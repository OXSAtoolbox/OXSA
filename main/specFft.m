function [spec] = specFft(fid,dim)
% FFT for spectroscopy. Converts fid --> spectrum.
%
% Accounts correctly for the 0.5x weighting for the t=0 FID point arising
% from the one-sided definition of the Fourier Transform relations in
% spectroscopy.
%
% Optional parameter: dim is the dimension to be FFT'd. Default is 1.
%
% EXAMPLE:
% zz=randn(2048,1)+1i*randn(2048,1);maxdiff(zz,specFft(specInvFft(zz)))
% OR
% zz=randn(2048,128)+1i*randn(2048,128);maxdiff(zz,specFft(specInvFft(zz)));maxdiff(zz,specFft(specInvFft(zz,2),2))

if nargin<2
    dim = 1;
end

perm = [dim 1:(dim-1) (dim+1):numel(size(fid))];

% Re-use variable name "spec" to economise on RAM.
spec = permute(fid,perm);

% t=0 point is treated differently by convention for a FID
spec(1,:) = spec(1,:) * 0.5;

spec = ipermute(fftshift(fft(spec,[],1),1)/size(spec,1),perm);
