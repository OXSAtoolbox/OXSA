function [modelFid, Jacobian, modelFids] = makeModelFidAndJacobianReIm(x,constraintsCellArray,beginTime,dwellTime,imagingFrequency,nPoints, varargin)
%The numerical AMARES model function with Jacobian support and
%incorporating the split into real, imaginary parts.
%
%[modelFid, Jacobian] = makeModelFidAndJacobianReIm(x,constraintsCellArray,beginTime,dwellTime,imagingFrequency,nPoints)
%
%This function is used at the core of the Matlab AMARES code as the
%objective function when the Jacobian is also required.
%This code still reverts to the original functions, but NB the linewidths
%are HWHM.

options = processVarargin(varargin{:});

if isfield(options,'complexOutput') &&~isempty(options.complexOutput)
    complexOutput = options.complexOutput;
else
    % The real and imaginary parts of the FID and Jacobian must be
    % separated for lsqcurvefit
    complexOutput = false;
end

modelParams = AMARES.applyModelConstraints(x, constraintsCellArray);

bandwidth = 1/dwellTime;

tTrue = ((0:(nPoints-1)).'/(bandwidth)) + beginTime; % In seconds

[modelFid, modelFids] = AMARES.makeModelFid(modelParams, tTrue, imagingFrequency);

if ~complexOutput
    % Split real/imag parts:
    modelFid = [real(modelFid); imag(modelFid)];
end

if nargout > 1
    % Jacobian required.
    
    Jacobian = AMARES.compute_Jacobian(modelFids, imagingFrequency, tTrue, modelParams);
    
    % P must be calculated at run time, because it can depend on the
    % current value of x.
    P = AMARES.compute_P_Matrix(x,constraintsCellArray);
    
    Jacobian = Jacobian * P;
    
    if ~complexOutput
        % Split real/imag parts:
        Jacobian = [real(Jacobian); imag(Jacobian)];
    end
end
