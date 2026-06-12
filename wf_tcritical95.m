function tCrit = wf_tcritical95(df)
%WF_TCRITICAL95 Return a two-sided 95 percent t critical value.

if df <= 0
    tCrit = NaN;
    return;
end

if exist('tinv', 'file') == 2
    tCrit = tinv(0.975, df);
    return;
end

targetP = 0.05;
objective = @(t) t_two_tailed_p(t, df) - targetP;
tCrit = fzero(objective, [0.1 20]);
end

function p = t_two_tailed_p(tValue, df)
x = df ./ (df + tValue .^ 2);
p = betainc(x, df / 2, 0.5);
end
