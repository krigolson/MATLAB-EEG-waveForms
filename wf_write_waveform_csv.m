function wf_write_waveform_csv(csvFile, timeVector, waveform)
%WF_WRITE_WAVEFORM_CSV Write a single waveform to CSV.

parentDir = fileparts(csvFile);
if ~isempty(parentDir) && ~exist(parentDir, 'dir')
    mkdir(parentDir);
end
fid = fopen(csvFile, 'w');
if fid == -1
    error('waveForms:CannotWriteCSV', 'Could not write %s.', csvFile);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'time,value\n');
for idx = 1:numel(timeVector)
    fprintf(fid, '%.12g,%.12g\n', timeVector(idx), waveform(idx));
end
end
