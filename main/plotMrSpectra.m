function [out] = plotMrSpectra(ppmaxis, spectra, varargin)
% plotMrSpectra - plot MR spectra in real/complex form with GUI
%
% plotMrSpectra(ppmaxis, spectra, options)
%
% ppmaxis - vector containing the x-axis for the spectra
% spectra - matrix containing the complex data points for the spectra
% options - struct of options:
%         * debug: display extra output from callbacks

% Copyright Chris Rodgers, University of Oxford, 2008.
% $Id: plotMrSpectra.m 7940 2014-08-08 00:02:03Z crodgers $

%% Check input arguments
error(nargchk(2, Inf, nargin, 'struct'))

% If no options argument, set a default value
options = processVarargin(varargin{:});

% Scan through options setting essential fields
optionsDefaults = {'debug', 0; 'xdir', 'rev'; 'xlabel', '\delta / ppm'; 'plotOptions',{}};
for idx=1:size(optionsDefaults,1)
    if ~isfield(options,optionsDefaults{idx,1})
        options.(optionsDefaults{idx,1}) = optionsDefaults{idx,2};
    end
end

%% Allocate guidata for this figure
hFig = gcf;
data = guidata(hFig);
if isempty(data)
    data = struct();
end

data.ppmaxis = ppmaxis;
data.spectra = spectra;
data.options = options;
data.hLines = [];

%% Plot the supplied spectra
data.hAxes(2)=subplot(2,1,2,'tag','ImagAxis');
hold on
data.hLines(:,2)=plot(ppmaxis,imag(spectra),'-',options.plotOptions{:});
set(gca,'xdir',options.xdir)
xlabel(options.xlabel)
ylabel('Im')
rainbowcolour(data.hLines(:,2))

% Plot this second so that legends / titles end up going here
data.hAxes(1)=subplot(2,1,1,'tag','RealAxis');
hold on
data.hLines(:,1)=plot(ppmaxis,real(spectra),'-',options.plotOptions{:});
set(gca,'xdir',options.xdir)
xlabel(options.xlabel)
ylabel('Re')
rainbowcolour(data.hLines(:,1))

set(data.hLines,'HitTest','off')

% Synchronise zoom on the x-axes of both plots
linkaxes(data.hAxes,'x')

%% Add GUI options for 0th order and 1st order phase correction
set(gcf,'Toolbar','figure')
tbh = findall(gcf,'Type','uitoolbar');

% Remove old buttons
% N.B. must use findall here because these handles are hidden!
delete(findall(tbh,'-regexp','Tag','^PlotMrSpectra\.'))

% % Matlab compiler script include:
% %#include PhiIcon.png
% phiIcon = double(imread(fullfile(RodgersSpectroToolsRoot,'main','PhiIcon.png')));
phiIcon = getPhiIcon();
phiIcon(phiIcon==240)=NaN;
phiIcon=phiIcon/255;
data.tth = uitoggletool(tbh,'CData',phiIcon,...
            'Separator','on',...
            'HandleVisibility','off','OnCallback',@plotMrSpectra_toolboxHelper,...
            'OffCallback',@plotMrSpectra_toolboxHelper_off,...
            'Tag','PlotMrSpectra.Toolbox');

data.phiCursor = repmat(NaN,16,16);
data.phiCursor(phiIcon(:,:,1)<0.5) = 1;

%% Store the guidata
guidata(hFig,data)

if nargout>0
    out = data;
end

%% Done
end

function phiIcon = getPhiIcon()
% Replaces:
% % Matlab compiler script include:
% %#include PhiIcon.png
% phiIcon = double(imread(fullfile(RodgersSpectroToolsRoot,'main','PhiIcon.png')));
phiIcon = zeros(16,16,3);
phiIcon(:,:,1) = [ ...
  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240
  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240
  240  240  240  240  240  210  135  240  135   89  135  195  240  240  240  240
  240  240  240  225   89    0   89  135    0    0    0   14  195  240  240  240
  240  240  240   89    0   89  225   74    0  165  165   14   14  240  240  240
  240  240  240    0   14  225  240   59    0  180  240  104    0  195  240  240
  240  240  195    0   59  240  240   59    0  180  240  120    0  135  240  240
  240  240  180    0   29  240  240   59    0  180  240  120    0  135  240  240
  240  240  240    0    0  195  240   59    0  180  240   59    0  180  240  240
  240  240  240   74    0   89  225   59    0  180  135    0   44  240  240  240
  240  240  240  210   14    0   14   29    0   29    0   14  195  240  240  240
  240  240  240  240  195   29    0    0    0    0   29  180  240  240  240  240
  240  240  240  240  240  240  180   44    0  135  240  240  240  240  240  240
  240  240  240  240  240  240  240   59    0  180  240  240  240  240  240  240
  240  240  240  240  240  240  240   59    0  180  240  240  240  240  240  240
  240  240  240  240  240  240  240  104   59  195  240  240  240  240  240  240];
phiIcon(:,:,2) = [ ...
  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240
  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240
  240  240  240  240  240  210  135  240  135   89  135  195  240  240  240  240
  240  240  240  225   89    0   89  135    0    0    0   14  195  240  240  240
  240  240  240   89    0   89  225   74    0  165  165   14   14  240  240  240
  240  240  240    0   14  225  240   59    0  180  240  104    0  195  240  240
  240  240  195    0   59  240  240   59    0  180  240  120    0  135  240  240
  240  240  180    0   29  240  240   59    0  180  240  120    0  135  240  240
  240  240  240    0    0  195  240   59    0  180  240   59    0  180  240  240
  240  240  240   74    0   89  225   59    0  180  135    0   44  240  240  240
  240  240  240  210   14    0   14   29    0   29    0   14  195  240  240  240
  240  240  240  240  195   29    0    0    0    0   29  180  240  240  240  240
  240  240  240  240  240  240  180   44    0  135  240  240  240  240  240  240
  240  240  240  240  240  240  240   59    0  180  240  240  240  240  240  240
  240  240  240  240  240  240  240   59    0  180  240  240  240  240  240  240
  240  240  240  240  240  240  240  104   59  195  240  240  240  240  240  240];
phiIcon(:,:,3) = [ ...
  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240
  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240  240
  240  240  240  240  240  210  135  240  135   89  135  195  240  240  240  240
  240  240  240  225   89    0   89  135    0    0    0   14  195  240  240  240
  240  240  240   89    0   89  225   74    0  165  165   14   14  240  240  240
  240  240  240    0   14  225  240   59    0  180  240  104    0  195  240  240
  240  240  195    0   59  240  240   59    0  180  240  120    0  135  240  240
  240  240  180    0   29  240  240   59    0  180  240  120    0  135  240  240
  240  240  240    0    0  195  240   59    0  180  240   59    0  180  240  240
  240  240  240   74    0   89  225   59    0  180  135    0   44  240  240  240
  240  240  240  210   14    0   14   29    0   29    0   14  195  240  240  240
  240  240  240  240  195   29    0    0    0    0   29  180  240  240  240  240
  240  240  240  240  240  240  180   44    0  135  240  240  240  240  240  240
  240  240  240  240  240  240  240   59    0  180  240  240  240  240  240  240
  240  240  240  240  240  240  240   59    0  180  240  240  240  240  240  240
  240  240  240  240  240  240  240  104   59  195  240  240  240  240  240  240];
end