function quickPlotFid_Callback(obj,hObject,eventdata) %#ok<INUSD>
% Callback that plots the current voxel spectrum in a new window

% Copyright Chris Rodgers, University of Oxford, 2010.
% $Id: quickPlotFid_Callback.m 4322 2011-06-20 13:09:57Z crodgers $

% phasedSpectrum = stored.misc.data.spectra{1}(:,stored.voxel) * ...
%     conj(stored.misc.data.signals{1}(1,stored.voxel)) / ...
%     abs(stored.misc.data.signals{1}(1,stored.voxel));
% 
% hFig = figure();
% clf
% % plot(stored.misc.data.ppmaxis{1},abs(stored.misc.data.spectra{1}(:,stored.voxel)));
% subplot(2,1,1)
% plot(stored.misc.data.ppmaxis{1},real(phasedSpectrum));
% set(gca,'xdir','rev')
% xlim([0 17])
% ylim([-0.4 0.4])
% 
% subplot(2,1,2)
% plot(stored.misc.data.ppmaxis{1},imag(phasedSpectrum));
% set(gca,'xdir','rev')
% xlim([0 17])
% ylim([-0.4 0.4])

if ~obj.csiInterpolated
    error('Time-domain data are not currently de-interpolated.')
end

% Temporarily plot in time domain
phasedSpectrum = obj.data.spec.signals{1}(:,obj.voxel); 
% * ...
%     conj(stored.misc.data.signals{1}(1,stored.voxel)) / ...
%     abs(stored.misc.data.signals{1}(1,stored.voxel));

timevals = obj.data.spec.timeAxis;

hFig = figure();
clf
% plot(stored.misc.data.ppmaxis{1},abs(stored.misc.data.spectra{1}(:,stored.voxel)));
subplot(2,1,1)
plot(timevals*1e3,real(phasedSpectrum),'r.-');
% set(gca,'xdir','rev')
xlim([0 10])
% ylim([-800 200])

subplot(2,1,2)
plot(timevals*1e3,imag(phasedSpectrum),'g.-');
% set(gca,'xdir','rev')
xlim([0 10])
% ylim([-800 200])

    

set(hFig,'name',sprintf('Quick plot of coil #1 FID for voxel #%d',obj.voxel))
