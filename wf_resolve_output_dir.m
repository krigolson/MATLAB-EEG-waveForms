function outputDir = wf_resolve_output_dir(outputDir, rootDir)
%WF_RESOLVE_OUTPUT_DIR Resolve output paths relative to the waveForms folder.

if wf_is_absolute_path(outputDir)
    return;
end
outputDir = fullfile(rootDir, outputDir);
end
