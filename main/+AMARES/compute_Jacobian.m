function [Jacobian] = compute_Jacobian(optimVar,func,beginTime,dwellTime,imagingFrequency,nPoints)
% Compute Jacobian matrix with real/imag parts split out.

[chemShift, linewidth, amplitude, phase] = AMARES.applyModelConstraints(optimVar, func);

% TODO: g is a variable parameter. Don't hard-code it to zero!
% TODO: Use AMARES.linewidthToDamping() to pass in a damping parameter to
%       makeSyntheticData instead of a linewidth?

% Cut-and-paste in from makeSyntheticData
bandwidth = 1/dwellTime;
damping = linewidth * pi;

peakAmplitudesWithPhase = amplitude.*exp(1i*phase*pi/180);

tTrue = ((0:(nPoints-1)).'/(bandwidth)) + beginTime; % In seconds

% Lorentzian peak at chemShift ppm
modelFids = bsxfun(@times,exp(tTrue(:) * (-damping(:) + 1i*2*pi*chemShift(:)*imagingFrequency).'),peakAmplitudesWithPhase(:).');


% Derivatives are all of the form f(x) * ...
%
% See ComputeJacobianElements.nb for derivation.

% cs
cs_deriv = bsxfun(@times,modelFids, 2i.*imagingFrequency.*pi.*tTrue);
% lw
lw_deriv = bsxfun(@times,modelFids, -pi * tTrue);
% am
am_deriv = bsxfun(@times,modelFids, 1./amplitude(:).');
% ph
ph_deriv = modelFids * 1i*pi/180;

% Combine into canonical ordering...
Jacobian = zeros(nPoints,4*numel(peakAmplitudesWithPhase));
for peakDx = 1:numel(peakAmplitudesWithPhase)
    Jacobian(:,(1:4)+4*(peakDx-1)) = [cs_deriv(:,peakDx) lw_deriv(:,peakDx) am_deriv(:,peakDx) ph_deriv(:,peakDx)];
end

P = AMARES.compute_P_Matrix(optimVar,func);
Jacobian = Jacobian * P;
