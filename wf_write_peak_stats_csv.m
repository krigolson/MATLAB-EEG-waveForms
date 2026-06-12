function stats = wf_write_peak_stats_csv(csvFile, peak, varargin)
%WF_WRITE_PEAK_STATS_CSV Write group statistics for peak measures to CSV.

parser = inputParser;
parser.FunctionName = mfilename;
addParameter(parser, 'BayesianDraws', 5000, @(x) isnumeric(x) && isscalar(x) && x >= 100);
addParameter(parser, 'BayesianSeed', 1, @(x) isnumeric(x) && isscalar(x));
parse(parser, varargin{:});
opts = parser.Results;

measureNames = {'mean_amplitude', 'peak_amplitude', 'peak_latency'};
units = {'uV', 'uV', 'ms'};
values = {peak.meanAmplitude(:), peak.peakAmplitude(:), peak.peakLatency(:)};

stats = repmat(empty_stats_row(), numel(measureNames), 1);
for idx = 1:numel(measureNames)
    stats(idx) = make_stats_row(measureNames{idx}, units{idx}, values{idx}, ...
        opts.BayesianDraws, opts.BayesianSeed + idx - 1);
end

parentDir = fileparts(csvFile);
if ~isempty(parentDir) && ~exist(parentDir, 'dir')
    mkdir(parentDir);
end
fid = fopen(csvFile, 'w');
if fid == -1
    error('waveForms:CannotWriteCSV', 'Could not write %s.', csvFile);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ['measure,unit,n,mean,sd,se,ci95_lower,ci95_upper,' ...
    'bayesian_interval_lower,bayesian_interval_upper,t,df,p,cohens_d\n']);
for idx = 1:numel(stats)
    fprintf(fid, '%s,%s,%d,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%d,%.12g,%.12g\n', ...
        stats(idx).measure, stats(idx).unit, stats(idx).n, stats(idx).mean, ...
        stats(idx).sd, stats(idx).se, stats(idx).ci95Lower, ...
        stats(idx).ci95Upper, stats(idx).bayesianLower, ...
        stats(idx).bayesianUpper, stats(idx).t, stats(idx).df, ...
        stats(idx).p, stats(idx).cohensD);
end
end

function row = make_stats_row(measureName, unit, values, bayesianDraws, bayesianSeed)
values = double(values(:));
values = values(isfinite(values));
n = numel(values);
df = n - 1;
meanValue = mean(values);
sdValue = std(values, 0);
seValue = sdValue ./ sqrt(n);
tCrit = wf_tcritical95(df);
ciHalfWidth = tCrit .* seValue;
if seValue > 0
    tValue = meanValue ./ seValue;
elseif meanValue == 0
    tValue = 0;
else
    tValue = sign(meanValue) .* Inf;
end
pValue = two_tailed_t_p(abs(tValue), df);
if sdValue > 0
    cohensD = meanValue ./ sdValue;
elseif meanValue == 0
    cohensD = 0;
else
    cohensD = sign(meanValue) .* Inf;
end

[bayesianLower, bayesianUpper] = bayesian_interval(values, bayesianDraws, bayesianSeed);

row = empty_stats_row();
row.measure = measureName;
row.unit = unit;
row.n = n;
row.mean = meanValue;
row.sd = sdValue;
row.se = seValue;
row.ci95Lower = meanValue - ciHalfWidth;
row.ci95Upper = meanValue + ciHalfWidth;
row.bayesianLower = bayesianLower;
row.bayesianUpper = bayesianUpper;
row.t = tValue;
row.df = df;
row.p = pValue;
row.cohensD = cohensD;
end

function row = empty_stats_row()
row = struct('measure', '', 'unit', '', 'n', 0, 'mean', NaN, 'sd', NaN, ...
    'se', NaN, 'ci95Lower', NaN, 'ci95Upper', NaN, ...
    'bayesianLower', NaN, 'bayesianUpper', NaN, 't', NaN, 'df', 0, ...
    'p', NaN, 'cohensD', NaN);
end

function [lowerValue, upperValue] = bayesian_interval(values, bayesianDraws, bayesianSeed)
[lowerBand, upperBand] = wf_bayesian_bootstrap_interval(values(:), ...
    'CredibleLevel', 0.95, ...
    'NumDraws', bayesianDraws, ...
    'Seed', bayesianSeed);
lowerValue = lowerBand(1);
upperValue = upperBand(1);
end

function p = two_tailed_t_p(tValue, df)
if df <= 0 || ~isfinite(tValue)
    if isinf(tValue)
        p = 0;
    else
        p = NaN;
    end
    return;
end
if exist('tcdf', 'file') == 2
    p = 2 .* (1 - tcdf(tValue, df));
else
    x = df ./ (df + tValue .^ 2);
    p = betainc(x, df / 2, 0.5);
end
p = min(max(p, 0), 1);
end
