function modelFid = makeModelFid(x,constraintsCellArray,beginTime,dwellTime,imagingFrequency,nPoints)
% The numerical AMARES model function.
%
% modelFid = makeModelFid(x,constraintsCellArray,beginTime,dwellTime,imagingFrequency,nPoints)
%
% This function is used at the core of the Matlab AMARES code as the
% objective function.

[chemShift, linewidth, amplitude, phase] = AMARES.applyModelConstraints(x, constraintsCellArray);

% TODO: g is a variable parameter. Don't hard-code it to zero!
% TODO: Use AMARES.linewidthToDamping() to pass in a damping parameter to
%       makeSyntheticData instead of a linewidth?

% Cut-and-paste in from makeSyntheticData
bandwidth = 1/dwellTime;
damping = linewidth * pi;

peakAmplitudesWithPhase = amplitude.*exp(1i*phase*pi/180);

tTrue = ((0:(nPoints-1)).'/(bandwidth)) + beginTime; % In seconds

% Lorentzian peak at chemShift ppm
modelFid = exp(tTrue(:) * (-damping(:) + 1i*2*pi*chemShift(:)*imagingFrequency).') * peakAmplitudesWithPhase(:);

%% Original code for comparison

% model = makeSyntheticData('coilAmplitudes',1,'noiseLevels',0, ...
%     'bandwidth',1/exptParams.dwellTime,'imagingFrequency',exptParams.imagingFrequency, ...
%     'nPoints',exptParams.samples,'beginTime', options.beginTime,...
%     'linewidth',linewidth,'g',zeros(1,numel(linewidth)),...
%     'chemicalShift',chemShift,'peakAmplitudes',amplitude.*exp(1i*phase*pi/180));
% 
% result = model.perfectFid;

% maxdiff(result, modelFid,'result vs modelFid',1e-10)
