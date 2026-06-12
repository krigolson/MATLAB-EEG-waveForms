function pCorrected = wf_correct_pvalues(p, correction)
%WF_CORRECT_PVALUES Apply simple multiple-comparison correction.

p = p(:);
switch lower(correction)
    case {'none', 'uncorrected'}
        pCorrected = p;
    case {'fdr', 'bh'}
        [sortedP, order] = sort(p, 'ascend');
        n = numel(p);
        adjusted = sortedP .* n ./ (1:n).';
        for idx = n-1:-1:1
            adjusted(idx) = min(adjusted(idx), adjusted(idx + 1));
        end
        pCorrected = zeros(size(p));
        pCorrected(order) = min(adjusted, 1);
    otherwise
        error('waveForms:BadCorrection', ...
            'Correction must be fdr or none.');
end
pCorrected = reshape(pCorrected, size(p));
end
