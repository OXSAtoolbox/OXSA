function out = shiftCsiMatrix(in,phX,phY,phZ)
% Shift CSI matrix

%% Convert back into k-space
kspace=conj(in);
kspace=ifftshift(ifft(ifftshift(kspace,2),[],2),2);
kspace=ifftshift(ifft(ifftshift(kspace,3),[],3),3);
kspace=ifftshift(ifft(ifftshift(kspace,4),[],4),4);

%% Apply phase shift
size_in = size(in);
size_in((end+1):4) = 1; % Pad 1D and 2D data with size = 1.

% X
ph = reshape(exp(phX * 2*pi*i*((-size_in(2)/2):(size_in(2)/2-1))/size_in(2)),[1 size_in(2) 1 1]);
kspace = bsxfun(@times,kspace,ph);

% Y
ph = reshape(exp(phY * 2*pi*i*((-size_in(3)/2):(size_in(3)/2)-1)/size_in(3)),[1 1 size_in(3) 1]);
kspace = bsxfun(@times,kspace,ph);

% Z
ph = reshape(exp(phZ * 2*pi*i*((-size_in(4)/2):(size_in(4)/2)-1)/size_in(4)),[1 1 1 size_in(4)]);
kspace = bsxfun(@times,kspace,ph);

%% Convert to image space
out = fftshift(fft(fftshift(kspace,2),[],2),2);
out = fftshift(fft(fftshift(out,3),[],3),3);
out = fftshift(fft(fftshift(out,4),[],4),4);
out = conj(out);
