function [thisDTD] = compute_DT_times_D_Matrix(optimVar, func, beginTime,dwellTime,imagingFrequency,nPoints)
% Compute D'*D matrix (where D is the Jacobian of partial derivatives of
% model w.r.t. the full set of model parameters).

modelParams = AMARES.applyModelConstraints(optimVar, func);

bandwidth = 1/dwellTime;
tTrue = ((0:(nPoints-1)).'/(bandwidth)) + beginTime; % In seconds

[~,modelFids] = AMARES.makeModelFid(modelParams, tTrue, imagingFrequency);
  
Dmat = AMARES.compute_Jacobian(modelFids, imagingFrequency, tTrue, modelParams);

thisDTD = Dmat' * Dmat;


