function [channelIdx, selectedLabels] = wf_select_channels(channels, labels)
%WF_SELECT_CHANNELS Convert channel labels or indices to numeric indices.

if isnumeric(channels)
    channelIdx = channels(:).';
elseif ischar(channels) || isstring(channels)
    channels = cellstr(channels);
    channelIdx = labels_to_indices(channels, labels);
elseif iscell(channels)
    if all(cellfun(@isnumeric, channels))
        channelIdx = cell2mat(channels(:)).';
    else
        channelIdx = labels_to_indices(channels, labels);
    end
else
    error('waveForms:BadChannels', ...
        'Channels must be numeric indices, labels, or a cell array.');
end

channelIdx = round(channelIdx);
if isempty(channelIdx) || any(channelIdx < 1) || any(channelIdx > numel(labels))
    error('waveForms:BadChannels', ...
        'One or more channel indices are outside the available channel range.');
end
selectedLabels = labels(channelIdx);
end

function channelIdx = labels_to_indices(requestedLabels, labels)
requestedLabels = cellstr(requestedLabels);
channelIdx = zeros(1, numel(requestedLabels));
for idx = 1:numel(requestedLabels)
    match = find(strcmpi(requestedLabels{idx}, labels), 1);
    if isempty(match)
        error('waveForms:UnknownChannel', ...
            'Could not find channel label %s.', requestedLabels{idx});
    end
    channelIdx(idx) = match;
end
end
