function [hFig, hAx] = amaresPlot(varargin)
% Plot the results from a Matlab AMARES.
%
% [hFig, hAx] = amaresPlot(fitStatus,...);
%
% EXAMPLE:
% AMARES.amaresPlot(fitStatus);

%% Process options
options = processVarargin(varargin{:});

%% Required "options"
exptParams = options.exptParams;
inputFid = options.inputFid;
xFit = options.xFit;
constraintsCellArray = options.constraintsCellArray;

%% Defaults
if ~isfield(options,'apodization')
    options.apodization = 30;
end

if ~isfield(options,'xUnits')
    options.xUnits = 'PPM';
end

%% Count number of subplots
totalPlots = 1; % Result is always plotted.

if ~isfield(options,'plotIndividual') || options.plotIndividual % On by default
    totalPlots = totalPlots + 1;
end

if ~isfield(options,'plotResidual') || options.plotResidual % Default on.
    totalPlots = totalPlots + 1;
end

if ~isfield(options,'plotInitial') || options.plotInitial % Default on.
    totalPlots = totalPlots + 1;
end

%% Axis options
if ~isfield(exptParams,'offset')
    exptParams.offset = 0;
end

if strcmp(options.xUnits,'PPM')
    xAxis = exptParams.ppmAxis-exptParams.offset;
    
    xAxisLabel = '\delta / ppm';
    if isfield(options,'xlims')
        xLimits = options.xlims;
    elseif max(xAxis) > 15 && min(xAxis) < - 20 %% Normal phosphorus
        xLimits = [-25 15];
    else
        xLimits = [ceil(min(xAxis)) floor(max(xAxis))];
    end
elseif strcmp(options.xUnits,'HZ')
    xAxis = exptParams.freqAxis;
    xAxisLabel = '\nu / Hz';
    xLimits = [-3600 2400];
else
    error('Not a recognised axis unit.')
end

if isfield(options,'overideXAxis')
    if numel(options.overideXAxis) > 1
        xAxis = options.overideXAxis;
        xLimits = [min(xAxis) max(xAxis)];
        
    elseif numel(options.overideXAxis) == 1
        xAxis = xAxis + options.overideXAxis;
        xLimits = xLimits + options.overideXAxis;
    end
end

if isfield(options,'hFig')
    hFig = options.hFig;
    figure(hFig)
    clf
else
    hFig = figure;
end

%% Apply prior knowledge to yield full solution
fitResults = AMARES.applyModelConstraints(xFit,constraintsCellArray);

%% Calculate the zero and first order phase correction
if ~isfield(options,'firstOrder') || options.firstOrder % On by default
    if ~isfield(exptParams,'freqAxis')
        exptParams.freqAxis = exptParams.ppmAxis * exptParams.imagingFrequency;
    end
    
    % Set zero-order phase relative to the reference peak
    actualRefPeak = AMARES.getActualRefPeakDx(options.pkWithLinLsq);
    if ~isempty(actualRefPeak)
        zeroOrderPhaseRad = fitResults.phase(actualRefPeak) * pi / 180;
    else
        zeroOrderPhaseRad = 0;
    end
    
    fprintf('zeroOrderPhaseRad = %.3f\n',zeroOrderPhaseRad)
    
    % N.B. Careful... freqAxis here MUST NOT contain any frequency offset.
    % It must be centred at the actual acquisition centre frequency.
    firstOrderCorrection = exp(-1i * (zeroOrderPhaseRad + 2* pi * exptParams.freqAxis * exptParams.beginTime));
else
    firstOrderCorrection = 1;
end

%% Calculate the fixed spectra to plot

timeAxis = exptParams.dwellTime*(0:exptParams.samples-1).';

spectrum = specApodize(timeAxis, specFft(inputFid,1).*firstOrderCorrection,options.apodization);

[modelFid,~,modelFids] = AMARES.makeModelFidAndJacobianReIm(xFit,constraintsCellArray,exptParams.beginTime,exptParams.dwellTime,exptParams.imagingFrequency,exptParams.samples, 'complexOutput', true);

fittedSpectrum =  specApodize(timeAxis, specFft(modelFid).*firstOrderCorrection,options.apodization);

%% Plot fit

% Subplot positioning
overall =  [0 0 0.05 0.02];
element = [.1 .03 0.03 0];

hAx = subplotSetBorder(totalPlots,1,element,overall,1); % This is always the first plot.

plot(xAxis,real(spectrum),'k')
hold on
plot(xAxis,real(fittedSpectrum),'r')
set(gca,'XDir','reverse')
ylabel('Spectrum fit');

% Set the ylimits to 10% wider than the highest point visible on the plot
[~, XAxisLimitIndex(1)] = min(abs(xAxis-xLimits(1)));
[~, XAxisLimitIndex(2)] = min(abs(xAxis-xLimits(2)));

ytop = 1.1 * max([max(real(spectrum(XAxisLimitIndex(1):XAxisLimitIndex(2)))) max(real(fittedSpectrum(XAxisLimitIndex(1):XAxisLimitIndex(2))))]);
ybottom = 1.1 * min([min(real(spectrum(XAxisLimitIndex(1):XAxisLimitIndex(2)))) min(real(fittedSpectrum(XAxisLimitIndex(1):XAxisLimitIndex(2))))]);

yLimits = [ybottom ytop];  % Get the range of the y axis

set(gca,'XLim',xLimits) % Set explicitly, stops reset on figure resize.
set(gca,'YLim',yLimits)
box off

subplots = 1;

%% What does the user want to plot?
if ~isfield(options,'plotIndividual') || options.plotIndividual % On by default
    subplots = subplots + 1;
    
    % Individual peaks
    hAx(end+1) = subplotSetBorder(totalPlots,1,element,overall,subplots);
    
    indivColours = distinguishable_colors(numel(fitResults.chemShift));
    
    
    for peakDx = 1:numel(fitResults.chemShift)
        hold on

        indivFID = modelFids(:,peakDx);
  
        indivSpectrum = specApodize(timeAxis,specFft(indivFID).*firstOrderCorrection,options.apodization);
        
        %Calculate the points to plot over so we don't end up with lots of
        %baselines overlapping
        [~,peakCentreIndex] =  min(abs((exptParams.ppmAxis) - fitResults.chemShift(peakDx)));
        hzPerPoint = (1/exptParams.dwellTime)/exptParams.samples;
        
        plotPeakWidth = 2.5*round(fitResults.linewidth(peakDx)+2*sqrt(2*log(2))*fitResults.sigma(peakDx)/hzPerPoint);
        peakPlotIndex = [floor(peakCentreIndex-plotPeakWidth) ceil(peakCentreIndex+plotPeakWidth)];
        if peakPlotIndex(1)<1
            peakPlotIndex(1) = 1;
        end
        if peakPlotIndex(2) > exptParams.samples
            peakPlotIndex(2) = exptParams.samples;
        end
        
        plot(xAxis(peakPlotIndex(1):peakPlotIndex(2)),real(indivSpectrum(peakPlotIndex(1):peakPlotIndex(2))),'color',indivColours(peakDx,:))
    end
    set(gca,'XDir','reverse')
    ylabel('Individual Peaks')
    set(gca,'XLim',xLimits)
    set(gca,'YLim',yLimits)
    box off
end

if ~isfield(options,'plotResidual') || options.plotResidual % Default on.
    subplots = subplots + 1;
    residual = specApodize(timeAxis,specFft(options.residual ).*firstOrderCorrection,options.apodization);
    
    hAx(end+1) = subplotSetBorder(totalPlots,1,element,overall,subplots);
    
    plot(xAxis,real(residual),'k')
    hold on
    plot(xAxis,zeros(size(residual)),'r--')
    
    plot(xAxis,repmat(+std(residual),size(residual)),'r:')
    plot(xAxis,repmat(-std(residual),size(residual)),'r:')
    
    set(gca,'XDir','reverse')
    ylabel('Residual')
    set(gca,'XLim',xLimits)
    set(gca,'YLim',yLimits)
    box off
end

if ~isfield(options,'plotInitial') || options.plotInitial % Default on.
    subplots = subplots + 1;
    
   initialFID = AMARES.makeInitialValuesModelFid(options.pkWithLinLsq, exptParams);
    initialSpectrum = specApodize(timeAxis,specFft(initialFID).*firstOrderCorrection,options.apodization);
    
    hAx(end+1) = subplotSetBorder(totalPlots,1,element,overall,subplots);
    plot(xAxis,real(initialSpectrum),'r-x')
    hold on
    plot(xAxis,real(spectrum),'k')
    set(gca,'XDir','reverse')
    ylabel({'Initial values';'for non-linear fit'})
    set(gca,'XLim',xLimits)
    set(gca,'YLim',yLimits)
    
    box off
end

% Label the last x-axis at the bottom
xlabel(xAxisLabel)

% Fix up all xticks...
if numel(hAx) > 1
    set(hAx(1:end-1),'xtick',get(hAx(end),'XTick'),'xticklabel',[])
end

end