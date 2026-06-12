function [lowerBand, upperBand, draws] = wf_bayesian_bootstrap_interval(subjectWaveforms, varargin)
%WF_BAYESIAN_BOOTSTRAP_INTERVAL Bayesian bootstrap interval for the mean.

parser = inputParser;
parser.FunctionName = mfilename;
addParameter(parser, 'CredibleLevel', 0.95, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1);
addParameter(parser, 'NumDraws', 5000, @(x) isnumeric(x) && isscalar(x) && x >= 100);
addParameter(parser, 'Seed', 1, @(x) isnumeric(x) && isscalar(x));
parse(parser, varargin{:});
opts = parser.Results;

subjectWaveforms = double(subjectWaveforms);
nSubjects = size(subjectWaveforms, 1);
nTime = size(subjectWaveforms, 2);
numDraws = round(opts.NumDraws);

previousState = set_rng_seed(opts.Seed);
rawWeights = -log(max(rand(numDraws, nSubjects), realmin));
restore_rng_state(previousState);

weights = rawWeights ./ sum(rawWeights, 2);
draws = weights * subjectWaveforms;

alpha = (1 - opts.CredibleLevel) / 2;
lowerBand = percentile_columns(draws, 100 * alpha);
upperBand = percentile_columns(draws, 100 * (1 - alpha));
lowerBand = reshape(lowerBand, 1, nTime);
upperBand = reshape(upperBand, 1, nTime);
end

function previousState = set_rng_seed(seed)
previousState = [];
try
    previousState = rng;
    rng(seed, 'twister');
catch
    try
        previousState = rand('state');
        rand('state', seed);
    catch
        previousState = [];
    end
end
end

function restore_rng_state(previousState)
if isempty(previousState)
    return;
end
try
    rng(previousState);
catch
    try
        rand('state', previousState);
    catch
    end
end
end

function pct = percentile_columns(values, percentile)
sortedValues = sort(values, 1);
nRows = size(sortedValues, 1);
position = 1 + (nRows - 1) * percentile / 100;
lowerIdx = floor(position);
upperIdx = ceil(position);
weight = position - lowerIdx;
if lowerIdx == upperIdx
    pct = sortedValues(lowerIdx, :);
else
    pct = (1 - weight) .* sortedValues(lowerIdx, :) + ...
        weight .* sortedValues(upperIdx, :);
end
end
