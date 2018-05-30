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
numPeaks = size(optimIndex,2);
numCompounds = numel(pk.priorKnowledge);

chemShift_fun = {};
linewidth_fun = {};
sigma_fun = {};
amplitude_fun = {};
phase_fun = {};
multiplet_count = 0;

for compoundDx = 1:numCompounds
    %
    if isempty(pk.priorKnowledge(compoundDx).multiplet)
        
        maxMultipletDx = 1;
        
    elseif ~isempty(pk.priorKnowledge(compoundDx).multiplet)
        
        maxMultipletDx = numel(pk.priorKnowledge(compoundDx).multiplet);
        
    end
    
    for multipletDx = 1:maxMultipletDx
        
        if multipletDx~=1
            multiplet_count = multiplet_count + 1;
        end
        %%   If bounds are empty, constrain to initial value
        
        if isempty(pk.bounds(compoundDx).chemShift) && ~isempty(pk.initialValues(compoundDx).chemShift)
            chemShift_fun{compoundDx + multiplet_count} = {'@(a)a;',pk.initialValues(compoundDx).chemShift}; %#ok<*AGROW>
        end
        
        if isempty(pk.bounds(compoundDx).linewidth) && ~isempty(pk.initialValues(compoundDx).linewidth)
            linewidth_fun{compoundDx + multiplet_count} = {'@(a)a;',pk.initialValues(compoundDx).linewidth};
        end
        if isfield(pk.bounds(compoundDx),'sigma')&&isfield(pk.initialValues(compoundDx),'sigma')&&isempty(pk.bounds(compoundDx).sigma) && ~isempty(pk.initialValues(compoundDx).sigma)
            % Sigma is not present in all PK, so check first.
            sigma_fun{compoundDx + multiplet_count} = {'@(a)a;',pk.initialValues(compoundDx).sigma};
        else
            % Set Gaussian linewidth to zero
            sigma_fun{compoundDx + multiplet_count} = {'@(a)a;',0};
        end
        if isempty(pk.bounds(compoundDx).amplitude) && ~isempty(pk.initialValues(compoundDx).amplitude)
            amplitude_fun{compoundDx + multiplet_count} = {'@(a)a;',pk.initialValues(compoundDx).amplitude};
        end
        if isempty(pk.bounds(compoundDx).phase) && ~isempty(pk.initialValues(compoundDx).phase)
            phase_fun{compoundDx + multiplet_count} = {'@(a)a;',pk.initialValues(compoundDx).phase};
        end
        
        %%   Loop through peaks and parameters
        
        for peakDx = 1:numPeaks
            if optimIndex{1,peakDx}==compoundDx && strcmp(optimIndex{2,peakDx},'chemShift')
                
               % Set chemical shift prior
               
                if ~isempty(pk.priorKnowledge(compoundDx).multiplet)
                    
                    if ~isempty(pk.priorKnowledge(compoundDx).chemShiftDelta) && isempty(pk.bounds(compoundDx).chemShiftDelta)
                        chemShiftDelta = pk.priorKnowledge(compoundDx).chemShiftDelta;
                        chemShift_fun{compoundDx+multiplet_count} = {'@(x,a,b)x(a)+b;',peakDx,(multipletDx-1)*chemShiftDelta};
                    else
                        for relPeakDx = 1:numPeaks
                            if (isempty(pk.priorKnowledge(compoundDx).G_chemShiftDelta) && optimIndex{1,relPeakDx}==compoundDx && strcmp(optimIndex{2,relPeakDx},'chemShiftDelta')) || ...
                                    (~isempty(pk.priorKnowledge(compoundDx).G_chemShiftDelta) && optimIndex{1,relPeakDx}==pk.priorKnowledge(compoundDx).G_chemShiftDelta && strcmp(optimIndex{2,relPeakDx},'chemShiftDelta'))
                                chemShift_fun{compoundDx+multiplet_count} = {'@(x,a,b,c)x(a)+b*x(c);',peakDx,(multipletDx-1),relPeakDx};
                            end
                        end
                    end
                    
                else
                    
                    chemShift_fun{compoundDx+multiplet_count} = {'@(x,a)x(a);',peakDx};
                    
                end
                
            elseif (isempty(pk.priorKnowledge(compoundDx).G_linewidth) && optimIndex{1,peakDx}==compoundDx && strcmp(optimIndex{2,peakDx},'linewidth')) || ...
                    (~isempty(pk.priorKnowledge(compoundDx).G_linewidth) && optimIndex{1,peakDx}==pk.priorKnowledge(compoundDx).G_linewidth && strcmp(optimIndex{2,peakDx},'linewidth'))
                
                % Set lorenztian linewidth prior
                
                if isfield(pk.priorKnowledge(compoundDx),'base_linewidth') && ~isempty(pk.priorKnowledge(compoundDx).base_linewidth)
                    % LP: If we know the T2, then ADD this intrinsic linewidth to that being fitted.
                    linewidth_fun{compoundDx+multiplet_count} = {'@(x,a,b)x(a)+b;',peakDx,pk.priorKnowledge(compoundDx).base_linewidth};
                else
                    % Normal mode
                    linewidth_fun{compoundDx+multiplet_count} = {'@(x,a)x(a);',peakDx};
                    
                end
                       
            elseif (isempty(pk.priorKnowledge(compoundDx).G_amplitude) && optimIndex{1,peakDx}==compoundDx && strcmp(optimIndex{2,peakDx},'amplitude')) || ...
                    (~isempty(pk.priorKnowledge(compoundDx).G_amplitude) && optimIndex{1,peakDx}==pk.priorKnowledge(compoundDx).G_amplitude && strcmp(optimIndex{2,peakDx},'amplitude'))
                
                % Set amplitude prior
                
                if ~isempty(pk.priorKnowledge(compoundDx).multiplet)&&pk.priorKnowledge(compoundDx).multiplet(multipletDx) ~= 0
                    
                    % Assign relative amplitudes to multiplet peaks
                    
                    if ~isempty(pk.priorKnowledge(compoundDx).amplitudeRatio) && isempty(pk.bounds(compoundDx).amplitudeRatio)
                        amplitudeRatio = pk.priorKnowledge(compoundDx).amplitudeRatio;
                        amplitude_fun{compoundDx+multiplet_count} = {'@(x,a,b)x(a)*b;',peakDx,amplitudeRatio};
                    else
                        for relPeakDx = 1:numPeaks
                            % Loop through peaks to find the one that this
                            % peak will be constrained to.
                            if optimIndex{1,relPeakDx}==compoundDx && strcmp(optimIndex{2,relPeakDx},'amplitudeRatio')
                                amplitude_fun{compoundDx+multiplet_count} = {'@(x,a,b)x(a)*x(b);',relPeakDx,peakDx};
                            end
                        end
                    end
                    
                else
                    amplitude_fun{compoundDx+multiplet_count} = {'@(x,a)x(a);',peakDx};
                end
                
            elseif (isempty(pk.priorKnowledge(compoundDx).G_phase) && optimIndex{1,peakDx}==compoundDx && strcmp(optimIndex{2,peakDx},'phase')) || ...
                    (~isempty(pk.priorKnowledge(compoundDx).G_phase) && optimIndex{1,peakDx}==pk.priorKnowledge(compoundDx).G_phase && strcmp(optimIndex{2,peakDx},'phase'))
                
                % Set phase prior
                
                if isfield(pk.priorKnowledge(compoundDx),'RelPhase') && ~isempty(pk.priorKnowledge(compoundDx).RelPhase)
                    
                    %WTC: To enable relative phase shifts.
                    phase_fun{compoundDx+multiplet_count} = {'@(x,a,b)x(a)+b;',peakDx,pk.priorKnowledge(compoundDx).RelPhase};
                    
                else
                    
                    % Normal mode
                    phase_fun{compoundDx+multiplet_count} = {'@(x,a)x(a);',peakDx};
                    
                end
                
                       
            elseif ((~isfield(pk.priorKnowledge(compoundDx),'G_sigma')||isempty(pk.priorKnowledge(compoundDx).G_sigma)) && optimIndex{1,peakDx}==compoundDx && strcmp(optimIndex{2,peakDx},'sigma')) || ...
                    ((isfield(pk.priorKnowledge(compoundDx),'G_sigma')&&~isempty(pk.priorKnowledge(compoundDx).G_sigma)) && optimIndex{1,peakDx}==pk.priorKnowledge(compoundDx).G_sigma && strcmp(optimIndex{2,peakDx},'sigma'))
                
                % Set Gaussian lineshape prior
                
                if isfield(pk.bounds(compoundDx),'sigma')&&~isempty(pk.bounds(compoundDx).sigma)
                    sigma_fun{compoundDx+multiplet_count} = {'@(x,a)x(a);',peakDx};
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

