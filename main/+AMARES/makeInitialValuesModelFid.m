function [modelFid, modelFids] = makeInitialValuesModelFid(pk, exptParams, varargin)
options = processVarargin(varargin{:});

params = fieldnames(pk.initialValues(1));
params(1) = []; %Remove peak name string

multiplet_count = 0;

for compoundDx = 1:numel(pk.initialValues)
    
    if isempty(pk.priorKnowledge(compoundDx).multiplet)
        
        maxMultipletDx = 1;
        
    elseif ~isempty(pk.priorKnowledge(compoundDx).multiplet)
        
        maxMultipletDx = numel(pk.priorKnowledge(compoundDx).multiplet);
        
    end
    
    for multipletDx = 1:maxMultipletDx
        
        if multipletDx~=1
            multiplet_count = multiplet_count + 1;
        end
        
        peakDx(compoundDx + multiplet_count,:) = [compoundDx, compoundDx + multiplet_count];%#okAGROW
        
        
        for pDx = 1:numel(params)
            if ~isempty(pk.initialValues(compoundDx).(params{pDx}))
            modelParams.(params{pDx})(compoundDx + multiplet_count) = pk.initialValues(compoundDx).(params{pDx});
            end
        end
        
        if isfield(options, 'fixAmpPhase')&&options.fixAmpPhase
            modelParams.amplitude(compoundDx + multiplet_count) = 1;
            modelParams.phase(compoundDx + multiplet_count) = 0;
        end
        
        if ~isempty(pk.priorKnowledge(compoundDx).multiplet)
            
            
            if ~isempty(pk.priorKnowledge(compoundDx).chemShiftDelta)
                modelParams.chemShift(compoundDx + multiplet_count) = modelParams.chemShift(compoundDx + multiplet_count) + (multipletDx-1)*pk.priorKnowledge(compoundDx).chemShiftDelta;
            end
            
            if ~isempty(pk.priorKnowledge(compoundDx).amplitudeRatio)&&pk.priorKnowledge(compoundDx).multiplet(multipletDx) ~= 0
                modelParams.amplitude(compoundDx + multiplet_count) = modelParams.amplitude(compoundDx + multiplet_count)*pk.priorKnowledge(compoundDx).amplitudeRatio;
            end
        end
        
    end
    
    
end

bandwidth = 1/exptParams.dwellTime;

tTrue = ((0:(exptParams.samples-1)).'/(bandwidth)) + exptParams.beginTime; % In seconds

[modelFid, modelFids] = AMARES.makeModelFid(modelParams, tTrue, exptParams.imagingFrequency);

if isfield(options, 'sumMultiplets')&&options.sumMultiplets
    tmp_modelFids = zeros(size(modelFids,1),numel(pk.initialValues));
    for compoundDx = 1:size(peakDx,1)
        tmp_modelFids(:,peakDx(compoundDx,1)) = tmp_modelFids(:,peakDx(compoundDx,1))+modelFids(:,compoundDx);
    end
    modelFids = tmp_modelFids;
end