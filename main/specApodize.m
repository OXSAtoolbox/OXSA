function [outSpec] = specApodize(timevals,spec,amount)
% Apodize spectra.
%
% [outSpec] = specApodize(timevals,spec,amount)

% Check dimensions

% Prepare the window function
outSpec = bsxfun(@(oneSpec,windowFunc) specFft(specInvFft(oneSpec).*windowFunc),spec,exp(-amount*timevals));
