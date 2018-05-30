% Run a Monte Carlo simulation on five voxels from a phantom dataset
% to test the fitting algorithm characteristics. 
% This simulation is set up so that there is no output during fitting, and
% it will take approximately 3 h 10 min to run. It can be speeded up by
% reducing the number of runs or the number of variances tested.
% Lucian A. B. Purvis 2017


%% Make sure relevant code is added to path.
mydir = fullfile(fileparts(mfilename('fullpath')));
cd(mydir)
cd ../..
startup

%%

saveData = 0; %Change if the new simulation should be saved

newFileName = 'phantom_MonteCarlo_new';
refFileName = 'phantom_MonteCarlo_reference';

%% Load the struct 'spec' which contains:
%              'spectra'/'signals'
%              'dwellTime'
%              'ppmAxis'
%              'timeAxis'
%              'imagingFrequency'
%              'samples'

load sampleData.mat

%% Set required experimental parameters

% beginTime is the time for first FID point in s. It is used for first
% order phase correction.
beginTime = 4.7038e-4;

% The expected offset for the reference peak vs. the centre of readout in
% the experiment / ppm.
expOffset = 0;


%% Choose an instance number

% In this case only a single instance is included, so:
instanceNum = 1;


numVoxels = 5;
%% Set the prior knowledge.

pk = AMARES.priorKnowledge.PK_SinglePeak;

%% Set plot handle
% 0 to not show plot, 1 to give lowest unused figure handle, or a
% double to assign figure handle. e.g. :

showPlot = 0;

%% Run AMARES.amares
numRuns = 1000;

variance = [1e-4 0.005 0.01 0.015 0.02 0.05 0.06 0.07 0.08 0.09 0.1 0.3];
% 5 voxels included.
%%
baseSpec = spec.spectra{1};

%% Approximate "True values" to calculate percentage changes
%Determined using highest possible SNR spectrum for each voxel.

trueValue.Linewidths = [9.59 7.98 6.59 6.45 7.04];
trueValue.Amplitudes = [1.17 1.62 2.07 2.75 3.63];
trueValue.Phases = [36.7 58.5 79.8 102.8 129.1];
trueValue.ChemicalShiftsIncOffset = [-0.05 -0.02 -0.06 -0.03 -0.05];

%% Monte-Carlo simulation

analysisFn= {'Linewidths', 'Amplitudes', 'Phases', 'ChemicalShiftsIncOffset'};
crlbFn = {'Standard_deviation_of_Linewidths', 'Standard_deviation_of_Amplitudes', 'Standard_deviation_of_Phases', 'Standard_deviation_of_ChemicalShifts'};
relFn = {'Absolute', 'Percentage'};
snr = zeros(numel(variance), numVoxels, numRuns);
clear fullRes
tStart = tic;
% Convolution offset fails for low SNR, so turn it off for now.
warning('off','AMARES:ConvolutionOffsetFailed')
for vDx = 1:numel(variance)
    nCount = 1;
    
    for nDx = 1:numRuns
        
        spec.spectra{1} = baseSpec + randn(2048,5)*variance(vDx);
        
        
        for voxelNum = 1:numVoxels
            tRunStart = tic;
            
            Results = AMARES.amares(spec, instanceNum ,voxelNum, beginTime, expOffset, pk, showPlot, 'quiet', true);
            
            exptSpec_filtered = specApodize(spec.timeAxis,spec.spectra{1}(:,voxelNum),10 * pi);
            baselineNoise_filtered = std(exptSpec_filtered(spec.ppmAxis  <= -20));
            peaksAmp = max(abs(exptSpec_filtered));
            analysis.SNR(vDx,nCount) = peaksAmp / baselineNoise_filtered;
            
            for aDx = 1:numel(analysisFn)
                
                analysis.Absolute.Value.(analysisFn{aDx})(vDx,nCount) = Results.(analysisFn{aDx});
                analysis.Percentage.Value.(analysisFn{aDx})(vDx,nCount) = Results.(analysisFn{aDx})./trueValue.(analysisFn{aDx})(voxelNum)*100;
                
                analysis.Absolute.Bias.(analysisFn{aDx})(vDx,nCount) = Results.(analysisFn{aDx}) - trueValue.(analysisFn{aDx})(voxelNum);
                analysis.Percentage.Bias.(analysisFn{aDx})(vDx,nCount) = (Results.(analysisFn{aDx})-trueValue.(analysisFn{aDx})(voxelNum))./trueValue.(analysisFn{aDx})(voxelNum)*100;
                
                analysis.Absolute.CRLB.(analysisFn{aDx})(vDx,nCount) = Results.(crlbFn{aDx});
                analysis.Percentage.CRLB.(analysisFn{aDx})(vDx,nCount) = Results.(crlbFn{aDx})./trueValue.(analysisFn{aDx})(voxelNum)*100;
                
            end
            analysis.Time(vDx,nCount) =  toc(tRunStart);
            
            nCount = nCount + 1;
            
        end
        
        
    end
    
    
    fprintf('Variance %i/%i complete in %0.02fs\n', vDx, numel(variance), toc(tStart))
    
end
warning('on','AMARES:ConvolutionOffsetFailed')

%% Calculate summary statistics

summaryRes = createSummaryStructure(analysis);

%% Plot
figPos = [5,5,40,20]; % Figure position in cm
errorFn = {'Bias', 'SD', 'RMSE'};

for eDx = 3
    %Plot RMSE only
    
    figure(600 + eDx)
    clf
    set(gcf,'units', 'centimeters', 'Position', figPos)
    
    for aDx = 1:numel(analysisFn)
        
        subplot(4,1,aDx)
        
        plot(summaryRes.SNR,summaryRes.Percentage.(errorFn{eDx}).(analysisFn{aDx}), 'x-','Linewidth', 4, 'MarkerSize', 20)
        ylabel(sprintf('%s / %%',analysisFn{aDx}))
        
        set(gca, 'FontSize', 15)
    end
    
end

%%
if numRuns>=1000
    %Only compare CRLBs to SDs if the number of repeats is enough to
    %converge.
    res = compareSingleMonteCarloResult(summaryRes.Absolute.SD, summaryRes.Absolute.CRLB, 'Absolute');
    
    
    
    figure(800)
    clf
    set(gcf,'units', 'centimeters', 'Position', figPos)
    
    for aDx = 1:numel(analysisFn)
        
        subplot(4,1,aDx)
        
        plot(summaryRes.SNR,summaryRes.Percentage.CRLB.(analysisFn{aDx}) - summaryRes.Percentage.SD.(analysisFn{aDx}), 'x-','Linewidth', 4, 'MarkerSize', 20)
        ylabel(sprintf('%s / %%',analysisFn{aDx}))
        
        set(gca, 'FontSize', 15)
    end
    
end

%%
refSummary = summaryRes;

if saveData
    save(fullfile(mydir,'data',newFileName), 'refSummary')
end
%% Plot against saved data

load(fullfile(mydir,'data',refFileName))

for eDx = 3%1:numel(errorFn)
    figure(600 + eDx)
    clf
    set(gcf,'units', 'centimeters', 'Position', figPos)
    
    for aDx = 1:numel(analysisFn)
        
        subplot(4,1,aDx)
        
        plot(summaryRes.SNR,summaryRes.Percentage.(errorFn{eDx}).(analysisFn{aDx}) , 'x-','Linewidth', 4, 'MarkerSize', 20)
        hold on
        plot(summaryRes.SNR,refSummary.Percentage.(errorFn{eDx}).(analysisFn{aDx}), 'x-','Linewidth', 4, 'MarkerSize', 20)
        
        
        ylabel(sprintf('%s / %%',analysisFn{aDx}))
        
        set(gca, 'FontSize', 15)
    end
    
end