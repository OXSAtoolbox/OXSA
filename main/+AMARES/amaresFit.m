function [fitResults, fitStatus, figureHandle, CRBResults] = amaresFit(inputFid, exptParams, pk, plotOn, varargin)
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

%% find initial conditions by solving the linear least squares problem for amplitude and phase only and update prior knowledge

[pkWithLinLsq,pkWithLinLsq_orig_phase]= AMARES.initializePriorKnowledge(pk, exptParams, inputFid);
clear pk

%% set initial values, prior knowledge and lower/upper pkWithLinLsq.bounds
[xInit, xLBounds, xUBounds, optimIndex] = AMARES.initializeOptimization(pkWithLinLsq);

%% create cell arrays of constraints for the makeModelFid function
constraintsCellArray = AMARES.createModelConstraints(pkWithLinLsq, optimIndex);

%% multi-peak fitting
cplx2real = @(in) [real(in)  imag(in)];

%% New method. Analytical Jacobian.
fitOpt = optimset();

if isfield(options,'MaxFunEvals')
    fitOpt.MaxFunEvals =  options.MaxFunEvals;
else
    fitOpt.MaxFunEvals = 500;
end

if isfield(options,'TolFun')
    fitOpt.TolFun = options.TolFun;
else
    fitOpt.TolFun = 1E-006 * sqrt(amp0);
end

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

fitStatus.residual = -complex(residualSplit(1:exptParams.samples),residualSplit(exptParams.samples+1:end));
dataNormSq = norm(inputFid-mean(inputFid)).^2;
fitStatus.relativeNorm = resNormSq/dataNormSq;
fitStatus.resNormSq = resNormSq;

if ~isfield(options,'quiet') || ~options.quiet
    fprintf('Iterations = %d.\nNorm of residual = %0.3f\nNorm of the data = %0.3f\nresNormSq / dataNormSq = %0.3f\n',fitStatus.OUTPUT.iterations,resNormSq,dataNormSq,fitStatus.relativeNorm)
end

%% Finally calculate the fitted values and the CRBs.
fitResults = AMARES.applyModelConstraints(xFit,constraintsCellArray);

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

% The noise variance should be the variance of the real or imaginary parts
% of the residual not the variance of the whole complex data.
% var(residual) = sqrt(2) * var(real(residual)) = sqrt(2) * var(imag(residual)).
% This is explained on page 312 of Cavasilla et al, in the text between
% eqns 2 and 3:
%"where sigma_r and sigma_i are, respectively, the standard deviations of the
% real and imaginary parts of the noise. In NMR, generally a
% quadrature lock-in detection provides the real and imaginary
% parts of the signal which do not modify the characteristics of
% the noise distribution. Consequently, we can assume that sigma_r =
% sigma_i = sigma. The joint probability function P of the measurement
% x 5 ( x0, x1, . . . , xN21) T (the superscript T denotes the
% transposition), the so-called likelihood function, equals the
% product of the probability functions of all samples:"

if isfield(options,'noiseVariance')
    noise_var = options.noiseVariance;
else
    noise_var = var(real(fitStatus.residual));
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
