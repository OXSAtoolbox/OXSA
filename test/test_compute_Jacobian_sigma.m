% Test: Regression test for the sigma column of AMARES.compute_Jacobian.
% OXSA ISSUE #10
% Chris Rodgers, Aug 2026

classdef test_compute_Jacobian_sigma < matlab.unittest.TestCase
methods(Test,TestTags={})

function test1(testCase)
imagingFrequency = 120.3;
dwellTime = 1/2000;
beginTime = 0.002;
nPoints = 16;
tTrue = ((0:(nPoints-1)).' * dwellTime) + beginTime;

modelParams.chemShift = 1.7;
modelParams.linewidth = 7.5;
modelParams.amplitude = 3.2;
modelParams.phase = 27;
modelParams.sigma = 4.1;

[~, modelFids] = AMARES.makeModelFid(modelParams, tTrue, imagingFrequency);
Jacobian = AMARES.compute_Jacobian(modelFids, imagingFrequency, tTrue, modelParams);
sigmaColumn = Jacobian(:,5);

delta = 1e-6 * max(1, abs(modelParams.sigma));

modelParamsPlus = modelParams;
modelParamsPlus.sigma = modelParams.sigma + delta;
[modelFidPlus, ~] = AMARES.makeModelFid(modelParamsPlus, tTrue, imagingFrequency);

modelParamsMinus = modelParams;
modelParamsMinus.sigma = modelParams.sigma - delta;
[modelFidMinus, ~] = AMARES.makeModelFid(modelParamsMinus, tTrue, imagingFrequency);

finiteDifference = (modelFidPlus - modelFidMinus) / (2 * delta);

verifyEqual(testCase, sigmaColumn, finiteDifference, 'RelTol', 1e-7)

end

end
end
