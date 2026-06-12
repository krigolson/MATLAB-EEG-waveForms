function [limits, ticks] = wf_integer_axis_limits(values)
%WF_INTEGER_AXIS_LIMITS Even-number y-axis limits and 2-uV ticks.

values = values(:);
values = values(isfinite(values));
if isempty(values)
    minValue = 0;
    maxValue = 0;
else
    minValue = min(values);
    maxValue = max(values);
end

bottom = 2 * floor(min([minValue 0]) / 2);
top = 2 * ceil(max([maxValue 0]) / 2);

if bottom == top
    bottom = bottom - 2;
    top = top + 2;
end

if abs(minValue - bottom) < 1e-12
    bottom = bottom - 2;
end
if abs(maxValue - top) < 1e-12
    top = top + 2;
end

ticks = bottom:2:top;
limits = [bottom top];
end
