function tf = wf_should_pad_even_endpoint(timeVector, evenTimeStep)
%WF_SHOULD_PAD_EVEN_ENDPOINT True when one copied endpoint reaches a clean time.

if numel(timeVector) < 2
    tf = false;
    return;
end

sampleStep = timeVector(end) - timeVector(end - 1);
nextTime = timeVector(end) + sampleStep;
ratio = nextTime ./ evenTimeStep;
tf = abs(ratio - round(ratio)) < 1e-9;
end
