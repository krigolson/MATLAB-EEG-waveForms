function limits = wf_data_limits(values)
%WF_DATA_LIMITS Return padded limits spanning all finite plotted values.

values = values(:);
values = values(isfinite(values));
if isempty(values)
    limits = [-1 1];
    return;
end

minValue = min(values);
maxValue = max(values);
if minValue == maxValue
    pad = max(1, abs(minValue) * 0.05);
else
    pad = 0.05 * (maxValue - minValue);
end
limits = [minValue - pad, maxValue + pad];
end
