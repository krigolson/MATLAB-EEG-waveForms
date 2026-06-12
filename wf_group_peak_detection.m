function peak = wf_group_peak_detection(subjectWaveforms, timeVector, varargin)
%WF_GROUP_PEAK_DETECTION Subject-level peak measures from group waveforms.

parser = inputParser;
parser.FunctionName = mfilename;
addParameter(parser, 'PeakTime', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x)));
addParameter(parser, 'PeakPolarity', 'positive', @(x) ischar(x) || isstring(x));
addParameter(parser, 'MeanWindowMs', 20, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
addParameter(parser, 'PeakWindowMs', 50, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
parse(parser, varargin{:});
opts = parser.Results;

timeVector = timeVector(:).';
polarity = lower(char(opts.PeakPolarity));
if ~ismember(polarity, {'positive', 'pos', 'maximum', 'max', 'negative', 'neg', 'minimum', 'min'})
    error('waveForms:BadPeakPolarity', ...
        'PeakPolarity must be positive or negative.');
end
isPositive = ismember(polarity, {'positive', 'pos', 'maximum', 'max'});

groupWaveform = mean(subjectWaveforms, 1);
if isempty(opts.PeakTime)
    if isPositive
        [~, peakIndex] = max(groupWaveform);
    else
        [~, peakIndex] = min(groupWaveform);
    end
    peakTime = timeVector(peakIndex);
else
    peakTime = opts.PeakTime;
    [~, peakIndex] = min(abs(timeVector - peakTime));
    peakTime = timeVector(peakIndex);
end

meanMask = timeVector >= (peakTime - opts.MeanWindowMs) & ...
    timeVector <= (peakTime + opts.MeanWindowMs);
peakMask = timeVector >= (peakTime - opts.PeakWindowMs) & ...
    timeVector <= (peakTime + opts.PeakWindowMs);
if ~any(meanMask) || ~any(peakMask)
    error('waveForms:BadPeakWindow', ...
        'Peak windows do not overlap the available time vector.');
end

nSubjects = size(subjectWaveforms, 1);
meanAmplitude = mean(subjectWaveforms(:, meanMask), 2);
peakAmplitude = zeros(nSubjects, 1);
peakLatency = zeros(nSubjects, 1);
searchTimes = timeVector(peakMask);
for subjectIdx = 1:nSubjects
    searchValues = subjectWaveforms(subjectIdx, peakMask);
    if isPositive
        [peakAmplitude(subjectIdx), localIdx] = max(searchValues);
    else
        [peakAmplitude(subjectIdx), localIdx] = min(searchValues);
    end
    peakLatency(subjectIdx) = searchTimes(localIdx);
end

peak = struct();
peak.peakTime = peakTime;
peak.peakIndex = peakIndex;
peak.peakPolarity = ternary(isPositive, 'positive', 'negative');
peak.meanWindowMs = opts.MeanWindowMs;
peak.peakWindowMs = opts.PeakWindowMs;
peak.meanWindow = [peakTime - opts.MeanWindowMs, peakTime + opts.MeanWindowMs];
peak.peakWindow = [peakTime - opts.PeakWindowMs, peakTime + opts.PeakWindowMs];
peak.meanAmplitude = meanAmplitude;
peak.peakAmplitude = peakAmplitude;
peak.peakLatency = peakLatency;
peak.summary = make_summary(meanAmplitude, peakAmplitude, peakLatency);
end

function summary = make_summary(meanAmplitude, peakAmplitude, peakLatency)
summary = struct();
summary.nSubjects = numel(meanAmplitude);
summary.meanAmplitudeMean = mean(meanAmplitude);
summary.meanAmplitudeSE = std(meanAmplitude, 0) ./ sqrt(summary.nSubjects);
summary.peakAmplitudeMean = mean(peakAmplitude);
summary.peakAmplitudeSE = std(peakAmplitude, 0) ./ sqrt(summary.nSubjects);
summary.peakLatencyMean = mean(peakLatency);
summary.peakLatencySE = std(peakLatency, 0) ./ sqrt(summary.nSubjects);
end

function out = ternary(condition, trueValue, falseValue)
if condition
    out = trueValue;
else
    out = falseValue;
end
end
