function pk = boundParams(pk)
ps = fieldnames(pk.initialValues);
ps = ps(2:end);
% Ensure all parameters are within bounds
for peakDx = 1:length(pk.initialValues)
    for paramDx = 1:length(ps)
        if ~isempty(pk.bounds(peakDx).(ps{paramDx}))
            if pk.initialValues(peakDx).(ps{paramDx}) > pk.bounds(peakDx).(ps{paramDx})(2)
                pk.initialValues(peakDx).(ps{paramDx}) = pk.bounds(peakDx).(ps{paramDx})(2);
            elseif pk.initialValues(peakDx).(ps{paramDx}) < pk.bounds(peakDx).(ps{paramDx})(1)
                pk.initialValues(peakDx).(ps{paramDx}) = pk.bounds(peakDx).(ps{paramDx})(1);
            end
        end
    end
end
end