function [optimInit, optimLBounds, optimUBounds, optimIndex] = initializeOptimization(pk)
% Converts the prior knowledge into a format suitable for lsqcurvefit,
% i.e. this function extracts the initial values and pk.bounds.
%
% Input:
% pk: priorKnowledge set.
%
% Output:
% optimInit - initial values for each variable fit parameter.
% optimLBounds - lower bounds for each variable fit parameter.
% optimUBounds - upper bounds for each variable fit parameter.
% optimIndex - a 3 x #variable fit parameters cell array.
%              Column 1: Identifies the "peak" that each parameter belongs
%                        to. (Was "peakIndex".)
%              Column 2: Identifies the type of model parameter e.g.
%                        chemShift, ... (Was "paramIndex".)
%              Column 3: String identifier for user-display. Montage of
%                        columns 1 and 2.
%
%
% N.B. There is a split in Matlab AMARES between "peaks" and "multiplet
% components". For singlets, these are the same thing. But e.g. a triplet
% is 1 "peak" but 3 "multiplet components".

numPeaks = numel(pk.initialValues);
Bounds = fieldnames(pk.bounds);
numBounds = numel(Bounds);

optimInit = [];
optimLBounds = [];
optimUBounds = [];
peakIndex = [];
paramIndex = {};

counter = 1;
for f = 1:numBounds
    group = 0;
    inc = 0; % appears to be unused
    for p = 1:numPeaks
        if ~isempty(pk.bounds(p).(Bounds{f})) && isnumeric(pk.bounds(p).(Bounds{f})) % bounds field is a non-empty numeric
            if isfield(pk.priorKnowledge,['G_' Bounds{f}]) && ~isempty(pk.priorKnowledge(p).(['G_' Bounds{f}])) && group == pk.priorKnowledge(p).(['G_' Bounds{f}]) % boundsfield is grouped with current group
               % inc = inc+1;   
            else
                if isfield(pk.priorKnowledge,['G_' Bounds{f}]) && ~isempty(pk.priorKnowledge(p).(['G_' Bounds{f}])) && group ~= pk.priorKnowledge(p).(['G_' Bounds{f}]) % bounds field is grouped, but not with current group
                    group = pk.priorKnowledge(p).(['G_' Bounds{f}]);
                end
                if isfield(pk.initialValues, Bounds{f}) % bounds field is associated with an initial value field
                    if ~isempty(pk.initialValues(p).(Bounds{f})) % field has an initial value
                        optimInit(counter) = pk.initialValues(p).(Bounds{f});
                    else
                        optimInit(counter) = mean(pk.bounds(p).(Bounds{f}));
                    end
                elseif isfield(pk.priorKnowledge, Bounds{f}) % bounds field is associated with a prior knowledge field
                    if ~isempty(pk.priorKnowledge(p).(Bounds{f})) % field has prior knowledge
                        optimInit(counter) = pk.priorKnowledge(p).(Bounds{f});
                    else
                        optimInit(counter) = mean(pk.bounds(p).(Bounds{f}));
                    end
                end
                optimLBounds(counter) = pk.bounds(p).(Bounds{f})(1);
                optimUBounds(counter) = pk.bounds(p).(Bounds{f})(2);
                peakIndex(counter) = p;
                paramIndex{counter} = Bounds{f};
                
                if ~isempty(pk.priorKnowledge(p).multiplet) 
                   inc = inc+length(pk.priorKnowledge(p).multiplet)-1; 
                end
                
                counter = counter + 1;
            end
        else
            inc = inc+1;
        end
    end
end

optimIndex = cell(3,numel(peakIndex));
for idx=1:numel(peakIndex)
    optimIndex{1,idx} = peakIndex(idx);
    optimIndex{2,idx} = paramIndex{idx};
    pkName = pk.priorKnowledge(peakIndex(idx)).peakName;
    if iscell(pkName)
        pkName = pkName{1};
    end
    optimIndex{3,idx} = sprintf('%s.%s',pkName,paramIndex{idx});
end
