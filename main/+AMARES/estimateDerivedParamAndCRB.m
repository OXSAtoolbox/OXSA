function [derivedParamVal, CRB] = estimateDerivedParamAndCRB(pk, xFit, constraintsCellArray, CRB_covariance_in, derivedParamStr, extraParamStr, extraParamVals)
% Calculate the CRB for a derived parameter with help from the symbolic maths toolbox.
%
% derivedParamStr is a cell array of strings specifying the derived
% parameter to compute.
%
% ..._cs is a peak chemical shift
% ..._lw is a peak linewidth
% ..._am is a peak amplitude
% ..._ph is a peak phase
% 
% extraParamStr is a cell array of strings specifying external (non-fitted)
%        parameters e.g. saturation factors.
%
% extraParamVals is a double vector with the values of the parameters in
%        extraParamStr.
%
% EXAMPLE:
%
% prior = struct('pk',AMARES.priorKnowledge.PK_3T_Cardiac());
% res = AMARES.amaresDriver(obj,'type','voxel','prior',prior,'forceFitAgain',true);
% CRB = AMARES.estimateCRB(res{1}.fitStatus{1}.exptParams.imagingFrequency, res{1}.fitStatus{1}.exptParams.dwellTime, res{1}.fitStatus{1}.exptParams.beginTime, res{1}.fitStatus{1}.noise_var, res{1}.fitStatus{1}.xFit, res{1}.fitStatus{1}.constraintsCellArray)
% [ratio_vals, ratio_crbs] = AMARES.estimateDerivedParamAndCRB(res{1}.fitStatus{1}.pkWithLinLsq, res{1}.fitStatus{1}.xFit, res{1}.fitStatus{1}.constraintsCellArray,CRB.covariance,{'PCR_am / (ATP_GAMMA1_am + ATP_GAMMA2_am)','PCR_am / ((ATP_ALPHA1_am + ATP_ALPHA2_am + ATP_BETA1_am + ATP_BETA2_am + ATP_BETA3_am + ATP_GAMMA1_am + ATP_GAMMA2_am)/3)'})

if ~exist('extraParamStr','var')
    extraParamStr = {};
end

if ~exist('extraParamVals','var')
    extraParamVals = [];
end

if ~iscell(derivedParamStr)
    derivedParamStr = {derivedParamStr};
end

multipletComponentToPeakIndex = AMARES.getMultipletComponentToPeakIndex(pk);

[chemShift, linewidth, amplitude, phase] = AMARES.applyModelConstraints(xFit, constraintsCellArray);

% Check for cached version of the CRB formulae - [] is returned if no
% cache entry matches.
[derivedParam_MFunc, Jsym_MFunc] = AMARES.estimateDerivedParamAndCRB_loadCached(pk, constraintsCellArray, derivedParamStr, extraParamStr);

if ~isempty(derivedParam_MFunc) && ~isempty(Jsym_MFunc)
    % Cache hit - use pure Matlab
    
    % The fits
    for idx=1:size(multipletComponentToPeakIndex,2)
        allParamsStruct.([multipletComponentToPeakIndex{1,idx} '_cs']) = chemShift(idx);
        allParamsStruct.([multipletComponentToPeakIndex{1,idx} '_lw']) = linewidth(idx);
        allParamsStruct.([multipletComponentToPeakIndex{1,idx} '_am']) = amplitude(idx);
        allParamsStruct.([multipletComponentToPeakIndex{1,idx} '_ph']) = phase(idx);
    end
    
    for idx = 1:numel(extraParamStr)
        allParamsStruct.(extraParamStr{idx}) = extraParamVals(idx);
    end
    
    % Apply the Matlab formula(e)
    derivedParamVal = NaN(size(derivedParamStr));
    CRB = NaN(size(derivedParamStr));
    for paramDx = 1:numel(derivedParamStr)
        
        % Identify the required inputs
        requiredInputs = regexp(regexp(func2str(derivedParam_MFunc{paramDx}),'(?<=\@\()[^)]*','match','once'),',','split');
        valueArray = cellfun(@(x) allParamsStruct.(x),requiredInputs,'uniformoutput',false);
        % Evaluate
        derivedParamVal(paramDx) = derivedParam_MFunc{paramDx}(valueArray{:});
        
        % Identify the required inputs
        requiredInputs = regexp(regexp(func2str(Jsym_MFunc{paramDx}),'(?<=\@\()[^)]*','match','once'),',','split');
        if strcmp(requiredInputs{1},'')
            valueArray = {};
        else
            valueArray = cellfun(@(x) allParamsStruct.(x),requiredInputs,'uniformoutput',false);
        end
        % Evaluate
        Jnum = Jsym_MFunc{paramDx}(valueArray{:});
        
        CRB(paramDx) = sqrt(Jnum*CRB_covariance_in*Jnum');
        fprintf('= %.3f (SD %.3f = %.1f%%) [%s]\n',derivedParamVal(paramDx),CRB(paramDx),100*CRB(paramDx)/derivedParamVal(paramDx),derivedParamStr{paramDx})
    end
    
else
    % Cache miss - use symbolic maths toolbox
    if isdeployed()
        error('Symbolic toolbox not available in deployed code. Run AMARES..... to update cached CRB formulae.')
    end
    
    allParams = cell(size(multipletComponentToPeakIndex,2),5);
    for idx=1:size(multipletComponentToPeakIndex,2)
        allParams(4*idx-3,:) = {[multipletComponentToPeakIndex{1,idx} '_cs'], sym([multipletComponentToPeakIndex{1,idx} '_cs']), multipletComponentToPeakIndex{1,idx}, 'cs', chemShift(idx)};
        allParams(4*idx-2,:) = {[multipletComponentToPeakIndex{1,idx} '_lw'], sym([multipletComponentToPeakIndex{1,idx} '_lw']), multipletComponentToPeakIndex{1,idx}, 'lw', linewidth(idx)};
        allParams(4*idx-1,:) = {[multipletComponentToPeakIndex{1,idx} '_am'], sym([multipletComponentToPeakIndex{1,idx} '_am']), multipletComponentToPeakIndex{1,idx}, 'am', amplitude(idx)};
        allParams(4*idx-0,:) = {[multipletComponentToPeakIndex{1,idx} '_ph'], sym([multipletComponentToPeakIndex{1,idx} '_ph']), multipletComponentToPeakIndex{1,idx}, 'ph', phase(idx)};
    end
    
    % Now apply this to the formula(e)
    derivedParamVal = NaN(size(derivedParamStr));
    CRB = NaN(size(derivedParamStr));
    for paramDx = 1:numel(derivedParamStr)
        derivedParam = sym(derivedParamStr{paramDx});
        
        % Cache anonymous Matlab function handles for future runs / deployed mode
        derivedParam_MFunc{paramDx} = matlabFunction(derivedParam);
        Jsym_MFunc{paramDx} = matlabFunction(jacobian(derivedParam,[allParams{:,2}]));
        
        % Substitute in extra parameters if provided
        if ~isempty(extraParamStr)
            extraParam = sym(extraParamStr);
            
            derivedParam = subs(derivedParam,extraParam,extraParamVals);
        end
        
        derivedParamVal(paramDx) = subs(derivedParam,[allParams{:,2}],[allParams{:,5}]);
        
        Jsym = jacobian(derivedParam,[allParams{:,2}]);
        Jnum = subs(Jsym,[allParams{:,2}],[allParams{:,5}]);
        
        CRB(paramDx) = sqrt(Jnum*CRB_covariance_in*Jnum');
        fprintf('= %.3f (SD %.3f = %.1f%%) [%s]\n',derivedParamVal(paramDx),CRB(paramDx),100*CRB(paramDx)/derivedParamVal(paramDx),derivedParamStr{paramDx})
    end
    
    % Save anonymous function cache
    AMARES.estimateDerivedParamAndCRB_saveCached(pk, constraintsCellArray, derivedParamStr, extraParamStr, derivedParam_MFunc, Jsym_MFunc);
end

% %% Specific example...
% 
% % PCr / gATP ratio
% syms am1 am2 am3 am4 am5 am6 am7 am8 am9 am10 am11
% am = [am1 am2 am3 am4 am5 am6 am7 am8 am9 am10 am11];
% ratio = am8 / (am6 + am7)
% tmpP = jacobian(ratio,am)
% 
% tmpPnum = subs(tmpP,am,amplitude)
% 
% mPratioExtra = zeros(1,44);
% mPratioExtra(3:4:end) = tmpPnum
% 
% % Calculate the final CRB only
% sqrt(diag(mP*inv(Fishernum)*mP'))
% 
% % Calculate the derived param CRB only
% sqrt(diag(mPratioExtra*mP*inv(Fishernum)*mP'*mPratioExtra'))
% 
% sqrt(diag(mPratioExtra*CRB.covariance*mPratioExtra'))
% 
% %%
% opengl software; figure(10101);clf;pcolorV2('x',1:44,'y',1:44,'c',abs(CRB.covariance));colormap(jet(256));colorbar;caxis([0 100])