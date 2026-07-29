function [modelSpec, modelSpecs, modelFid, modelFids] = makeModelSpec(fitStatus, options)
% Construct the fid and spec data, with optional phasing and apodization
%
% [modelSpec, modelSpecs, modelFid, modelFids] = makeModelSpec(fitStatus, options);
%
% EXAMPLE:
% [modelSpec, modelSpecs, modelFid, modelFids] = AMARES.makeModelSpec(fitStatus, options);

%% Required inputs
exptParams = fitStatus.exptParams;
xFit = fitStatus.xFit;
constraintsCellArray = fitStatus.constraintsCellArray;

%% Defaults
if ~isfield(options,'apodization')
    options.apodization = 0;
end
if isfield(options,'firstOrder') && ~options.firstOrder
    firstOrderCorrection = 1;
end

%% Apply prior knowledge to yield full solution
fitResults = AMARES.applyModelConstraints(xFit,constraintsCellArray);

%% Calculate the zero and first order phase correction
if ~isfield(options,'firstOrder') || options.firstOrder % On by default
    if ~isfield(exptParams,'freqAxis')
        exptParams.freqAxis = exptParams.ppmAxis*exptParams.imagingFrequency;
    end
    
    % Set zero-order phase relative to the reference peak
    actualRefPeak = AMARES.getActualRefPeakDx(fitStatus.pkWithLinLsq);
    if ~isempty(actualRefPeak)
        zeroOrderPhaseRad = fitResults.phase(actualRefPeak) * pi / 180;
    else
        zeroOrderPhaseRad = 0;
    end
    
    if ~isfield(options,'quiet') || ~options.quiet
        fprintf('zeroOrderPhaseRad = %.3f\n',zeroOrderPhaseRad)
    end
    
    % N.B. Careful... freqAxis here MUST NOT contain any frequency offset.
    % It must be centred at the actual acquisition centre frequency.
    firstOrderCorrection = exp(-1i * (zeroOrderPhaseRad + 2* pi * exptParams.freqAxis * exptParams.beginTime));
end

%% Calculate the fitted spectra
timeAxis = exptParams.dwellTime*(0:exptParams.samples-1).';

[modelFid,~,modelFids] = AMARES.makeModelFidAndJacobianReIm(xFit,constraintsCellArray,exptParams.beginTime,exptParams.dwellTime,exptParams.imagingFrequency,exptParams.samples, 'complexOutput', true);

modelSpec =  specApodize(timeAxis, specFft(modelFid).*firstOrderCorrection,options.apodization);
modelSpecs =  specApodize(timeAxis, specFft(modelFids).*firstOrderCorrection,options.apodization);

modelFid = specInvFft(modelSpec);
modelFids = specInvFft(modelSpecs);