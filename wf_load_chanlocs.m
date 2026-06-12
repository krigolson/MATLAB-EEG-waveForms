function chanlocs = wf_load_chanlocs(chanlocsFile)
%WF_LOAD_CHANLOCS Load EEGLAB-style chanlocs from a MAT file.

loaded = load(chanlocsFile, 'chanlocs');
if ~isfield(loaded, 'chanlocs')
    error('waveForms:MissingChanlocs', ...
        '%s must contain a chanlocs variable.', chanlocsFile);
end
chanlocs = loaded.chanlocs;
end
