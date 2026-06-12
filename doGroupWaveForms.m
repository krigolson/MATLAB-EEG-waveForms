function outputs = doGroupWaveForms(dataInput, varargin)
%DOGROUPWAVEFORMS Plot group conditional and difference ERP waveforms.
%
%   outputs = doGroupWaveForms(dataInput)
%   outputs = doGroupWaveForms(dataInput, 'ConditionPair', [1 2])
%
%   The figure is a 3 x 1 plot:
%       top    - group mean condition waveforms
%       middle - group mean difference with a 95 percent confidence band
%       bottom - group mean difference with a Bayesian confidence band
%
%   Data should be channels x time x conditions x subjects.

if nargin < 1 || isempty(dataInput)
    dataInput = fullfile('..', 'sLoretta', 'rewpGrandERP.mat');
end

parser = inputParser;
parser.FunctionName = mfilename;
addParameter(parser, 'DataVariable', 'grandERP', @(x) ischar(x) || isstring(x));
addParameter(parser, 'ChanlocsFile', fullfile('..', 'sLoretta', 'matlocs.mat'), @(x) ischar(x) || isstring(x));
addParameter(parser, 'OutputDir', 'outputs', @(x) ischar(x) || isstring(x));
addParameter(parser, 'OutputPrefix', '', @(x) ischar(x) || isstring(x));
addParameter(parser, 'ConditionPair', [1 2], @(x) isnumeric(x) && numel(x) == 2 && all(x >= 1));
addParameter(parser, 'ConditionLabels', {}, @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x));
addParameter(parser, 'Channels', {'FCz'}, @(x) isnumeric(x) || ischar(x) || isstring(x) || iscell(x));
addParameter(parser, 'StartTime', -200, @(x) isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(parser, 'SamplingRate', 500, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
addParameter(parser, 'TimeVector', [], @(x) isempty(x) || isnumeric(x));
addParameter(parser, 'YLabel', 'Voltage (uV)', @(x) ischar(x) || isstring(x));
addParameter(parser, 'BayesianDraws', 5000, @(x) isnumeric(x) && isscalar(x) && x >= 100);
addParameter(parser, 'BayesianSeed', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(parser, 'MakePeakPlot', true, @(x) islogical(x) || isnumeric(x));
addParameter(parser, 'PeakTime', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
addParameter(parser, 'PeakPolarity', 'positive', @(x) ischar(x) || isstring(x));
addParameter(parser, 'MeanWindowMs', 20, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
addParameter(parser, 'PeakWindowMs', 50, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
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
if ndims(raw) < 4
    error([mfilename ':NeedSubjects'], ...
        'Group waveforms need channels x time x conditions x subjects data.');
end

chanlocs = wf_load_chanlocs(wf_resolve_path(char(opts.ChanlocsFile), rootDir));
labels = wf_chanlocs_labels(chanlocs);
wf_validate_channel_count(raw, labels);

conditionPair = round(opts.ConditionPair(:).');
conditionLabels = make_condition_labels(opts.ConditionLabels, conditionPair);
[channelIdx, selectedLabels] = wf_select_channels(opts.Channels, labels);
[conditionSubjectWaveforms, differenceSubjectWaveforms] = select_group_waveforms(raw, conditionPair, channelIdx);
timeVector = wf_make_time_vector(size(raw, 2), opts.TimeVector, opts.StartTime, opts.SamplingRate);
if logical(opts.PadToEvenTime) && isempty(opts.TimeVector) && ...
        wf_should_pad_even_endpoint(timeVector, opts.EvenTimeStep)
    sampleStep = timeVector(end) - timeVector(end - 1);
    timeVector(end + 1) = timeVector(end) + sampleStep;
    conditionSubjectWaveforms(:, end + 1, :) = conditionSubjectWaveforms(:, end, :);
    differenceSubjectWaveforms(:, end + 1) = differenceSubjectWaveforms(:, end);
end

nSubjects = size(differenceSubjectWaveforms, 1);
conditionMeanWaveforms = squeeze(mean(conditionSubjectWaveforms, 3));
differenceMeanWaveform = mean(differenceSubjectWaveforms, 1);
differenceSE = std(differenceSubjectWaveforms, 0, 1) ./ sqrt(nSubjects);
tCrit = wf_tcritical95(nSubjects - 1);
differenceCI = tCrit .* differenceSE;
differenceCILower = differenceMeanWaveform - differenceCI;
differenceCIUpper = differenceMeanWaveform + differenceCI;
[bayesianDifferenceCILower, bayesianDifferenceCIUpper, bayesianDifferenceDraws] = ...
    wf_bayesian_bootstrap_interval(differenceSubjectWaveforms, ...
    'CredibleLevel', 0.95, ...
    'NumDraws', opts.BayesianDraws, ...
    'Seed', opts.BayesianSeed);
bayesianDifferenceCI = (bayesianDifferenceCIUpper - bayesianDifferenceCILower) ./ 2;

if isempty(char(opts.OutputPrefix))
    outputPrefix = sprintf('groupWaveform_cond%02dminus%02d_%s', ...
        conditionPair(1), conditionPair(2), make_channel_token(selectedLabels));
else
    outputPrefix = char(opts.OutputPrefix);
end

imageFile = fullfile(outputDir, [outputPrefix '_group_waveform.png']);
csvFile = fullfile(outputDir, [outputPrefix '_group_waveform.csv']);
matFile = fullfile(outputDir, [outputPrefix '_group_waveform.mat']);
peakImageFile = fullfile(outputDir, [outputPrefix '_peak_detection.png']);
peakCsvFile = fullfile(outputDir, [outputPrefix '_peak_detection.csv']);

fig = figure('Color', 'w', 'Position', [100 100 1100 950]);
colors = [0.0 0.28 0.55; 0.78 0.30 0.10];
differenceColor = [0.0 0.45 0.22];
ciBandColor = [0.67 0.84 0.68];
bayesianBandColor = [0.55 0.77 0.56];
[sharedYLimits, sharedYTicks] = wf_integer_axis_limits([conditionMeanWaveforms(:); ...
    differenceMeanWaveform(:); differenceCILower(:); differenceCIUpper(:); ...
    bayesianDifferenceCILower(:); bayesianDifferenceCIUpper(:)]);

ax1 = subplot(3, 1, 1);
hold(ax1, 'on');
plot(ax1, timeVector, conditionMeanWaveforms(1, :), 'LineWidth', 2.2, 'Color', colors(1, :));
plot(ax1, timeVector, conditionMeanWaveforms(2, :), 'LineWidth', 2.2, 'Color', colors(2, :));
format_waveform_axis(ax1, timeVector, opts.ShowZeroLines);
ylim(ax1, sharedYLimits);
set(ax1, 'YTick', sharedYTicks);
ylabel(ax1, char(opts.YLabel));
title(ax1, sprintf('Conditional Waveforms: %s', strjoin(selectedLabels, ', ')), ...
    'Interpreter', 'none', 'FontSize', 14);
legend(ax1, conditionLabels, 'Location', 'northwest', 'Box', 'off');

ax2 = subplot(3, 1, 2);
hold(ax2, 'on');
patch(ax2, [timeVector fliplr(timeVector)], [differenceCIUpper fliplr(differenceCILower)], ...
    ciBandColor, 'FaceAlpha', 0.45, 'EdgeColor', 'none');
plot(ax2, timeVector, differenceMeanWaveform, 'LineWidth', 2.4, 'Color', differenceColor);
format_waveform_axis(ax2, timeVector, opts.ShowZeroLines);
ylim(ax2, sharedYLimits);
set(ax2, 'YTick', sharedYTicks);
ylabel(ax2, char(opts.YLabel));
title(ax2, 'Difference Waveform', 'Interpreter', 'none', 'FontSize', 14);
add_panel_text(ax2, '95% Confidence Interval');

ax3 = subplot(3, 1, 3);
hold(ax3, 'on');
patch(ax3, [timeVector fliplr(timeVector)], ...
    [bayesianDifferenceCIUpper fliplr(bayesianDifferenceCILower)], ...
    bayesianBandColor, 'FaceAlpha', 0.45, 'EdgeColor', 'none');
plot(ax3, timeVector, differenceMeanWaveform, 'LineWidth', 2.4, 'Color', differenceColor);
format_waveform_axis(ax3, timeVector, opts.ShowZeroLines);
ylim(ax3, sharedYLimits);
set(ax3, 'YTick', sharedYTicks);
xlabel(ax3, 'Time (ms)');
ylabel(ax3, char(opts.YLabel));
title(ax3, 'Difference Waveform', 'Interpreter', 'none', 'FontSize', 14);
add_panel_text(ax3, 'Bayesian Confidence Interval');

wf_save_png(fig, imageFile);
if logical(opts.CloseFigures)
    close(fig);
end

peak = wf_group_peak_detection(differenceSubjectWaveforms, timeVector, ...
    'PeakTime', opts.PeakTime, ...
    'PeakPolarity', opts.PeakPolarity, ...
    'MeanWindowMs', opts.MeanWindowMs, ...
    'PeakWindowMs', opts.PeakWindowMs);
if logical(opts.MakePeakPlot)
    peakFig = wf_plot_peak_detection(peak, peakImageFile);
    if logical(opts.CloseFigures)
        close(peakFig);
    end
end
wf_write_peak_csv(peakCsvFile, peak);

write_group_csv(csvFile, timeVector, conditionMeanWaveforms, differenceMeanWaveform, ...
    differenceCILower, differenceCIUpper, bayesianDifferenceCILower, ...
    bayesianDifferenceCIUpper, conditionPair, nSubjects);

metadata = struct();
metadata.createdBy = mfilename;
metadata.dataInfo = dataInfo;
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
metadata.nSubjects = nSubjects;
metadata.ciLevel = 0.95;
metadata.bayesianCiLevel = 0.95;
metadata.bayesianDraws = opts.BayesianDraws;
metadata.bayesianSeed = opts.BayesianSeed;
metadata.bayesianCiNote = 'Computed with a deterministic Bayesian bootstrap over subject difference waveforms.';
metadata.peakDetection = struct('peakTime', peak.peakTime, ...
    'peakPolarity', peak.peakPolarity, ...
    'meanWindowMs', peak.meanWindowMs, ...
    'peakWindowMs', peak.peakWindowMs);
metadata.tCritical = tCrit;
metadata.outputPrefix = outputPrefix;

save(matFile, 'conditionSubjectWaveforms', 'conditionMeanWaveforms', ...
    'differenceSubjectWaveforms', 'differenceMeanWaveform', 'differenceCI', ...
    'differenceCILower', 'differenceCIUpper', 'bayesianDifferenceCI', ...
    'bayesianDifferenceCILower', 'bayesianDifferenceCIUpper', ...
    'bayesianDifferenceDraws', 'peak', 'timeVector', 'selectedLabels', ...
    'channelIdx', 'metadata', '-v7');

outputs = struct();
outputs.imageFile = imageFile;
outputs.csvFile = csvFile;
outputs.matFile = matFile;
outputs.peakImageFile = peakImageFile;
outputs.peakCsvFile = peakCsvFile;
outputs.conditionSubjectWaveforms = conditionSubjectWaveforms;
outputs.conditionMeanWaveforms = conditionMeanWaveforms;
outputs.differenceSubjectWaveforms = differenceSubjectWaveforms;
outputs.differenceMeanWaveform = differenceMeanWaveform;
outputs.differenceCI = differenceCI;
outputs.differenceCILower = differenceCILower;
outputs.differenceCIUpper = differenceCIUpper;
outputs.bayesianDifferenceCI = bayesianDifferenceCI;
outputs.bayesianDifferenceCILower = bayesianDifferenceCILower;
outputs.bayesianDifferenceCIUpper = bayesianDifferenceCIUpper;
outputs.bayesianDifferenceDraws = bayesianDifferenceDraws;
outputs.peak = peak;
outputs.timeVector = timeVector;
outputs.channelIdx = channelIdx;
outputs.channelLabels = selectedLabels;
outputs.metadata = metadata;

fprintf('Group waveform image saved: %s\n', imageFile);
fprintf('Group waveform CSV saved: %s\n', csvFile);
fprintf('Group waveform MAT saved: %s\n', matFile);
fprintf('Group peak detection image saved: %s\n', peakImageFile);
fprintf('Group peak detection CSV saved: %s\n', peakCsvFile);
end

function [conditionSubjectWaveforms, differenceSubjectWaveforms] = select_group_waveforms(raw, conditionPair, channelIdx)
condition1 = squeeze(raw(channelIdx, :, conditionPair(1), :));
condition2 = squeeze(raw(channelIdx, :, conditionPair(2), :));
condition1 = subject_by_time(condition1, channelIdx);
condition2 = subject_by_time(condition2, channelIdx);
conditionSubjectWaveforms = cat(1, reshape(condition1.', 1, size(condition1, 2), size(condition1, 1)), ...
    reshape(condition2.', 1, size(condition2, 2), size(condition2, 1)));
differenceSubjectWaveforms = condition1 - condition2;
end

function waveforms = subject_by_time(data, channelIdx)
if numel(channelIdx) == 1
    waveforms = squeeze(data).';
else
    waveforms = squeeze(mean(data, 1)).';
end
if size(waveforms, 2) == 1
    waveforms = waveforms.';
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

function write_group_csv(csvFile, timeVector, conditionMeanWaveforms, differenceMeanWaveform, ...
    differenceCILower, differenceCIUpper, bayesianDifferenceCILower, ...
    bayesianDifferenceCIUpper, conditionPair, nSubjects)
parentDir = fileparts(csvFile);
if ~isempty(parentDir) && ~exist(parentDir, 'dir')
    mkdir(parentDir);
end
fid = fopen(csvFile, 'w');
if fid == -1
    error([mfilename ':CannotWriteCSV'], 'Could not write %s.', csvFile);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, ['time_ms,n,mean_condition_%d,mean_condition_%d,' ...
    'mean_difference_%d_minus_%d,ci95_lower,ci95_upper,' ...
    'bayesian_ci95_lower,bayesian_ci95_upper\n'], ...
    conditionPair(1), conditionPair(2), conditionPair(1), conditionPair(2));
for idx = 1:numel(timeVector)
    fprintf(fid, '%.12g,%d,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', ...
        timeVector(idx), nSubjects, conditionMeanWaveforms(1, idx), ...
        conditionMeanWaveforms(2, idx), differenceMeanWaveform(idx), ...
        differenceCILower(idx), differenceCIUpper(idx), ...
        bayesianDifferenceCILower(idx), bayesianDifferenceCIUpper(idx));
end
end

function add_panel_text(ax, labelText)
yLimits = ylim(ax);
xLimits = xlim(ax);
xPos = xLimits(1) + 0.03 * range(xLimits);
yPos = yLimits(2) - 0.12 * range(yLimits);
text(ax, xPos, yPos, labelText, 'FontName', 'Helvetica', 'FontSize', 11, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top');
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
