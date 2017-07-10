function [] = estimateDerivedParamAndCRB_saveCached(pk, constraintsCellArray, derivedParamStr, extraParamStr, derivedParam_MFunc, Jsym_MFunc)
% Save the cached AMARES CRB formulas to a .mat file.

cacheFilename = fullfile(RodgersSpectroToolsRoot(),'main','+AMARES','estimateDerivedParamAndCRB_CACHE.mat');

try
    cache = load(cacheFilename);
catch
    cache = struct('cache',[]);
end

cache.cache(end+1).pk = pk;
cache.cache(end).constraintsCellArray = constraintsCellArray;
cache.cache(end).derivedParamStr = derivedParamStr;
cache.cache(end).extraParamStr = extraParamStr;

% There is an annoying Matlab quirk whereby anonymous function handles
% store the full workspace of the function in which they were generated.
% This means these functions contain references to the symbollic maths
% toolbox. Strip that out here.
%
% E.g.
% >> vvv=functions(cache(1).derivedParam_MFunc{1})
% vvv = 
%      function: 'makeFhandle/@(ATP_GAMMA1_am,ATP_GAMMA2_am,PCR_am)PCR_am./(ATP_GAMMA1_am+ATP_GAMMA2_am)'
%          type: 'anonymous'
%          file: 'D:\Program Files\MATLAB\R2014a_pre\toolbox\symbolic\symbolic\symengine.p'
%     workspace: {2x1 cell}
% but
% >> var2 = str2func(func2str(cache(1).derivedParam_MFunc{1}));
% >> vvv2=functions(var2)
% vvv2 = 
%      function: '@(ATP_GAMMA1_am,ATP_GAMMA2_am,PCR_am)PCR_am./(ATP_GAMMA1_am+ATP_GAMMA2_am)'
%          type: 'anonymous'
%          file: ''
%     workspace: {[1x1 struct]}

cache.cache(end).derivedParam_MFunc = cellfun(@(x) str2func(func2str(x)), derivedParam_MFunc, 'UniformOutput', false);
cache.cache(end).Jsym_MFunc = cellfun(@(x) str2func(func2str(x)), Jsym_MFunc, 'UniformOutput', false);
    
try
	save(cacheFilename,'-struct','cache')
catch
end
