function [newSpectra] = phaseCorrect(ppmaxis, spectra, options)
% phaseCorrect: Zero and first-order phase correction on an MR spectrum
%
% [newSpectra] = phaseCorrect(ppmaxis, spectra, options)
%
% ppmaxis - chemical shift for each spectral point (N element vector)
% spectra - matrix of spectra to be rephased
%           chemical shift is the FIRST dimension (i.e. N x m matrix)
% options - structure containing the following phase parameters:
%   zeroOrder - zero order phase in radians
%   firstOrder - phase in radians per ppm
%   firstOrderCentre - ppm value that is left unaltered by first order
%                      phase correction

% Copyright Chris Rodgers, University of Oxford, 2008.
% $Id: phaseCorrect.m 3402 2010-06-22 15:48:24Z crodgers $

%% Check input arguments
narginchk(3, 3)

sizeSpectra = size(spectra);

if numel(ppmaxis)~=sizeSpectra(1)
	error('Dimensions of ppmaxis and spectra are inconsistent')
end

%% Extract options fields
if ~isfield(options,'zeroOrder')
    options.zeroOrder = 0;
end

if ~isfield(options,'firstOrder')
    options.firstOrder = 0;
end

if ~isfield(options,'firstOrderCentre')
    options.firstOrderCentre = 0;
end

%% Rephase spectra
zeroOrderPhase = exp(i*options.zeroOrder);
firstOrderPhase = exp((ppmaxis(:) - options.firstOrderCentre)*i*options.firstOrder);

% This vectorised operation takes more memory than a loop, but is probably
% quicker except for very large numbers of spectra
newSpectra=(spectra*zeroOrderPhase).*repmat(firstOrderPhase,[1,sizeSpectra(2:end)]);
