function [derivedParam_MFunc, Jsym_MFunc] = estimateDerivedParamAndCRB_loadCached(pk, constraintsCellArray, derivedParamStr, extraParamStr)
% Load the cached AMARES CRB formulas from a .mat file. Check if any of the
% stored files match the supplied problem.
%
% Returns Matlab anonymous function handles for computing derivedParamVals
% and Jnum in AMARES.estimateDerivedParamAndCRB.m

derivedParam_MFunc = [];
Jsym_MFunc = [];

try
    % Matlab compiler script include:
    %#include estimateDerivedParamAndCRB_CACHE.mat
    cacheFilename = fullfile(RodgersSpectroToolsRoot(),'main','+AMARES','estimateDerivedParamAndCRB_CACHE.mat');
    
    cache = load(cacheFilename);
    
    for cacheDx = 1:numel(cache.cache)
        
        if isequal(cache.cache(cacheDx).pk.priorKnowledge,pk.priorKnowledge) ...
                && isequal(cache.cache(cacheDx).constraintsCellArray,constraintsCellArray) ...
                && isequal(cache.cache(cacheDx).derivedParamStr,derivedParamStr) ...
                && isequal(cache.cache(cacheDx).extraParamStr,extraParamStr)
            
            % Cache hit.
            derivedParam_MFunc = cache.cache(cacheDx).derivedParam_MFunc;
            Jsym_MFunc = cache.cache(cacheDx).Jsym_MFunc;
            
            return
        end
    end
    
    % Cache miss.
    
catch ME
    
end
