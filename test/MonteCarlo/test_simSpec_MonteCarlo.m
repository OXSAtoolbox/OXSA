% Run a Monte Carlo simulation on simulated spectra to test the fitting algorithm
% characteristics.
% This simulation is set up so that there is no output during fitting, and
% it will take approximately 1 h to run. It can be speeded up by reducing
% the number of runs or the number of variances tested.
% Lucian A. B. Purvis 2017

%% Make sure relevant code is added to path.
mydir = fullfile(fileparts(mfilename('fullpath')));
cd(mydir)
cd ../..
startup

%% Load Data
% fids contains 11 simulated 7T cardiac spectra of different noise levels.
% simulation contains the simulation parameters. Some of these are required
% by AMARES for the fitting (referred to as exptParams):
%   exptParams.samples
%   exptParams.imagingFrequency / MHz
%   exptParams.timeAxis / s
%   exptParams.dwellTime / s
%   exptParams.ppmAxis / ppm
%   exptParams.beginTime / s

load simData.mat


saveData = 0; %Change if the new simulation should be saved

newFileName = 'phantom_MonteCarlo_new';
refFileName = 'phantom_MonteCarlo_reference';

%% Fit all spectra using linewidth-constrained and unconstrained methods.

%% Load relevant prior knowledge.

pk = AMARES.priorKnowledge.PK_7T_Cardiac;



%% Apply the offset.
for i=1:length(pk.initialValues)
    pk.initialValues(i).chemShift = (pk.initialValues(i).chemShift + simulation.offset);
    pk.bounds(i).chemShift = (pk.bounds(i).chemShift + simulation.offset);
end


%%
showPlot = 0;

perfectFid = fids(:,11);
variance = [1e-2 0.5 1 2 4 6 8 10 15 20 35 100] ;
numRuns = 2000;

analysisFn= {'linewidth', 'amplitude', 'phase', 'chemShift'};
units = {'Hz', 'a.u.', '\circ', 'ppm'};
relFn = {'Absolute', 'Percentage'};


%% Call the main fitting function

warning('off','MATLAB:nearlySingularMatrix')
warning('off','MATLAB:singularMatrix')
tStart = tic;
for vDx = 1:numel(variance)
    monteCarloFids = perfectFid.*ones(1,numRuns) + variance(vDx)*randn(size(perfectFid,1),numRuns);
    
    for nDx = 1:numRuns
        tRunStart = tic;
        
        % Put fitStatus instead of first ~ to get status.
        % Put CRBResults instead of 3rd ~ to get CRBs
        [fitResults, ~, ~, CRBResults] = AMARES.amaresFit(monteCarloFids(:,nDx), simulation, pk, showPlot, 'quiet', true);
        
        exptSpec_filtered = specApodize(simulation.timeAxis,specFft(monteCarloFids(:,nDx)),35 * pi);
        baselineNoise_filtered = std(exptSpec_filtered(simulation.ppmAxis  <= -20));
        peaksAmp = max(abs(exptSpec_filtered));
        analysis.SNR(vDx,nDx) = peaksAmp / baselineNoise_filtered;
        
        for aDx = 1:numel(analysisFn)
            analysis.Absolute.Value.(analysisFn{aDx})(vDx,nDx,:) = fitResults.(analysisFn{aDx});
            analysis.Absolute.Bias.(analysisFn{aDx})(vDx,nDx,:) = fitResults.(analysisFn{aDx}) - simulation.(analysisFn{aDx});
            analysis.Percentage.Value.(analysisFn{aDx})(vDx,nDx,:) = fitResults.(analysisFn{aDx})./simulation.(analysisFn{aDx})*100;
            analysis.Percentage.Bias.(analysisFn{aDx})(vDx,nDx,:) = (fitResults.(analysisFn{aDx}) - simulation.(analysisFn{aDx}))./simulation.(analysisFn{aDx})*100;
            
            
            analysis.Absolute.CRLB.(analysisFn{aDx})(vDx,nDx,:) = CRBResults.(analysisFn{aDx});
            analysis.Percentage.CRLB.(analysisFn{aDx})(vDx,nDx,:) = CRBResults.(analysisFn{aDx})./simulation.(analysisFn{aDx});
        end
        analysis.Time(vDx,nDx) =  toc(tRunStart);
        
    end
    fprintf('Variance %i/%i complete in %0.02fs\n', vDx, numel(variance), toc(tStart))
    
end

warning('on','MATLAB:nearlySingularMatrix')
warning('on','MATLAB:singularMatrix')

%% Calculate summary statistics


summaryRes = createSummaryStructure(analysis);

if saveData
    save(fullfile(mydir,'data',newFileName), 'summaryRes')
end
%% Plot PCr results
figPos = [5,5,40,20]; % Figure position in cm
errorFn = {'Bias', 'SD', 'RMSE', 'CRLB'};

for eDx = 3%1:numel(errorFn)
    figure(600 + eDx)
    clf
    set(gcf,'units', 'centimeters', 'Position', figPos)
    
    for aDx = 1:numel(analysisFn)
        
        subplot(4,1,aDx)
        
        plot(summaryRes.SNR,summaryRes.Percentage.(errorFn{eDx}).(analysisFn{aDx})(:,8), 'x-','Linewidth', 4, 'MarkerSize', 20)
        ylabel(sprintf('%s / %%',analysisFn{aDx}))
        
        set(gca, 'FontSize', 15)
    end
    
end

%%


if numRuns>=1000
    %Only compare CRLBs to SDs if the number of repeats is enough to
    %converge.
    res = compareSingleMonteCarloResult(summaryRes.Absolute.SD, summaryRes.Absolute.CRLB, 'Absolute');
    
    
    
    figure(800 )
    clf
    set(gcf,'units', 'centimeters', 'Position', figPos)
    
    for aDx = 1:numel(analysisFn)
        
        subplot(4,1,aDx)
        
        plot(summaryRes.SNR,summaryRes.Percentage.CRLB.(analysisFn{aDx})(:,8) - summaryRes.Percentage.SD.(analysisFn{aDx})(:,8), 'x-','Linewidth', 4, 'MarkerSize', 20)
        ylabel(sprintf('%s / %%',analysisFn{aDx}))
        
        set(gca, 'FontSize', 15)
    end
    
end

%% Compare to reference data
load(fullfile(mydir,'data',refFileName))

figPos = [5,5,40,20]; % Figure position in cm
errorFn = {'Bias', 'SD', 'RMSE'};

for eDx = 3%1:numel(errorFn)
    figure(1000 + eDx)
    clf
    set(gcf,'units', 'centimeters', 'Position', figPos)
    
    for aDx = 1:numel(analysisFn)
        
        subplot(4,1,aDx)
        plot(summaryRes.SNR,summaryRes.Percentage.(errorFn{eDx}).(analysisFn{aDx})(:,8), 'x-','Linewidth', 4, 'MarkerSize', 20)
        hold on
        plot(refSummary.SNR,refSummary.Percentage.(errorFn{eDx}).(analysisFn{aDx})(:,8), 'x-','Linewidth', 4, 'MarkerSize', 20)
        
        ylabel(sprintf('%s / %%',analysisFn{aDx}))
        
        set(gca, 'FontSize', 15)
    end
    
end