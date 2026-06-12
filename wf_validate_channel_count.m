function wf_validate_channel_count(raw, labels)
%WF_VALIDATE_CHANNEL_COUNT Check that data and chanlocs agree.

if size(raw, 1) ~= numel(labels)
    error('waveForms:ChannelMismatch', ...
        'Data has %d channels but chanlocs has %d channels.', ...
        size(raw, 1), numel(labels));
end
end
