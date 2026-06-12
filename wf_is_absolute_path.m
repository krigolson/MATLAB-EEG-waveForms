function tf = wf_is_absolute_path(pathIn)
%WF_IS_ABSOLUTE_PATH True for Unix or Windows absolute paths.

pathIn = char(pathIn);
tf = startsWith(pathIn, filesep) || ...
    (~isempty(regexp(pathIn, '^[A-Za-z]:[\\/]', 'once')));
end
