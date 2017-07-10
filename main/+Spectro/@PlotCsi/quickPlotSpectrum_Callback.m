function quickPlotSpectrum_Callback(obj,hObject,eventdata) %#ok<INUSD>
% Callback that plots the current voxel spectrum in a new window

% Copyright Chris Rodgers, University of Oxford, 2010-11.
% $Id: quickPlotSpectrum_Callback.m 4322 2011-06-20 13:09:57Z crodgers $

% if stored.csiInterpolated
% phasedSpectrum = stored.misc.data.spectra{1}(:,stored.voxel) * ...
%     conj(stored.misc.data.signals{1}(1,stored.voxel)) / ...
%     abs(stored.misc.data.signals{1}(1,stored.voxel));
% else
% phasedSpectrum = stored.misc.spectraDeinterp{1}(:,stored.voxel);
% % * ...
% %     conj(stored.misc.data.signals{1}(1,stored.voxel)) / ...
% %     abs(stored.misc.data.signals{1}(1,stored.voxel));
% end

zeroFidPt = sum(obj.data.spec.spectra{1}(:,obj.voxel),1);

phasedSpectrum = obj.data.spec.spectra{1}(:,obj.voxel) * ...
    conj(zeroFidPt) / ...
    abs(zeroFidPt);

hFig = figure();
clf
% plot(stored.misc.data.ppmaxis{1},abs(stored.misc.data.spectra{1}(:,stored.voxel)));

% subplot(2,1,1)
% plot(stored.misc.data.ppmaxis{1},real(phasedSpectrum));
% set(gca,'xdir','rev')
% 
% subplot(2,1,2)
% plot(stored.misc.data.ppmaxis{1},imag(phasedSpectrum));
% set(gca,'xdir','rev')

plotMrSpectra(obj.data.spec.ppmAxis,phasedSpectrum)

set(hFig,'name',sprintf('Quick plot of coil #1 for voxel #%d',obj.voxel))
