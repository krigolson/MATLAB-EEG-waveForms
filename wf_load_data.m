function [raw, info] = wf_load_data(dataInput, dataVariable)
%WF_LOAD_DATA Load numeric data or a variable from a MAT file.

info = struct();
if isnumeric(dataInput)
    raw = dataInput;
    info.source = 'numeric input';
else
    dataFile = char(dataInput);
    varName = char(dataVariable);
    loaded = load(dataFile, varName);
    if ~isfield(loaded, varName)
        error('waveForms:MissingVariable', ...
            'Could not find variable %s in %s.', varName, dataFile);
    end
    raw = loaded.(varName);
    info.source = dataFile;
    info.variable = varName;
end
info.rawSize = size(raw);
end
