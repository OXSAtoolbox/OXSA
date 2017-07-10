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

nv = size(optimIndex,2);
np = numel(pk.priorKnowledge);
chemShift_fun = {};
linewidth_fun = {};
amplitude_fun = {};
phase_fun = {};
m_count = 0;
% optimIndex = cell(2,nv);
% syms cs lw am ph conP;

% for i = 1:nv
% optimIndex{1,i} = peakIndex(i);                           
% optimIndex{2,i} = paramIndex{i};
% end

for p = 1:np
    if isempty(pk.bounds(p).chemShift) && ~isempty(pk.initialValues(p).chemShift)
        chemShift_fun{p+m_count} = {'@(a)a;',pk.initialValues(p).chemShift}; %#ok<*AGROW>
%         cs(p+m_count) = 0;
    end
    if isempty(pk.bounds(p).linewidth) && ~isempty(pk.initialValues(p).linewidth)

            linewidth_fun{p+m_count} = {'@(a)a;',pk.initialValues(p).linewidth};
%         lw(p+m_count) = 0;
    end
    if isempty(pk.bounds(p).amplitude) && ~isempty(pk.initialValues(p).amplitude)
        amplitude_fun{p+m_count} = {'@(a)a;',pk.initialValues(p).amplitude};
%         am(p+m_count) = 0;
    end
    if isempty(pk.bounds(p).phase) && ~isempty(pk.initialValues(p).phase)
        phase_fun{p+m_count} = {'@(a)a;',pk.initialValues(p).phase};
%         ph(p+m_count) = 0;
    end
    if isempty(pk.priorKnowledge(p).multiplet)
        for v = 1:nv
            if optimIndex{1,v}==p && strcmp(optimIndex{2,v},'chemShift')
                chemShift_fun{p+m_count} = {'@(x,a)x(a);',v};
            elseif (isempty(pk.priorKnowledge(p).G_linewidth) && optimIndex{1,v}==p && strcmp(optimIndex{2,v},'linewidth')) || ...
                    (~isempty(pk.priorKnowledge(p).G_linewidth) && optimIndex{1,v}==pk.priorKnowledge(p).G_linewidth && strcmp(optimIndex{2,v},'linewidth'))
                
                if isfield(pk.priorKnowledge(p),'base_linewidth') && ~isempty(pk.priorKnowledge(p).base_linewidth)
                    % LP: If we know the T2, then ADD this intrinsic linewidth to that being fitted.
                    linewidth_fun{p+m_count} = {'@(x,a,b)x(a)+b;',v,pk.priorKnowledge(p).base_linewidth};
                else
                    % Normal mode
                    linewidth_fun{p+m_count} = {'@(x,a)x(a);',v};

                end
                
            elseif (isempty(pk.priorKnowledge(p).G_amplitude) && optimIndex{1,v}==p && strcmp(optimIndex{2,v},'amplitude')) || ...
                    (~isempty(pk.priorKnowledge(p).G_amplitude) && optimIndex{1,v}==pk.priorKnowledge(p).G_amplitude && strcmp(optimIndex{2,v},'amplitude'))
                amplitude_fun{p+m_count} = {'@(x,a)x(a);',v};
            elseif (isempty(pk.priorKnowledge(p).G_phase) && optimIndex{1,v}==p && strcmp(optimIndex{2,v},'phase')) || ...
                    (~isempty(pk.priorKnowledge(p).G_phase) && optimIndex{1,v}==pk.priorKnowledge(p).G_phase && strcmp(optimIndex{2,v},'phase'))
                
                if isfield(pk.priorKnowledge(p),'RelPhase') && ~isempty(pk.priorKnowledge(p).RelPhase)
                    %WTC: To enable relative phase shifts.
                    phase_fun{p+m_count} = {'@(x,a,b)x(a)+b;',v,pk.priorKnowledge(p).RelPhase};
                else
                    % Normal mode
                    phase_fun{p+m_count} = {'@(x,a)x(a);',v};

                end
                
            end
            
            
        end
    elseif ~isempty(pk.priorKnowledge(p).multiplet)
        for m = 1:numel(pk.priorKnowledge(p).multiplet)
            if m~=1
                m_count = m_count + 1;
            end
            if isempty(pk.bounds(p).chemShift) && ~isempty(pk.initialValues(p).chemShift)
                chemShift_fun{p+m_count} = {'@(a)a;',pk.initialValues(p).chemShift};
%                 cs(p+m_count) = 0;
            end
            if isempty(pk.bounds(p).linewidth) && ~isempty(pk.initialValues(p).linewidth)
                linewidth_fun{p+m_count} = {'@(a)a;',pk.initialValues(p).linewidth};
%                 lw(p+m_count) = 0;
            end
            if isempty(pk.bounds(p).amplitude) && ~isempty(pk.initialValues(p).amplitude)
                amplitude_fun{p+m_count} = {'@(a)a;',pk.initialValues(p).amplitude};
%                 am(p+m_count) = 0;
            end
            if isempty(pk.bounds(p).phase) && ~isempty(pk.initialValues(p).phase)
                phase_fun{p+m_count} = {'@(a)a;',pk.initialValues(p).phase};
%                 ph(p+m_count) = 0;
            end
                for v = 1:nv
                    if optimIndex{1,v}==p && strcmp(optimIndex{2,v},'chemShift')
                        if ~isempty(pk.priorKnowledge(p).chemShiftDelta) && isempty(pk.bounds(p).chemShiftDelta)
                        csd = pk.priorKnowledge(p).chemShiftDelta;    
                        chemShift_fun{p+m_count} = {'@(x,a,b)x(a)+b;',v,(m-1)*csd};
                        else
                            for f = 1:nv
                                if (isempty(pk.priorKnowledge(p).G_chemShiftDelta) && optimIndex{1,f}==p && strcmp(optimIndex{2,f},'chemShiftDelta')) || ...
                                    (~isempty(pk.priorKnowledge(p).G_chemShiftDelta) && optimIndex{1,f}==pk.priorKnowledge(p).G_chemShiftDelta && strcmp(optimIndex{2,f},'chemShiftDelta'))
                                    chemShift_fun{p+m_count} = {'@(x,a,b,c)x(a)+b*x(c);',v,(m-1),f};
                                end
                            end
                        end
                     
       
            
                    elseif (isempty(pk.priorKnowledge(p).G_linewidth) && optimIndex{1,v}==p && strcmp(optimIndex{2,v},'linewidth')) || ...
                            (~isempty(pk.priorKnowledge(p).G_linewidth) && optimIndex{1,v}==pk.priorKnowledge(p).G_linewidth && strcmp(optimIndex{2,v},'linewidth'))
                       
                        if isfield(pk.priorKnowledge(p),'base_linewidth') && ~isempty(pk.priorKnowledge(p).base_linewidth)
                             % LP: If we know the T2, then ADD this intrinsic linewidth to that being fitted.
                            linewidth_fun{p+m_count} = {'@(x,a,b)x(a)+b;',v,pk.priorKnowledge(p).base_linewidth};
                            
                        else
                            % Normal mode
                            linewidth_fun{p+m_count} = {'@(x,a)x(a);',v};
                        end
                        
                    elseif (isempty(pk.priorKnowledge(p).G_amplitude) && optimIndex{1,v}==p && strcmp(optimIndex{2,v},'amplitude')) || ...
                            (~isempty(pk.priorKnowledge(p).G_amplitude) && optimIndex{1,v}==pk.priorKnowledge(p).G_amplitude && strcmp(optimIndex{2,v},'amplitude'))
                        if pk.priorKnowledge(p).multiplet(m) ~= 0
                            if ~isempty(pk.priorKnowledge(p).amplitudeRatio) && isempty(pk.bounds(p).amplitudeRatio)
                                ar = pk.priorKnowledge(p).amplitudeRatio;
                                amplitude_fun{p+m_count} = {'@(x,a,b)x(a)*b;',v,ar};
                            else
                                for f = 1:nv
                                    if optimIndex{1,f}==p && strcmp(optimIndex{2,f},'amplitudeRatio')
                                        amplitude_fun{p+m_count} = {'@(x,a,b)x(a)*x(b);',f,v};
                                    end
                                end
                            end
                        else
                            amplitude_fun{p+m_count} = {'@(x,a)x(a);',v};
                        end
                    elseif (isempty(pk.priorKnowledge(p).G_phase) && optimIndex{1,v}==p && strcmp(optimIndex{2,v},'phase')) || ...
                            (~isempty(pk.priorKnowledge(p).G_phase) && optimIndex{1,v}==pk.priorKnowledge(p).G_phase && strcmp(optimIndex{2,v},'phase'))
                        
                        if isfield(pk.priorKnowledge(p),'RelPhase') && ~isempty(pk.priorKnowledge(p).RelPhase)
                            %WTC: To enable relative phase shifts.
                            phase_fun{p+m_count} = {'@(x,a,b)x(a)+b;',v,pk.priorKnowledge(p).RelPhase};
                        else
                            % Normal mode
                            phase_fun{p+m_count} = {'@(x,a)x(a);',v};

                        end
                    end
                end
            
        end
    end
end

constraintsCellArray.chemShift_fun = chemShift_fun;
constraintsCellArray.linewidth_fun = linewidth_fun;
 constraintsCellArray.amplitude_fun = amplitude_fun;
constraintsCellArray.phase_fun = phase_fun;
