function [constraintsCellArray] = createModelConstraints(pk, optimIndex)
% Computes cell arrays of {constraint type, params} expressing the
% constraints on each model parameter.
%
% E.g.
% chemShift_fun{p+m_count} = {'@(x)x(a);',v} % Constrained equal to parameter with index v.
%
% The cell arrays are supplied to makeModelFid during the least squares
% fitting, which calls applyModelConstraints(...) to apply the constraints
% to determine the constrained parameter values from the unconstrained
% values that are in the process of being fitted. The parameter "x" is the
% vector of parameter values being varied by lsqcurvefit.


% optimIndex is a cell containing the peak indices in the first row, and
% the parameter indices in the second.
numParams = size(optimIndex,2);
numPeaks = numel(pk.priorKnowledge);

chemShift_fun = {};
linewidth_fun = {};
sigma_fun = {};
amplitude_fun = {};
phase_fun = {};
multiplet_count = 0; % index shift corresponding to number of multiplets minus first peak in each multiplet

for peakDx = 1:numPeaks
    %
    if isempty(pk.priorKnowledge(peakDx).multiplet)
        
        maxMultipletDx = 1;
        
    elseif ~isempty(pk.priorKnowledge(peakDx).multiplet)
        
        maxMultipletDx = numel(pk.priorKnowledge(peakDx).multiplet);
        
    end
    
    for multipletDx = 1:maxMultipletDx
        
        if multipletDx~=1
            multiplet_count = multiplet_count + 1;
        end
        %%   If bounds are empty, constrain to initial value
        
        if isempty(pk.bounds(peakDx).chemShift) && ~isempty(pk.initialValues(peakDx).chemShift)
            chemShift_fun{peakDx+multiplet_count} = {'@(a)a;',pk.initialValues(peakDx).chemShift}; %#ok<*AGROW>
        end
        
        if isempty(pk.bounds(peakDx).linewidth) && ~isempty(pk.initialValues(peakDx).linewidth)
            linewidth_fun{peakDx+multiplet_count} = {'@(a)a;',pk.initialValues(peakDx).linewidth};
        end
        if isfield(pk.bounds(peakDx),'sigma')&&isfield(pk.initialValues(peakDx),'sigma')&&isempty(pk.bounds(peakDx).sigma) && ~isempty(pk.initialValues(peakDx).sigma)
            % Sigma is not present in all PK, so check first.
            sigma_fun{peakDx+multiplet_count} = {'@(a)a;',pk.initialValues(peakDx).sigma};
        else
            % Set Gaussian linewidth to zero
            sigma_fun{peakDx+multiplet_count} = {'@(a)a;',0};
        end
        if isempty(pk.bounds(peakDx).amplitude) && ~isempty(pk.initialValues(peakDx).amplitude)
            amplitude_fun{peakDx+multiplet_count} = {'@(a)a;',pk.initialValues(peakDx).amplitude};
        end
        if isempty(pk.bounds(peakDx).phase) && ~isempty(pk.initialValues(peakDx).phase)
            phase_fun{peakDx+multiplet_count} = {'@(a)a;',pk.initialValues(peakDx).phase};
        end
        
        %%   Loop through peaks and parameters
        
        for paramDx = 1:numParams
            if strcmp(optimIndex{2,paramDx},'chemShift') && ... parameter is chemShift
                    optimIndex{1,paramDx}==peakDx % parameter corresponds to current peak
                
               % Set chemical shift prior
               
                if ~isempty(pk.priorKnowledge(peakDx).multiplet) % peak is a multiplet
                    
                    if ~isempty(pk.priorKnowledge(peakDx).chemShiftDelta) && isempty(pk.bounds(peakDx).chemShiftDelta) % chemShiftDelta is constrained to prior knowledge (prior knowledge & no bounds)
                        chemShift_fun{peakDx+multiplet_count} = {'@(x,a,b)x(a)+b;',paramDx,(multipletDx-1)*pk.priorKnowledge(peakDx).chemShiftDelta};
                    else % chemShiftDelta is not constrained to prior knowledge (no prior knowledge &/or bounded)
                        for relParamDx = 1:numParams
                            if strcmp(optimIndex{2,relParamDx},'chemShiftDelta') && ... relParameter is chemShiftDelta
                                    ((isempty(pk.priorKnowledge(peakDx).G_chemShiftDelta) && optimIndex{1,relParamDx}==peakDx) || ... peak chemShiftDelta is not grouped & relParameter corresponds to current peak
                                    (~isempty(pk.priorKnowledge(peakDx).G_chemShiftDelta) && optimIndex{1,relParamDx}==pk.priorKnowledge(peakDx).G_chemShiftDelta)) % peak chemShiftDelta is grouped & relParameter corresponds to chemShiftDelta group peak
                                chemShift_fun{peakDx+multiplet_count} = {'@(x,a,b,c)x(a)+b*x(c);',paramDx,(multipletDx-1),relParamDx};
                            end
                        end
                    end
                    
                else % peak is a singlet
                    
                    chemShift_fun{peakDx+multiplet_count} = {'@(x,a)x(a);',paramDx};
                    
                end
                
            elseif strcmp(optimIndex{2,paramDx},'linewidth') && ... parameter is linewidth
                    ((isempty(pk.priorKnowledge(peakDx).G_linewidth) && optimIndex{1,paramDx}==peakDx) || ... peak linewidth is not grouped & parameter corresponds to current peak
                    (~isempty(pk.priorKnowledge(peakDx).G_linewidth) && optimIndex{1,paramDx}==pk.priorKnowledge(peakDx).G_linewidth)) % peak linewidth is grouped & parameter corresponds to linewidth group peak
                
                % Set lorenztian linewidth prior
                
                if isfield(pk.priorKnowledge(peakDx),'base_linewidth') && ~isempty(pk.priorKnowledge(peakDx).base_linewidth) % prior knowledge of base_linewidth is present
                    % LP: If we know the T2, then ADD this intrinsic linewidth to that being fitted.
                    linewidth_fun{peakDx+multiplet_count} = {'@(x,a,b)x(a)+b;',paramDx,pk.priorKnowledge(peakDx).base_linewidth};
                else % no prior knowledge of base_linewidth
                    % Normal mode
                    linewidth_fun{peakDx+multiplet_count} = {'@(x,a)x(a);',paramDx};
                    
                end
                       
            elseif strcmp(optimIndex{2,paramDx},'amplitude') && ... parameter is amplitude
                    ((isempty(pk.priorKnowledge(peakDx).G_amplitude) && optimIndex{1,paramDx}==peakDx) || ... peak amplitude is not grouped & parameter corresponds to current peak
                    (~isempty(pk.priorKnowledge(peakDx).G_amplitude) && optimIndex{1,paramDx}==pk.priorKnowledge(peakDx).G_amplitude)) % peak amplitude is grouped & parameter corresponds to amplitude group peak
                
                % Set amplitude prior
                
                if ~isempty(pk.priorKnowledge(peakDx).multiplet) && pk.priorKnowledge(peakDx).multiplet(multipletDx)~=0 % peak is a multiplet & multiplet is affected by amplitudeRatio (i.e. non-zero)
                    
                    % Assign relative amplitudes to multiplet peaks
                    
                    if ~isempty(pk.priorKnowledge(peakDx).amplitudeRatio) && isempty(pk.bounds(peakDx).amplitudeRatio) % amplitudeRatio is constrained to prior knowledge (prior knowledge & no bounds)
                        amplitude_fun{peakDx+multiplet_count} = {'@(x,a,b)x(a)*b;',paramDx,pk.priorKnowledge(peakDx).amplitudeRatio};
                    else % amplitudeRatio is not constrained to prior knowledge (prior knowledge &/or bounded)
                        for relParamDx = 1:numParams
                            % Loop through peaks to find the one that this peak will be constrained to
                            if strcmp(optimIndex{2,relParamDx},'amplitudeRatio') && ... relParameter is amplitudeRatio
                                    optimIndex{1,relParamDx}==peakDx % relParameter corresponds to current peak
                                amplitude_fun{peakDx+multiplet_count} = {'@(x,a,b)x(a)*x(b);',relParamDx,paramDx};
                            end
                        end
                    end
                    
                else % peak is singlet or unaffected by amplitudeRatio (i.e. zero)
                    amplitude_fun{peakDx+multiplet_count} = {'@(x,a)x(a);',paramDx};
                end
                
            elseif strcmp(optimIndex{2,paramDx},'phase') && ... parameter is phase
                    ((isempty(pk.priorKnowledge(peakDx).G_phase) && optimIndex{1,paramDx}==peakDx) || ... peak phase is not grouped & parameter corresponds to current peak
                    (~isempty(pk.priorKnowledge(peakDx).G_phase) && optimIndex{1,paramDx}==pk.priorKnowledge(peakDx).G_phase)) % peak phase is grouped & parameter corresponds to phase group peak
                
                % Set phase prior
                
                if isfield(pk.priorKnowledge(peakDx),'base_phase') && ~isempty(pk.priorKnowledge(peakDx).base_phase) % prior knowledge of base_phase is present
                    
                    %WTC: To enable relative phase shifts.
                    phase_fun{peakDx+multiplet_count} = {'@(x,a,b)x(a)+b;',paramDx,pk.priorKnowledge(peakDx).base_phase};
                    
                else % no prior knowledge of base_phase
                    
                    % Normal mode
                    phase_fun{peakDx+multiplet_count} = {'@(x,a)x(a);',paramDx};
                    
                end
                
                       
            elseif strcmp(optimIndex{2,paramDx},'sigma') && ... parameter is sigma
                    (((~isfield(pk.priorKnowledge(peakDx),'G_sigma')||isempty(pk.priorKnowledge(peakDx).G_sigma)) && optimIndex{1,paramDx}==peakDx) || ... peak sigma is not grouped & parameter corresponds to current peak
                    ((isfield(pk.priorKnowledge(peakDx),'G_sigma')&&~isempty(pk.priorKnowledge(peakDx).G_sigma)) && optimIndex{1,paramDx}==pk.priorKnowledge(peakDx).G_sigma)) % peak sigma is grouped & parameter corresponds to sigma group peak
                
                % Set Gaussian lineshape prior
                
                if isfield(pk.bounds(peakDx),'sigma')&&~isempty(pk.bounds(peakDx).sigma) % sigma is bounded
                    sigma_fun{peakDx+multiplet_count} = {'@(x,a)x(a);',paramDx};
                end
                
            end
            
        end
        
    end
end

% Remove _fun from end of variable so that it is simpler to call in e.g.
% applyModelConstraints
constraintsCellArray.chemShift = chemShift_fun;
constraintsCellArray.linewidth = linewidth_fun;
constraintsCellArray.amplitude = amplitude_fun;
constraintsCellArray.phase = phase_fun;
constraintsCellArray.sigma = sigma_fun;

