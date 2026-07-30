function pk = boundParamsExt(pk, options)
ps = fieldnames(pk.bounds);
ps = ps(2:end);
% Ensure all parameters are within bounds
for paramDx = 1:length(ps)
    if any(isfield(options, {[ps{paramDx} 'Min'],[ps{paramDx} 'Max']}))
        for peakDx = 1:length(pk.bounds)
            if ~isempty(pk.bounds(peakDx).(ps{paramDx}))
                if isfield(options, [ps{paramDx} 'Max']) && pk.bounds(peakDx).(ps{paramDx})(2)>options.([ps{paramDx} 'Max'])
                    pk.bounds(peakDx).(ps{paramDx})(2) = options.([ps{paramDx} 'Max']);
                elseif isfield(options, [ps{paramDx} 'Min']) && pk.bounds(peakDx).(ps{paramDx})(1)<options.([ps{paramDx} 'Min'])
                    pk.bounds(peakDx).(ps{paramDx})(1) = options.([ps{paramDx} 'Min']);
                end
            end
        end
    end
end
end