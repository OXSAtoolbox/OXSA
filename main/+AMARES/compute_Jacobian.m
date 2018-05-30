function Jacobian = compute_Jacobian(modelFids, imagingFrequency, tTrue, modelParams)
%Calculates the Jacobian for the fitting model
%N.B. This does not include the P matrix
%Lucian A. B. Purvis 2017

% Derivatives are all of the form f(x) * ...
%
% See ComputeJacobianElements.nb for derivation.

amplitude = modelParams.amplitude;
sigma = modelParams.sigma;

% cs
cs_deriv = bsxfun(@times,modelFids, 2i.*imagingFrequency.*pi.*tTrue);
% lw
lw_deriv = bsxfun(@times,modelFids, -pi * tTrue);
% am
am_deriv = bsxfun(@times,modelFids, 1./amplitude(:).');
% ph
ph_deriv = modelFids * 1i*pi/180;
% sg
sg_deriv = bsxfun(@times,modelFids, -pi^2 .* tTrue.^2 *sigma);

% Combine into canonical ordering...
Jacobian = zeros(size(modelFids,1),5*size(cs_deriv,2));
for peakDx = 1:size(cs_deriv,2)
    Jacobian(:,(1:5)+5*(peakDx-1)) = [cs_deriv(:,peakDx) lw_deriv(:,peakDx) am_deriv(:,peakDx) ph_deriv(:,peakDx) sg_deriv(:,peakDx)];
end
