function [varargout] = covarianceRand(covarianceMatrix, sizeOutput, flagOutputFormat)
% CovarianceRand: Generate correlated (complex) Gaussian random numbers
% with the specified covariance matrix.
%
% [out] = CovarianceRand(covarianceMatrix, sizeOutput, flagOutputFormat)
%
% flagOutputFormat --> 0: return one batch of noise per output argument
%                  --> 1: return a single cell array
%                  --> 2: return a single prod(sizeOutput) x nOutputs
%                         matrix
%                  --> 3: return a single sizeOutput x nOutputs matrix
%
% N.B. This function uses a definition of COVARIANCE MATCHING THE MATLAB
% "cov" function which conjugates the FIRST vector in the expression
% covariance = conj(noiseSamples) * noiseSamples.'.
% 
% To get the other convention
% i.e. other_covariance = noiseSamples * noiseSamples'
% it is necessary to pass covarianceMatrix.' as the first input of this
% function instead.

% Copyright Chris Rodgers, University of Oxford, 2008-14.
% $Id: covarianceRand.m 7745 2014-06-02 16:28:50Z crodgers $

% UNIT TEST in RodgersSpectroToolsV2-private\tests\test_covarianceRand.m

if nargin<3
    flagOutputFormat = 0;
end

% Check the correlation matrix is square
if numel(size(covarianceMatrix))~=2 || ...
        size(covarianceMatrix,1)~=size(covarianceMatrix,2) || ...
        ~isequal(covarianceMatrix,covarianceMatrix')
    error('The covariance matrix must be symmetric positive definite (and hence also Hermitian).')
end

nOutputs = size(covarianceMatrix,1);

% Special case if covarianceMatrix is all zero
if all(covarianceMatrix(:)==0)
    scaledRand = zeros([prod(sizeOutput) nOutputs]);
else
    rawRand = randn([prod(sizeOutput) nOutputs])*sqrt(0.5) + 1i*randn([prod(sizeOutput) nOutputs])*sqrt(0.5);

    % Now combine these together with appropriate mixing to give the desired
    % correlated random numbers

    scaledRand = rawRand*chol(covarianceMatrix);
end

% Convert output to the appropriate format
if flagOutputFormat == 3
    varargout = {reshape(scaledRand,[sizeOutput(:).' nOutputs])};
    return
end

if flagOutputFormat == 2
    varargout = {scaledRand};
    return
end

output = cell(nOutputs,1);

for idx=1:nOutputs
    output{idx} = reshape(scaledRand(:,idx),sizeOutput);
end

if flagOutputFormat == 1
    % Output a single cell array
    varargout = {output};
else
    varargout = output;
end
