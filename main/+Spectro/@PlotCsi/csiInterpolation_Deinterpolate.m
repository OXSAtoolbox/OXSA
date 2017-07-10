function csiInterpolation_Deinterpolate(obj)
% Copyright Chris Rodgers, University of Oxford, 2010.
% All rights reserved.

%% TODO: Put these comments in the right places
disp('Converting interpolated spectra to original CSI matrix')
disp('Invert spatial FFT (image-space --> k-space)')
disp('Truncate k-space')
disp('New spatial FFT (k-space --> image-space)')

for coilDx = 1:numel(obj.data.spectra)

%% Reshape the DICOM CSI data and see how that helps
bbb = obj.data.spectra{coilDx}(:,:,:,:);
bbb=ifftshift(ifft(ifftshift(conj(bbb),2),[],2),2);
bbb=ifftshift(ifft(ifftshift(bbb,3),[],3),3);
bbb=ifftshift(ifft(ifftshift(bbb,4),[],4),4);

figure(90)
clf
for idx=1:size(bbb,2)
    subplot(4,8,idx)
    spy(squeeze(abs(bbb(1,idx,:,:))>1e-3));
    title(sprintf('idx = %d',idx))
end

% Now chop off the excess, such that the maximally sampled slice is
% middle (rounded up). E.g. 17 in a set of 32.


mask2 = true(1,obj.misc.ipolPhaseColumns);
mask2(1:(obj.misc.ipolPhaseColumns-obj.misc.rawPhaseColumns)/2)=0;
mask2((end-((obj.misc.ipolPhaseColumns-obj.misc.rawPhaseColumns)/2)+1):end)=0;

mask3 = true(1,obj.misc.ipolPhaseRows);
mask3(1:(obj.misc.ipolPhaseRows-obj.misc.rawPhaseRows)/2)=0;
mask3((end-((obj.misc.ipolPhaseRows-obj.misc.rawPhaseRows)/2)+1):end)=0;

mask4 = true(1,obj.misc.ipolPhaseZ);
mask4(1:(obj.misc.ipolPhaseZ-obj.misc.rawPhaseZ)/2)=0;
mask4((end-((obj.misc.ipolPhaseZ-obj.misc.rawPhaseZ)/2)+1):end)=0;


ccc=bbb(:,mask2,mask3,mask4);

figure(91)
clf
for idx=1:size(ccc,2)
    subplot(4,6,idx)
    spy(squeeze(abs(ccc(1,idx,:,:))>1e-3));
    title(sprintf('idx = %d',idx))
end

% Do the FFTs again (opposite order to inverse above):
ccc = fftshift(fft(fftshift(ccc,2),[],2),2);
ccc = fftshift(fft(fftshift(ccc,3),[],3),3);
ccc = fftshift(fft(fftshift(ccc,4),[],4),4);
ccc = conj(ccc);

obj.misc.spectraDeinterp{coilDx} = ccc;

end
