function [CRB] = estimateCRB(imagingFrequency, dwellTime, beginTime, noiseVariance, xFit, constraintsCellArray)
% Compute the Cramer-Ráo Lower Bounds (CRBs) for a given set of prior
% knowledge and the best-fit to a particular set of data.
%
% Input parameters:
%
% imagingFreq - Imaging frequency / MHz.
% dwelltime - Acquisition dwelltime / s.
% beginTime - Time of 1st FID point / s.
% noiseVariance - Noise variance / same arb units as amp0.
% xFit - Optimal fit parameters from lsqcurvefit.
% constraintsCellArray - Cell array form of prior knowledge constraints.
%
% Output:
% 
% CRB.chemShift etc - CRBs for each parameter.
% CRB.covariance - Full covariance matrix for all model parameters.
%
% EXAMPLE:
%
% prior = struct('pk',AMARES.priorKnowledge.PK_3T_Cardiac());
% res = AMARES.amaresDriver(obj,'type','voxel','prior',prior,'forceFitAgain',true);
% CRB = AMARES.estimateCRB(res{1}.fitStatus{1}.exptParams.imagingFrequency, res{1}.fitStatus{1}.exptParams.dwellTime, res{1}.fitStatus{1}.exptParams.beginTime, res{1}.fitStatus{1}.noise_var, res{1}.fitStatus{1}.xFit, res{1}.fitStatus{1}.constraintsCellArray)

% References:
%
% 1. Cavassila S, Deval S, Huegen C, van Ormondt D, Graveron-Demilly D.
% Cramer-Rao bound expressions for parametric estimation of overlapping
% peaks: Influence of prior knowledge. J Magn Reson 2000;143:311-20.
% 
% 2. Cavassila S, Deval S, Huegen C, van Ormondt D, Graveron-Demilly D.
% Cramer-Rao bounds: an evaluation tool for quantitation. NMR Biomed
% 2001;14:278-83.

% TODO: Some model parameters (g, beginTime) are missing below.
% TODO: Support simultaneous fitting of several spectra.

% Matlab computation NOT USING SYMBOLLIC TOOLBOX AT ALL!
mP = AMARES.compute_P_Matrix(xFit,constraintsCellArray);
mDTD = AMARES.compute_DT_times_D_Matrix(xFit,constraintsCellArray,beginTime,dwellTime,imagingFrequency,2048);


Fishernum = real(mP'*mDTD*mP)/noiseVariance;

% TODO: We need to handle the situation of a singular fisher information
% matrix. Traditionally, this is done using a pseudo-inverse, but that
% gives an overly-optimistic estimate of the variance. See [1] for details.
%
% 1. IEEE TRANSACTIONS ON SIGNAL PROCESSING, VOL. 49, NO. 1, JANUARY 2001 87
% Parameter Estimation Problems with Singular Information Matrices
% Petre Stoica and Thomas L. Marzetta
%
% 2. IEEE SIGNAL PROCESSING LETTERS, VOL. 16, NO. 6, JUNE 2009 453
% On the Constrained Cramér–Rao Bound With a Singular Fisher Information Matrix
% Zvika Ben-Haim and Yonina C. Eldar

lastwarn('');

% Don't show message for singular matrix
warn_state = warning('off' , 'MATLAB:singularMatrix');
warn_state_c = onCleanup(@() warning(warn_state)); % reset when this is cleared
CRB.covariance = mP*(Fishernum\mP');
[~, msgid] = lastwarn;
clear warn_state_c warn_state

% But still if there was a singular matrix warning then
if strcmp(msgid,'MATLAB:singularMatrix')
    % Run the Moore-Penrose pseudo inverse instead!
    CRB.covariance = mP*pinv(Fishernum)*mP';
    
    % Fix up any -ve diagonal elements
    for idx=1:size(CRB.covariance,1)
        if CRB.covariance(idx,idx) < 0
            CRB.covariance(idx,idx) = 0;
        end
    end
end

CRB_together = sqrt(diag(CRB.covariance)).'; % SDs for each parameter.

[params, numParams] = AMARES.getCanonicalOrdering();

for pDx = 1:numParams

CRB.(params{pDx}) = CRB_together(pDx:numParams:end);

end

return

