function [fitResults fitStatus figureHandle CRBResults] = amaresFit(inputFid, exptParams, pk, plotOn, varargin)
% Main AMARES fitting routine.
%
% Input:
%
% inputFid: double precision array comprising the FIDs to be fitted.
%           (Use "specInvFft(spectrum)" if the data to be fitted is
%           frequency domain.)
%
% exptParams: experimental parameters (Spectro.Spec object OR a struct with
%             the following fields).
%
% exptParams.samples 
% exptParams.imagingFrequency / MHz
% exptParams.timeAxis / s
% exptParams.dwellTime / s
% exptParams.ppmAxis / ppm
%
% exptParams.beginTime / s % TODO: This is a model parameter and should be possible to fit!
%
% pk.initialValues, pk.priorKnowledge and pk.bounds describe the fitting model.
%
% Options:
%
% 'quiet' - suppress output if true.
% 
% Output:
% fitResults is a structure containing the fitted parameters.
%
% fitStatus is a structure containing other information regarding the
% best-fit solution.
%
% figureHandle contains the handle of the fit results plot (or [] if
% fitting was run without plotting the results).
%
% CRBResults is a structure containing the error estimates of the fitted
% parameters.
%
% TODO:
%
% Make "plotOn" a name/value option.

%% Process options
options = processVarargin(varargin{:});

if ~isfield(options,'firstOrder')
    options.firstOrder = 1;
end

%% Input validation
if ~isa(inputFid,'double')
    error('inputFid must be a double-precision array.')
end

%% Perform auto-scaling of tolerances
%http://www.mathworks.com/matlabcentral/newsreader/view_thread/46882#119089
amp0 = max(abs(double(inputFid)));

%% find initial conditions by solving the linear least squares problem for amplitude and phase only
FIDmatrix = zeros(exptParams.samples,length(pk.initialValues)); % TODO: This should generate each component of a multiplet!!
for idx=1:length(pk.initialValues)
    if isfield(pk.priorKnowledge(idx), 'base_linewidth') && ~isempty(pk.priorKnowledge(idx).base_linewidth) &&...
        isfield(pk.initialValues(idx), 'addlinewidth') && ~isempty(pk.initialValues(idx).addlinewidth)
       
    initial_chemShift = pk.initialValues(idx).chemShift;
    initial_linewidth = pk.initialValues(idx).addlinewidth+ pk.priorKnowledge(idx).base_linewidth;
    else    
    initial_chemShift = pk.initialValues(idx).chemShift;
    initial_linewidth = pk.initialValues(idx).linewidth;
    
    end
    if isempty(pk.priorKnowledge(idx).multiplet)
        % Normal singlet peak
        initialmodelFid = makeSyntheticData('coilAmplitudes',1,'noiseLevels',0,'bandwidth',1/exptParams.dwellTime,'imagingFrequency',exptParams.imagingFrequency,...
            'nPoints',exptParams.samples,'linewidth',initial_linewidth,'g',zeros(1,numel(pk.initialValues)),...
            'chemicalShift',initial_chemShift,'peakAmplitudes',ones(1,numel(pk.initialValues)),...
            'beginTime',exptParams.beginTime);
    else
        % Multiplet
        %
        % See AMARES.createModelConstraints for details of the
        % chemShiftDelta and amplitudeRatio properties.
        %
        % N.B. I am not sure how this will interact with model constraints
        % on amplitudes. This initial linear least squares fit ought to
        % respect the model constraints / prior knowledge...
        
        multipletAmps = ones(size(pk.priorKnowledge(idx).multiplet));
        multipletAmps(pk.priorKnowledge(idx).multiplet ~= 0) = pk.priorKnowledge(idx).amplitudeRatio;
        
        multipletCS = initial_chemShift + (0:numel(pk.priorKnowledge(idx).multiplet)-1)*pk.priorKnowledge(idx).chemShiftDelta;
        
        initialmodelFid = makeSyntheticData('coilAmplitudes',1,'noiseLevels',0,'bandwidth',1/exptParams.dwellTime,'imagingFrequency',exptParams.imagingFrequency,...
            'nPoints',exptParams.samples,'linewidth',repmat(initial_linewidth,size(pk.priorKnowledge(idx).multiplet)),'g',zeros(1,numel(pk.priorKnowledge(idx).multiplet)),...
            'chemicalShift',multipletCS,'peakAmplitudes',multipletAmps,...
            'beginTime',exptParams.beginTime);
        
    end

    FIDmatrix(:,idx) = initialmodelFid.perfectFid;
end

linearFit = FIDmatrix \ inputFid;
%% Change Initial Value for Additional Linewidth

for idx= 1:length(pk.initialValues)
    if isfield(pk.priorKnowledge(idx), 'base_linewidth') && ~isempty(pk.priorKnowledge(idx).base_linewidth) &&...
        isfield(pk.initialValues(idx), 'addlinewidth') && ~isempty(pk.initialValues(idx).addlinewidth)
        pk.initialValues(idx).linewidth = pk.initialValues(idx).addlinewidth;
    end
end

%% Amend the supplied prior knowledge based on the linear least squares result
pkWithLinLsq = pk;
clear pk

% Check for phase locked peaks 
phaseGroups = unique([pkWithLinLsq.priorKnowledge.G_phase]);
% This loop created a matrix #peaks x #groups and identifies which peaks
% are in which group.
for iDx=1:numel(pkWithLinLsq.priorKnowledge)
    for jDx = 1:numel(phaseGroups)
        if pkWithLinLsq.priorKnowledge(iDx).G_phase == phaseGroups(jDx);
            isPhaseGrouped(iDx,jDx) = true;
        else
            isPhaseGrouped(iDx,jDx) = false;
        end
    end
end

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

%% set initial values, prior knowledge and lower/upper pkWithLinLsq.bounds
[xInit, xLBounds, xUBounds, optimIndex] = AMARES.initializeOptimization(pkWithLinLsq);

%% create cell arrays of constraints for the makeModelFid function
[constraintsCellArray] = AMARES.createModelConstraints(pkWithLinLsq, optimIndex);

%% multi-peak fitting
cplx2real = @(in) [real(in)  imag(in)];
% real2cplx = @(in) complex(in(:,1:size(in,2)/2),in(:,size(in,2)/2+1:end));
% modelFID2 = @(x,xdata) cplx2real(AMARES.makeModelFid(x,constraintsCellArray,exptParams.beginTime,exptParams.dwellTime,exptParams.imagingFrequency,exptParams.samples));

%% Old method. Finite differences for Jacobian.
% fitOpt = optimset();
% fitOpt.TolFun = 1E-006;
% fitOpt.MaxFunEvals = 2000;
% [xFit,resNormSq,residualSplit,fitStatus.EXITFLAG,fitStatus.OUTPUT,fitStatus.LAMBDA,fitStatus.JACOB] ...
%     = lsqcurvefit(modelFID2, xInit, exptParams.timeAxis, cplx2real(inputFid), xLBounds, xUBounds, fitOpt);
% % Check Jacobian to validate...
% jj2=AMARES.compute_Jacobian(xFit,constraintsCellArray,exptParams.beginTime,exptParams.dwellTime,exptParams.imagingFrequency,exptParams.samples);
% maxdiff(full(fitStatus.JACOB),full(jj2),'Jacobian test',1e-5)

%% New method. Analytical Jacobian.
fitOpt = optimset();
fitOpt.TolFun = 1E-006 * sqrt(amp0);
fitOpt.MaxFunEvals = 500;
if isfield(options,'MaxIter')
    fitOpt.MaxIter = options.MaxIter;
else
    fitOpt.MaxIter = 100;
end
fitOpt.Jacobian = 'on';
fitOpt.PrecondBandWidth = 0;
fitOpt.Display = 'none';
modelJAC2 = @(x,xdata) AMARES.makeModelFidAndJacobianReIm(x,constraintsCellArray,exptParams.beginTime,exptParams.dwellTime,exptParams.imagingFrequency,exptParams.samples);
[xFit,resNormSq,residualSplit,fitStatus.EXITFLAG,fitStatus.OUTPUT] ...
    = lsqcurvefit(modelJAC2, xInit, exptParams.timeAxis, cplx2real(inputFid.').', xLBounds, xUBounds, fitOpt);

fitStatus.residual = -complex(residualSplit(1:exptParams.samples),residualSplit(exptParams.samples+1:end)); % TODO: Why the minus sign??!

dataNormSq = norm(inputFid-mean(inputFid)).^2;
fitStatus.relativeNorm = resNormSq/dataNormSq;
fitStatus.resNormSq = resNormSq;
if ~isfield(options,'quiet') || ~options.quiet
    fprintf('Iterations = %d.\nNorm of residual = %0.3f\nNorm of the data = %0.3f\nresNormSq / dataNormSq = %0.3f\n',fitStatus.OUTPUT.iterations,resNormSq,dataNormSq,fitStatus.relativeNorm)
end

%% Finally calculate the fitted values and the CRBs.
[fitResults.chemShift, fitResults.linewidth, fitResults.amplitude, fitResults.phase] = AMARES.applyModelConstraints(xFit,constraintsCellArray);

% Fixup any unbounded phase parameters
multipletPeaksIdx = [];
for idx=1:numel(pkWithLinLsq.initialValues)
    if ischar(pkWithLinLsq.initialValues(idx).peakName)
        multipletPeaksIdx(end+1) = idx;
    else
        multipletPeaksIdx(end+1:end+numel(pkWithLinLsq.initialValues(idx).peakName)) = idx;
    end
end

for idx=1:numel(pkWithLinLsq.initialValues)
    if ~isempty(pkWithLinLsq_orig_phase{idx})
        pkWithLinLsq.bounds(idx).phase = pkWithLinLsq_orig_phase{idx};
        
        ph_delta = mod(fitResults.phase(multipletPeaksIdx == idx) - min(pkWithLinLsq_orig_phase{idx}),360);
        fitResults.phase(multipletPeaksIdx == idx) = ph_delta + min(pkWithLinLsq_orig_phase{idx});
    end
end

if isfield(options,'noiseVarience')
    noise_var = options.noiseVariance;
else
    noise_var = var(fitStatus.residual);
end

if nargout == 4
    CRBResults = AMARES.estimateCRB(exptParams.imagingFrequency, exptParams.dwellTime, exptParams.beginTime, noise_var, xFit, constraintsCellArray);
else
    disp('CRBs not calculated, add optional 4th output argument to call to calculate.')
end

%% Store data to re-run CRB calculation later and to plot fit
fitStatus.exptParams = exptParams;
fitStatus.noise_var = noise_var;
fitStatus.xFit = xFit;
fitStatus.constraintsCellArray = constraintsCellArray;
fitStatus.inputFid = inputFid;
fitStatus.pkWithLinLsq = pkWithLinLsq;
fitStatus.options = options;

%% Create spectra to be plotted and call plot code
% plotOn syntax:
% true - plot and automatically pick figure number
% false - don't plot
% double - plot into the specified figure handle

figureHandle = [];
if plotOn % Optionally suppress the figure if we are fitting multiple voxels to save a fair bit of time.
    if islogical(plotOn)
        figureHandle = figure();
    else
        figureHandle = plotOn;
    end
    
%     AMARES.amaresPlot(exptParams,inputFid,xFit,constraintsCellArray,'Individual',true,'Residual',fitStatus.residual,'pk',pkWithLinLsq,'Apodization',30,'xUnits','PPM','hFig',figureHandle,'firstOrder',true,'noise_var',fitStatus.noise_var);
    
    if isfield(options,'apodization')
        if ischar(options.apodization)
            peakIndex = strcmp({pkWithLinLsq.bounds.peakName},options.apodization);
            apodizeValue = fitResults.phase(peakIndex);
        elseif isnumeric(options.apodization)
            apodizeValue = options.apodization;
        end        
        AMARES.amaresPlot(fitStatus,'hFig',figureHandle,options);
    else
        AMARES.amaresPlot(fitStatus,'hFig',figureHandle,options);
    end


end
