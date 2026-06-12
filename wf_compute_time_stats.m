function stats = wf_compute_time_stats(subjectWaveforms, tail)
%WF_COMPUTE_TIME_STATS One-sample t tests across subjects at each time point.

nSubjects = size(subjectWaveforms, 1);
df = nSubjects - 1;
meanValues = mean(subjectWaveforms, 1);
sdValues = std(subjectWaveforms, 0, 1);
seValues = sdValues ./ sqrt(nSubjects);
tValues = meanValues ./ seValues;
tValues(~isfinite(tValues)) = 0;
pValues = t_to_p(tValues, df, tail);

stats = struct();
stats.mean = meanValues;
stats.sd = sdValues;
stats.se = seValues;
stats.t = tValues;
stats.df = repmat(df, size(tValues));
stats.p = pValues;
end

function p = t_to_p(tValues, df, tail)
if df <= 0
    p = ones(size(tValues));
    return;
end
x = df ./ (df + tValues .^ 2);
twoTailed = betainc(x, df / 2, 0.5);
switch lower(tail)
    case {'both', 'two', 'twotailed', 'two-tailed'}
        p = twoTailed;
    case {'right', 'positive', 'greater'}
        p = 0.5 * twoTailed;
        p(tValues < 0) = 1 - p(tValues < 0);
    case {'left', 'negative', 'less'}
        p = 0.5 * twoTailed;
        p(tValues > 0) = 1 - p(tValues > 0);
    otherwise
        error('waveForms:BadTail', 'Tail must be both, right, or left.');
end
p = min(max(p, 0), 1);
end
