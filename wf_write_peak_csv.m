function wf_write_peak_csv(csvFile, peak)
%WF_WRITE_PEAK_CSV Write subject-level peak measures to CSV.

parentDir = fileparts(csvFile);
if ~isempty(parentDir) && ~exist(parentDir, 'dir')
    mkdir(parentDir);
end
fid = fopen(csvFile, 'w');
if fid == -1
    error('waveForms:CannotWriteCSV', 'Could not write %s.', csvFile);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'subject,mean_amplitude_uv,peak_amplitude_uv,peak_latency_ms\n');
for idx = 1:numel(peak.meanAmplitude)
    fprintf(fid, '%d,%.12g,%.12g,%.12g\n', idx, ...
        peak.meanAmplitude(idx), peak.peakAmplitude(idx), peak.peakLatency(idx));
end
end
