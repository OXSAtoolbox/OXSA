function generatePKCache(listOfPk)

exptParams.samples = 2048;
exptParams.imagingFrequency = 120.316;
exptParams.dwellTime = 1/8000;
exptParams.timeAxis = 0:exptParams.dwellTime:(exptParams.dwellTime*exptParams.samples);
exptParams.ppmAxis = linspace(-4000,4000,exptParams.samples)/exptParams.imagingFrequency;
exptParams.beginTime = 0;

satn.pcr = 1;
satn.alphaAtp = 1;
satn.betaAtp= 1;
satn.gammaAtp= 1;
satn.dpg= 1;
addCor.pcr= 1;
addCor.alphaAtp= 1;
addCor.betaAtp= 1;
addCor.gammaAtp= 1;
addCor.dpg = 1;
bloodCorrectionFactor = 1;

for iDx = 1:numel(listOfPk)
    try
        pk = feval(['AMARES.priorKnowledge.' listOfPk{iDx}]);
    
    [fitResults, fitStatus, figureHandle, CRBResults] = AMARES.amaresFit(rand(round(exptParams.samples),1), exptParams, pk, false, 'MaxIter', 1);    
    
    
    CRB = AMARES.estimateCRB(exptParams.imagingFrequency, ...
            exptParams.dwellTime,...
            exptParams.beginTime,...
            fitStatus.noise_var,...
            fitStatus.xFit,...
            fitStatus.constraintsCellArray);

    [~, ~] = AMARES.estimateDerivedParamAndCRB(fitStatus.pkWithLinLsq, fitStatus.xFit, fitStatus.constraintsCellArray,CRB.covariance,...
            {'PCR_am * PCR_cor / ((ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor)'; % ratio
            'PCR_am * PCR_cor / (((ATP_ALPHA1_am + ATP_ALPHA2_am)*ATP_ALPHA_cor + (ATP_BETA1_am + ATP_BETA2_am + ATP_BETA3_am)*ATP_BETA_cor + (ATP_GAMMA1_am + ATP_GAMMA2_am)*ATP_GAMMA_cor)/3)'; % avgRatios
            'PCR_am * PCR_cor / (((ATP_ALPHA1_am + ATP_ALPHA2_am)*ATP_ALPHA_cor + (ATP_GAMMA1_am + ATP_GAMMA2_am)*ATP_GAMMA_cor)/2)'; % gamma&alpha - avgRatios 

            'PCR_am * PCR_cor / ((ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor - BloodCorrection * (x2_3_DPG1_am + x2_3_DPG2_am)*DPG_cor)'; % ratioBloodCorrected
            'PCR_am * PCR_cor / (((ATP_ALPHA1_am + ATP_ALPHA2_am)*ATP_ALPHA_cor + (ATP_BETA1_am + ATP_BETA2_am + ATP_BETA3_am)*ATP_BETA_cor + (ATP_GAMMA1_am + ATP_GAMMA2_am)*ATP_GAMMA_cor)/3 - BloodCorrection * (x2_3_DPG1_am + x2_3_DPG2_am)*DPG_cor)'; % avgRatioBloodCorrected
            'PCR_am * PCR_cor / (((ATP_ALPHA1_am + ATP_ALPHA2_am)*ATP_ALPHA_cor + (ATP_GAMMA1_am + ATP_GAMMA2_am)*ATP_GAMMA_cor)/2 - BloodCorrection * (x2_3_DPG1_am + x2_3_DPG2_am)*DPG_cor)'; %gamma&alpha - avgRatioBloodCorrected

            '(PCR_am * PCR_cor / PCR_sat) / ((ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor/ATP_GAMMA_sat)'; % ratioSatCor
            '(PCR_am * PCR_cor / PCR_sat) / (((ATP_ALPHA1_am + ATP_ALPHA2_am) * ATP_ALPHA_cor/ATP_ALPHA_sat + (ATP_BETA1_am + ATP_BETA2_am + ATP_BETA3_am) * ATP_BETA_cor/ATP_BETA_sat + (ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor/ATP_GAMMA_sat )/3)'; % avgRatioSatCor
            '(PCR_am * PCR_cor / PCR_sat) / (((ATP_ALPHA1_am + ATP_ALPHA2_am) * ATP_ALPHA_cor/ATP_ALPHA_sat + (ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor/ATP_GAMMA_sat )/2)'; % gamma&alpha - avgRatioSatCor

            '(PCR_am * PCR_cor / PCR_sat) / (((ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor/ATP_GAMMA_sat) - BloodCorrection * (x2_3_DPG1_am + x2_3_DPG2_am)*DPG_cor/DPG_sat)'; % RatioBloodSatCorrected
            '(PCR_am * PCR_cor / PCR_sat) / (((ATP_ALPHA1_am + ATP_ALPHA2_am) * ATP_ALPHA_cor/ATP_ALPHA_sat + (ATP_BETA1_am + ATP_BETA2_am + ATP_BETA3_am) * ATP_BETA_cor/ATP_BETA_sat + (ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor/ATP_GAMMA_sat )/3 - BloodCorrection * (x2_3_DPG1_am + x2_3_DPG2_am)*DPG_cor/DPG_sat)'; % avgRatioBloodSatCorrected
            '(PCR_am * PCR_cor / PCR_sat) / (((ATP_ALPHA1_am + ATP_ALPHA2_am) * ATP_ALPHA_cor/ATP_ALPHA_sat + (ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor/ATP_GAMMA_sat )/2 - BloodCorrection * (x2_3_DPG1_am + x2_3_DPG2_am)*DPG_cor/DPG_sat)'; % gamma&alpha - avgRatioBloodSatCorrected

            '(PCR_am * PCR_cor / PCR_sat) / (((ATP_GAMMA1_am + ATP_GAMMA2_am) * ATP_GAMMA_cor - BloodCorrection * (x2_3_DPG1_am + x2_3_DPG2_am)*DPG_cor)/ATP_GAMMA_sat)'; % bloodBeforeSat

            },...
            {'PCR_sat','ATP_ALPHA_sat','ATP_BETA_sat','ATP_GAMMA_sat','DPG_sat','PCR_cor','ATP_ALPHA_cor','ATP_BETA_cor','ATP_GAMMA_cor','DPG_cor','BloodCorrection'},...
            [satn.pcr, satn.alphaAtp, satn.betaAtp,satn.gammaAtp,satn.dpg, addCor.pcr, addCor.alphaAtp, addCor.betaAtp,addCor.gammaAtp,addCor.dpg,bloodCorrectionFactor ]);
    
    
    catch err
        % Check if the error is the PK needs input arguments. If so skip it
        % as it isn't apropriate for the deployed version.
       if strcmp(err.identifier,'MATLAB:minrhs')
            continue % Skip to the next pk
       else         
           %rethrow as warning  
           warning(err.identifier,err.message);
       end
       
    end
end

