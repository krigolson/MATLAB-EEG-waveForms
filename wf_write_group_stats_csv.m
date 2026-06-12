function wf_write_group_stats_csv(csvFile, timeVector, stats, nSubjects)
%WF_WRITE_GROUP_STATS_CSV Write time-wise group waveform stats to CSV.

parentDir = fileparts(csvFile);
if ~isempty(parentDir) && ~exist(parentDir, 'dir')
    mkdir(parentDir);
end
fid = fopen(csvFile, 'w');
if fid == -1
    error('waveForms:CannotWriteCSV', 'Could not write %s.', csvFile);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'time,n,mean,sd,se,t,df,p,p_corrected,significant\n');
for idx = 1:numel(timeVector)
    fprintf(fid, '%.12g,%d,%.12g,%.12g,%.12g,%.12g,%d,%.12g,%.12g,%d\n', ...
        timeVector(idx), nSubjects, stats.mean(idx), stats.sd(idx), ...
        stats.se(idx), stats.t(idx), stats.df(idx), stats.p(idx), ...
        stats.pCorrected(idx), stats.significant(idx));
end
end
