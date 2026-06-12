function labels = wf_chanlocs_labels(chanlocs)
%WF_CHANLOCS_LABELS Return channel labels as a column cell array.

labels = cell(numel(chanlocs), 1);
for idx = 1:numel(chanlocs)
    if isfield(chanlocs, 'labels') && ~isempty(chanlocs(idx).labels)
        labels{idx} = char(chanlocs(idx).labels);
    else
        labels{idx} = sprintf('Ch%d', idx);
    end
end
end
