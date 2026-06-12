function outputs = doWaveForms(dataInput, varargin)
%DOWAVEFORMS Plot subject-level conditional and difference ERP waveforms.
%
%   outputs = doWaveForms(dataInput)
%   outputs = doWaveForms(dataInput, 'ConditionPair', [1 2])
%
%   The figure is a 2 x 1 plot:
%       top    - both condition waveforms
%       bottom - conditionPair(1) - conditionPair(2)
%
%   Data can be channels x time, channels x time x conditions, or
%   channels x time x conditions x subjects.

if nargin < 1 || isempty(dataInput)
    dataInput = 'sampleGrandERP.mat';
end

parser = inputParser;
parser.FunctionName = mfilename;
addParameter(parser, 'DataVariable', 'sampleGrandERP', @(x) ischar(x) || isstring(x));
addParameter(parser, 'ChanlocsFile', 'sampleGrandERP.mat', @(x) ischar(x) || isstring(x));
addParameter(parser, 'OutputDir', 'outputs', @(x) ischar(x) || isstring(x));
addParameter(parser, 'OutputPrefix', '', @(x) ischar(x) || isstring(x));
addParameter(parser, 'SubjectIdx', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
addParameter(parser, 'ConditionPair', [1 2], @(x) isnumeric(x) && numel(x) == 2 && all(x >= 1));
addParameter(parser, 'ConditionLabels', {}, @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x));
addParameter(parser, 'Channels', {'FCz'}, @(x) isnumeric(x) || ischar(x) || isstring(x) || iscell(x));
addParameter(parser, 'StartTime', -200, @(x) isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(parser, 'SamplingRate', 500, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
addParameter(parser, 'TimeVector', [], @(x) isempty(x) || isnumeric(x));
addParameter(parser, 'YLabel', 'Voltage (uV)', @(x) ischar(x) || isstring(x));
addParameter(parser, 'PadToEvenTime', true, @(x) islogical(x) || isnumeric(x));
addParameter(parser, 'EvenTimeStep', 100, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
addParameter(parser, 'ShowZeroLines', true, @(x) islogical(x) || isnumeric(x));
addParameter(parser, 'CloseFigures', false, @(x) islogical(x) || isnumeric(x));
parse(parser, varargin{:});
opts = parser.Results;

rootDir = fileparts(mfilename('fullpath'));
outputDir = wf_resolve_output_dir(char(opts.OutputDir), rootDir);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

if isnumeric(dataInput)
    resolvedDataInput = dataInput;
else
    resolvedDataInput = wf_resolve_path(char(dataInput), rootDir);
end
[raw, dataInfo] = wf_load_data(resolvedDataInput, opts.DataVariable);
chanlocs = wf_load_chanlocs(wf_resolve_path(char(opts.ChanlocsFile), rootDir));
labels = wf_chanlocs_labels(chanlocs);
wf_validate_channel_count(raw, labels);

conditionPair = round(opts.ConditionPair(:).');
conditionLabels = make_condition_labels(opts.ConditionLabels, conditionPair);
[channelIdx, selectedLabels] = wf_select_channels(opts.Channels, labels);
[conditionWaveforms, differenceWaveform] = select_subject_waveforms(raw, opts.SubjectIdx, conditionPair, channelIdx);
timeVector = wf_make_time_vector(size(raw, 2), opts.TimeVector, opts.StartTime, opts.SamplingRate);
if logical(opts.PadToEvenTime) && isempty(opts.TimeVector) && ...
        wf_should_pad_even_endpoint(timeVector, opts.EvenTimeStep)
    sampleStep = timeVector(end) - timeVector(end - 1);
    timeVector(end + 1) = timeVector(end) + sampleStep;
    conditionWaveforms(:, end + 1) = conditionWaveforms(:, end);
    differenceWaveform(end + 1) = differenceWaveform(end);
end

if isempty(char(opts.OutputPrefix))
    outputPrefix = sprintf('waveform_sub%02d_cond%02dminus%02d_%s', ...
        opts.SubjectIdx, conditionPair(1), conditionPair(2), make_channel_token(selectedLabels));
else
    outputPrefix = char(opts.OutputPrefix);
end

imageFile = fullfile(outputDir, [outputPrefix '_waveform.png']);
csvFile = fullfile(outputDir, [outputPrefix '_waveform.csv']);
matFile = fullfile(outputDir, [outputPrefix '_waveform.mat']);

fig = figure('Color', 'w', 'Position', [100 100 1100 700]);
colors = [0.0 0.28 0.55; 0.78 0.30 0.10];
differenceColor = [0.0 0.45 0.22];
[sharedYLimits, sharedYTicks] = wf_integer_axis_limits([conditionWaveforms(:); differenceWaveform(:)]);

ax1 = subplot(2, 1, 1);
hold(ax1, 'on');
plot(ax1, timeVector, conditionWaveforms(1, :), 'LineWidth', 2.2, 'Color', colors(1, :));
plot(ax1, timeVector, conditionWaveforms(2, :), 'LineWidth', 2.2, 'Color', colors(2, :));
format_waveform_axis(ax1, timeVector, opts.ShowZeroLines);
ylim(ax1, sharedYLimits);
set(ax1, 'YTick', sharedYTicks);
ylabel(ax1, char(opts.YLabel));
title(ax1, sprintf('Conditional Waveforms: %s', strjoin(selectedLabels, ', ')), ...
    'Interpreter', 'none', 'FontSize', 14);
legend(ax1, conditionLabels, 'Location', 'northwest', 'Box', 'off');

ax2 = subplot(2, 1, 2);
hold(ax2, 'on');
plot(ax2, timeVector, differenceWaveform, 'LineWidth', 2.4, 'Color', differenceColor);
format_waveform_axis(ax2, timeVector, opts.ShowZeroLines);
ylim(ax2, sharedYLimits);
set(ax2, 'YTick', sharedYTicks);
xlabel(ax2, 'Time (ms)');
ylabel(ax2, char(opts.YLabel));
title(ax2, 'Difference Waveform', 'Interpreter', 'none', 'FontSize', 14);

wf_save_png(fig, imageFile);
if logical(opts.CloseFigures)
    close(fig);
end

write_subject_csv(csvFile, timeVector, conditionWaveforms, differenceWaveform, conditionPair);

metadata = struct();
metadata.createdBy = mfilename;
metadata.dataInfo = dataInfo;
metadata.subjectIdx = opts.SubjectIdx;
metadata.conditionPair = conditionPair;
metadata.conditionLabels = conditionLabels;
metadata.channels = selectedLabels;
metadata.channelIdx = channelIdx;
metadata.startTime = opts.StartTime;
metadata.samplingRate = opts.SamplingRate;
metadata.padToEvenTime = logical(opts.PadToEvenTime);
metadata.evenTimeStep = opts.EvenTimeStep;
metadata.timeUnit = 'ms';
metadata.yUnit = char(opts.YLabel);
metadata.outputPrefix = outputPrefix;

save(matFile, 'conditionWaveforms', 'differenceWaveform', 'timeVector', ...
    'selectedLabels', 'channelIdx', 'metadata', '-v7');

outputs = struct();
outputs.imageFile = imageFile;
outputs.csvFile = csvFile;
outputs.matFile = matFile;
outputs.conditionWaveforms = conditionWaveforms;
outputs.differenceWaveform = differenceWaveform;
outputs.timeVector = timeVector;
outputs.channelIdx = channelIdx;
outputs.channelLabels = selectedLabels;
outputs.metadata = metadata;

fprintf('Subject waveform image saved: %s\n', imageFile);
fprintf('Subject waveform CSV saved: %s\n', csvFile);
fprintf('Subject waveform MAT saved: %s\n', matFile);
end

function [conditionWaveforms, differenceWaveform] = select_subject_waveforms(raw, subjectIdx, conditionPair, channelIdx)
if ndims(raw) == 2
    error([mfilename ':NeedConditions'], ...
        'The two-panel waveform plot needs at least two conditions.');
elseif ndims(raw) == 3
    condition1 = squeeze(raw(channelIdx, :, conditionPair(1)));
    condition2 = squeeze(raw(channelIdx, :, conditionPair(2)));
else
    condition1 = squeeze(raw(channelIdx, :, conditionPair(1), subjectIdx));
    condition2 = squeeze(raw(channelIdx, :, conditionPair(2), subjectIdx));
end

conditionWaveforms = [mean_channel_waveform(condition1); mean_channel_waveform(condition2)];
differenceWaveform = conditionWaveforms(1, :) - conditionWaveforms(2, :);
end

function waveform = mean_channel_waveform(data)
if isvector(data)
    waveform = data(:).';
else
    waveform = mean(data, 1);
end
end

function format_waveform_axis(ax, timeVector, showZeroLines)
grid(ax, 'off');
box(ax, 'off');
set(ax, 'FontName', 'Helvetica', 'FontSize', 12, 'LineWidth', 1, ...
    'XAxisLocation', 'bottom', 'YDir', 'normal', 'TickLength', [0 0]);
if logical(showZeroLines)
    plot(ax, [timeVector(1) timeVector(end)], [0 0], '--', ...
        'Color', [0.25 0.25 0.25], 'LineWidth', 1.0);
    if min(timeVector) <= 0 && max(timeVector) >= 0
    end
end
xlim(ax, [timeVector(1) timeVector(end)]);
end

function write_subject_csv(csvFile, timeVector, conditionWaveforms, differenceWaveform, conditionPair)
parentDir = fileparts(csvFile);
if ~isempty(parentDir) && ~exist(parentDir, 'dir')
    mkdir(parentDir);
end
fid = fopen(csvFile, 'w');
if fid == -1
    error([mfilename ':CannotWriteCSV'], 'Could not write %s.', csvFile);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'time_ms,condition_%d,condition_%d,difference_%d_minus_%d\n', ...
    conditionPair(1), conditionPair(2), conditionPair(1), conditionPair(2));
for idx = 1:numel(timeVector)
    fprintf(fid, '%.12g,%.12g,%.12g,%.12g\n', timeVector(idx), ...
        conditionWaveforms(1, idx), conditionWaveforms(2, idx), differenceWaveform(idx));
end
end

function token = make_channel_token(selectedLabels)
token = strjoin(selectedLabels, '_');
token = regexprep(token, '[^A-Za-z0-9]+', '_');
end

function conditionLabels = make_condition_labels(requestedLabels, conditionPair)
if isempty(requestedLabels)
    conditionLabels = {sprintf('Condition %d', conditionPair(1)), ...
        sprintf('Condition %d', conditionPair(2))};
else
    conditionLabels = cellstr(requestedLabels);
    if numel(conditionLabels) ~= 2
        error([mfilename ':BadConditionLabels'], ...
            'ConditionLabels must contain exactly two names.');
    end
end
end
