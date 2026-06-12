function pathOut = wf_resolve_path(pathIn, rootDir)
%WF_RESOLVE_PATH Resolve paths relative to the waveForms folder.

if wf_is_absolute_path(pathIn) || exist(pathIn, 'file')
    pathOut = pathIn;
else
    pathOut = fullfile(rootDir, pathIn);
end
end
