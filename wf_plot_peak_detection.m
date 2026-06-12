function fig = wf_plot_peak_detection(peak, outputPng)
%WF_PLOT_PEAK_DETECTION Plot group peak measures with dual y axes.

fig = figure('Color', 'w', 'Position', [100 100 900 560]);
voltageColor = [0.0 0.45 0.22];
voltagePointColor = [0.35 0.68 0.47];
latencyColor = [0.18 0.36 0.42];
latencyPointColor = [0.48 0.66 0.72];

axLeft = axes('Parent', fig);
set(axLeft, 'Position', [0.12 0.14 0.70 0.56]);
hold(axLeft, 'on');

meanValues = [peak.summary.meanAmplitudeMean, peak.summary.peakAmplitudeMean];
meanSE = [peak.summary.meanAmplitudeSE, peak.summary.peakAmplitudeSE];
plot_jittered_points(axLeft, 1, peak.meanAmplitude, voltagePointColor);
plot_jittered_points(axLeft, 2, peak.peakAmplitude, voltagePointColor);
plot_mean_lines(axLeft, 1:2, meanValues, voltageColor);
plot_error_bars(axLeft, 1:2, meanValues, meanSE, 0.18);

ylabel(axLeft, 'Voltage (uV)');
set(axLeft, 'XLim', [0.35 3.65], 'XTick', 1:3, ...
    'XTickLabel', {'Mean', 'Peak', 'Latency'}, ...
    'TickLength', [0 0], 'FontName', 'Helvetica', 'FontSize', 12, ...
    'LineWidth', 1, 'Box', 'off');

leftLimits = voltage_limits([peak.meanAmplitude(:); peak.peakAmplitude(:); ...
    meanValues(:) - meanSE(:); meanValues(:) + meanSE(:); 0]);
ylim(axLeft, leftLimits);
set(axLeft, 'YTick', leftLimits(1):2:leftLimits(2));

axRight = axes('Parent', fig, 'Position', get(axLeft, 'Position'), ...
    'Color', 'none', 'YAxisLocation', 'right', 'XAxisLocation', 'bottom');
hold(axRight, 'on');
latencyLimits = latency_axis_limits(peak.peakLatency, ...
    peak.summary.peakLatencyMean, peak.summary.peakLatencySE);
ylim(axRight, latencyLimits);
plot_jittered_points(axRight, 3, peak.peakLatency, latencyPointColor);
plot_mean_lines(axRight, 3, peak.summary.peakLatencyMean, latencyColor);
plot_error_bars(axRight, 3, peak.summary.peakLatencyMean, ...
    peak.summary.peakLatencySE, 0.18);

ylabel(axRight, 'Time (ms)');
set(axRight, 'XLim', [0.35 3.65], 'XTick', [], 'TickLength', [0 0], ...
    'FontName', 'Helvetica', 'FontSize', 12, 'LineWidth', 1, ...
    'Box', 'off');
set(axRight, 'YTick', latency_ticks(latencyLimits));

labelAx = axes('Parent', fig, 'Position', [0 0 1 1], 'Visible', 'off');
set(labelAx, 'XLim', [0 1], 'YLim', [0 1]);
titleText = sprintf('Group Peak Detection: %s peak at %.0f ms', ...
    capitalize_first(peak.peakPolarity), peak.peakTime);
subtitleText = sprintf('Mean: %.0f +/- %.0f ms; Peak/Latency: %.0f +/- %.0f ms', ...
    peak.peakTime, peak.meanWindowMs, peak.peakTime, peak.peakWindowMs);
text(labelAx, 0.5, 0.94, titleText, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontName', 'Helvetica', ...
    'FontSize', 13, 'FontWeight', 'bold');
text(labelAx, 0.5, 0.89, subtitleText, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontName', 'Helvetica', 'FontSize', 11);

wf_save_png(fig, outputPng);
end

function plot_jittered_points(ax, xCenter, values, colorValue)
values = values(:);
nValues = numel(values);
if nValues == 1
    jitter = 0;
else
    jitter = linspace(-0.13, 0.13, nValues).';
end
plot(ax, xCenter + jitter, values, 'o', 'MarkerSize', 5.5, ...
    'MarkerFaceColor', colorValue, 'MarkerEdgeColor', colorValue, ...
    'LineStyle', 'none');
end

function plot_mean_lines(ax, xCenters, values, colorValue)
for idx = 1:numel(xCenters)
    plot(ax, [xCenters(idx) - 0.22, xCenters(idx) + 0.22], ...
        [values(idx), values(idx)], '-', 'Color', colorValue, 'LineWidth', 3.0);
end
end

function plot_error_bars(ax, xCenters, values, errors, capHalfWidth)
for idx = 1:numel(xCenters)
    x = xCenters(idx);
    y = values(idx);
    err = errors(idx);
    plot(ax, [x x], [y - err, y + err], 'k-', 'LineWidth', 1.5);
    plot(ax, [x - capHalfWidth, x + capHalfWidth], ...
        [y - err, y - err], 'k-', 'LineWidth', 1.5);
    plot(ax, [x - capHalfWidth, x + capHalfWidth], ...
        [y + err, y + err], 'k-', 'LineWidth', 1.5);
end
end

function limits = voltage_limits(values)
bottom = 2 * floor(min(values) / 2);
top = 2 * ceil(max(values) / 2);
if bottom == top
    bottom = bottom - 2;
    top = top + 2;
end
limits = [bottom top];
end

function limits = latency_axis_limits(values, meanValue, seValue)
values = values(:);
low = min([values; meanValue - seValue]);
high = max([values; meanValue + seValue]);
bottom = 10 * floor(low / 10);
top = 10 * ceil(high / 10);
if bottom == top
    bottom = bottom - 10;
    top = top + 10;
end
limits = [bottom top];
end

function ticks = latency_ticks(limits)
ticks = limits(1):10:limits(2);
end

function out = capitalize_first(in)
out = char(in);
out(1) = upper(out(1));
end
