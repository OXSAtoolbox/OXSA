%% Example of using AMARES.amaresFit using simulated 31P cardiac spectra.

%% Make sure relevant code is added to path.
mydir = fullfile(fileparts(mfilename('fullpath')));
cd(mydir)
cd ..
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

%% Fit all spectra for using linewidth-constrained and unconstrained methods.
for  pDx = 1:2
    %% Load relevant prior knowledge.
    if pDx == 1
        pk = AMARES.priorKnowledge.PK_7T_Cardiac;
    elseif pDx ==2
        pk = AMARES.priorKnowledge.PK_7T_Cardiac_t2;
    end
    
    
    
    %% Apply the offset.
    for i=1:length(pk.initialValues)
        pk.initialValues(i).chemShift = (pk.initialValues(i).chemShift + simulation.offset);
        pk.bounds(i).chemShift = (pk.bounds(i).chemShift + simulation.offset);
    end
    
    %% Call the main fitting function
    
    for fidDx = 1:size(fids,2)
        showPlot = pDx*100 + fidDx;
        % Put fitStatus instead of first ~ to get status.
        % Put CRBResults instead of 3rd ~ to get CRBs
        [fitResults fitStatus figureHandle CRBResults] = AMARES.amaresFit(fids(:,fidDx), simulation, pk, showPlot);
              
    end
    
    
end

%% Calculate PCr/gamma-ATP ratio and CRLB for final voxel
SigAtSatn = @(T1, TR, alpha) ((-1 + exp(TR/T1))*sind(alpha))/(exp(TR/T1) - cosd(alpha));

% For example, pick values to use for saturation correction

t1.PCr = 3.1; %in s
t1.gATP = 1.815;

Tr = 1; %same units as t1

theAlpha = 30; %in degrees

satn.PCr = SigAtSatn(t1.PCr, Tr, theAlpha);
satn.gATP = SigAtSatn(t1.gATP, Tr, theAlpha);

extraParamStr =        {'PCR_sat','ATP_GAMMA_sat'};

extraParamVals = [satn.PCr, satn.gATP];

derivedParamStr =  {  '(PCR_am / PCR_sat) / ((ATP_GAMMA1_am + ATP_GAMMA2_am) /ATP_GAMMA_sat)'};

[derivedParamVal, CRB] = AMARES.estimateDerivedParamAndCRB(pk, fitStatus.xFit, fitStatus.constraintsCellArray, CRBResults.covariance, derivedParamStr, extraParamStr, extraParamVals);


sprintf('Processing complete!\n')
