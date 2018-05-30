function [modelFid, modelFids] = makeModelFid(modelParams, t, imagingFrequency)
%Called in makeSyntheticData and makeModelFidJacobianReIm
% Lucian A. B. Purvis 2017

chemShift = modelParams.chemShift;
linewidth = modelParams.linewidth;
amplitude = modelParams.amplitude;
phase = modelParams.phase;

if isfield(modelParams, 'sigma')
    sigma = modelParams.sigma;
else
    sigma = zeros(size(linewidth));
end
%%
peakAmplitudesWithPhase = amplitude.*exp(1i*phase*pi/180);

lorentzian = exp( -abs(t(:))*linewidth(:).' * pi);
gaussian = exp(-2*pi^2*t(:).^2*(sigma(:).').^2);

lineshape = lorentzian.*gaussian;

% This exponential shifts the peak to chemShift ppm when multiplied by
% the FID
chemShiftFid = exp(t(:) * 1i*2*pi*chemShift(:).'*imagingFrequency.');

modelFids = bsxfun(@times,lineshape .* chemShiftFid,peakAmplitudesWithPhase(:).');
modelFid = sum(modelFids,2);