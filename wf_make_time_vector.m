function timeVector = wf_make_time_vector(nTime, requestedTimeVector, startTime, samplingRate)
%WF_MAKE_TIME_VECTOR Return a row vector for plotting and export.

if isempty(requestedTimeVector)
    if nargin < 3 || isempty(startTime)
        startTime = 1;
    end
    if nargin < 4 || isempty(samplingRate)
        timeVector = 1:nTime;
    else
        timeVector = startTime + ((0:nTime - 1) ./ samplingRate) .* 1000;
    end
else
    timeVector = requestedTimeVector(:).';
    if numel(timeVector) ~= nTime
        error('waveForms:BadTimeVector', ...
            'TimeVector has %d values, but the data has %d time points.', ...
            numel(timeVector), nTime);
    end
end
end
