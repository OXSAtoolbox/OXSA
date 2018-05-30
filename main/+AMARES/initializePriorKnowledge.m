function [pkWithLinLsq,pkWithLinLsq_orig_phase]= initializePriorKnowledge(pk, exptParams, inputFid)
% Find initial conditions by solving the linear least squares problem for a
% lorentzian, varying amplitude and phase only. Then update the prior knowledge.

%% Change Initial Value for Additional Linewidth


for idx= 1:length(pk.initialValues)
    if isfield(pk.priorKnowledge(idx), 'base_linewidth') && ~isempty(pk.priorKnowledge(idx).base_linewidth) 
        if pk.priorKnowledge(idx).base_linewidth < 0
            %Make sure that the model does not try and fit negative
            %linewidths as the bounds do not account for additional
            %linewidth.edit 
            
        pk.bounds(idx).linewidth(1) = abs(pk.priorKnowledge(idx).base_linewidth);
        
        end
        
        if  isfield(pk.initialValues(idx), 'addlinewidth') && ~isempty(pk.initialValues(idx).addlinewidth)
        pk.initialValues(idx).linewidth = pk.initialValues(idx).addlinewidth + pk.priorKnowledge(idx).base_linewidth;
        end
        
    end
    
    if isfield(pk.priorKnowledge(idx), 'G_sigma') && ~isempty(pk.priorKnowledge(idx).G_sigma)&&...
            isfield(pk.initialValues(idx), 'sigma') && ~isempty(pk.initialValues(idx).sigma)&&...
            pk.initialValues(idx).sigma~=pk.initialValues(pk.priorKnowledge(idx).G_sigma).sigma
        
        pk.initialValues(idx).sigma = pk.initialValues(pk.priorKnowledge(idx).G_sigma).sigma;
        
    end
end

%% Linear fit

[~, FIDmatrix] = AMARES.makeInitialValuesModelFid(pk, exptParams, 'fixAmpPhase', true, 'sumMultiplets', true);

linearFit = FIDmatrix \ inputFid;


%% Amend the supplied prior knowledge based on the linear least squares result
pkWithLinLsq = pk;
clear pk

% Check for phase locked peaks
phaseGroups = unique([pkWithLinLsq.priorKnowledge.G_phase]);
% This loop created a matrix #peaks x #groups and identifies which peaks
% are in which group.

isPhaseGrouped = false(numel(pkWithLinLsq.priorKnowledge), numel(phaseGroups));

for iDx=1:numel(pkWithLinLsq.priorKnowledge)
    for jDx = 1:numel(phaseGroups)
        if pkWithLinLsq.priorKnowledge(iDx).G_phase == phaseGroups(jDx)
            isPhaseGrouped(iDx,jDx) = true;
        else
            isPhaseGrouped(iDx,jDx) = false;
        end
    end
end

pkWithLinLsq_orig_phase = cell(1,numel(pkWithLinLsq.initialValues));

for idx=1:numel(pkWithLinLsq.initialValues)
    % AMPLITUDE
    if isempty(pkWithLinLsq.bounds(idx).amplitude) % i.e. constrained
        
    elseif min(pkWithLinLsq.bounds(idx).amplitude) <= abs(linearFit(idx)) && abs(linearFit(idx)) <= max(pkWithLinLsq.bounds(idx).amplitude) % Within the range
        pkWithLinLsq.initialValues(idx).amplitude =  abs(linearFit(idx));
        
    elseif min(pkWithLinLsq.bounds(idx).amplitude) > abs(linearFit(idx)) % Lower than lower bound
        pkWithLinLsq.initialValues(idx).amplitude = min(pkWithLinLsq.bounds(idx).amplitude);
        
    elseif abs(linearFit(idx)) > max(pkWithLinLsq.bounds(idx).amplitude) % Higher than higher bound
        pkWithLinLsq.initialValues(idx).amplitude = max(pkWithLinLsq.bounds(idx).amplitude);
    end
    
    %PHASE
    if isvector(pkWithLinLsq.bounds(idx).phase) && AMARES.range(pkWithLinLsq.bounds(idx).phase) >= 360 %% i.e. is unconstrained
        
        if exist('isPhaseGrouped','var') && any(isPhaseGrouped(idx,:))
            columnToUse = find(isPhaseGrouped(idx,:)); % identify which column has the list of peaks to average over
            pkWithLinLsq.initialValues(idx).phase =  mod(angle(mean(linearFit(isPhaseGrouped(:,columnToUse))))* 180/pi, 360); %Take weighted average.
        else
            pkWithLinLsq.initialValues(idx).phase = mod(angle(linearFit(idx)) * 180/pi, 360);
        end
        
    elseif isvector(pkWithLinLsq.bounds(idx).phase) && AMARES.range(pkWithLinLsq.bounds(idx).phase) < 360 % Not fixed but constrained to cetain values
        
        if exist('isPhaseGrouped','var') && any(isPhaseGrouped(idx,:))
            columnToUse = find(isPhaseGrouped(idx,:)); % identify which column has the list of peaks to average over
            tmpPhase =  mod(mean(angle(linearFit(isPhaseGrouped(:,columnToUse))).*abs(linearFit(isPhaseGrouped(:,columnToUse))))* 180/pi, 360);%Take weighted average.
        else
            tmpPhase = mod(angle(linearFit(idx)) * 180/pi, 360);
        end
        
        if min(pkWithLinLsq.bounds(idx).phase) <= tmpPhase && tmpPhase <= max(pkWithLinLsq.bounds(idx).phase) % Within the range
            pkWithLinLsq.initialValues(idx).phase = tmpPhase;
        elseif min(pkWithLinLsq.bounds(idx).phase) > tmpPhase % Lower than lower bound
            pkWithLinLsq.initialValues(idx).phase = min(pkWithLinLsq.bounds(idx).phase);
        elseif tmpPhase > max(pkWithLinLsq.bounds(idx).phase) % Higher than upper bound
            pkWithLinLsq.initialValues(idx).phase = max(pkWithLinLsq.bounds(idx).phase);
        end
    end
    
    % Rewrite any 0 360 phase bounds to -Inf +Inf. Otherwise, there's a
    % real risk of getting "stuck" at e.g. +0deg for a spectrum with
    % optimal phase of -10deg, or similar around the 360deg limit because
    % lsqcurvefit doesn't know that the parameter space wraps around.
    pkWithLinLsq_orig_phase{idx} = [];
    if diff(pkWithLinLsq.bounds(idx).phase) >= 360 - 1e-10 % An epsilon
        pkWithLinLsq_orig_phase{idx} = pkWithLinLsq.bounds(idx).phase; % Store original bounds to cast solution into the desired range at end.
        pkWithLinLsq.bounds(idx).phase = [-Inf +Inf];
    end
end

