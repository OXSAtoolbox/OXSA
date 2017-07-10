function [structFid, optout] = makeSyntheticData(varargin)
% makeSyntheticData: Simulate 31P FID
%
% [structFid, optout] = makeSyntheticData(options)
%
% options structure has fields:
%
% noiseCovarianceMatrix OR noiseLevels
% amplitudes
% phases
%
% beginTime
%
% structFid has fields:
%
% bandwidth
%
% It is also permissible to supply options as field / value pairs.
%
% optout is the processed form of the options structure

% References:
% Spectrum formula taken from Vanhamme, L., A. van den Boogaart, and S. Van Huffel, Improved method for accurate and efficient quantification of MRS data with use of prior knowledge. Journal of Magnetic Resonance, 1997. 129(1): p. 35-43.
% Others from Ernst RR, Bodenhausen G, Wokaun A (1987) Principles of nuclear magnetic resonance in one and two dimensions. Clarendon Press, Oxford
% and from Fukushima E, Roeder SBW (1981) Experimental pulse NMR : a nuts and bolts approach. Addison-Wesley, Reading, Mass. ; London

% Copyright Chris Rodgers, University of Oxford, 2008.
% $Id: makeSyntheticData.m 7556 2014-03-27 17:42:00Z crodgers $

options = processVarargin(varargin{:});

%% Parse the options structure and extract values
if ~isfield(options,'coilAmplitudes')
    error('You must specificy the coil signal amplitudes "coilAmplitudes".')
else
    coilAmplitudes=options.coilAmplitudes(:);
    nCoils=numel(coilAmplitudes);
end

% Phase in radians
if isfield(options,'coilPhases')
    coilPhases=options.coilPhases(:);
else
    coilPhases=zeros(nCoils,1);
end

if isfield(options,'noiseCovarianceMatrix')
    noiseCovarianceMatrix=options.noiseCovarianceMatrix;

    if numel(size(noiseCovarianceMatrix))~=2 || any(size(noiseCovarianceMatrix)~=nCoils)
        error('The noiseCovarianceMatrix is the wrong size.')
    end
elseif isfield(options,'noiseLevels')
    % Uncorrelated noise of given levels
    if numel(options.noiseLevels)==nCoils
        noiseCovarianceMatrix=diag(options.noiseLevels(:));
    elseif numel(options.noiseLevels)==1
        noiseCovarianceMatrix=diag(repmat(options.noiseLevels,1,nCoils));
    else
        error('The noiseLevels are the wrong size.')
    end
else
    error('You must provide noiseLevels or noiseCovarianceMatrix')
end

if isfield(options,'bandwidth')
    bandwidth = options.bandwidth;
else
    bandwidth = 4000;
end

if isfield(options,'imagingFrequency')
    imagingFrequency = options.imagingFrequency;
else
    imagingFrequency = 49; % 31P is at approximately 49MHz on a 3T system
end

if isfield(options,'nPoints')
    nPoints = options.nPoints;
else
    nPoints = 1024;
end

if isfield(options,'g')
    g = options.g;
else
    g = [0 0];
end

if isfield(options,'damping') && isfield(options,'linewidth')
    error('Please specify damping OR linewidth rather than both');
end

if isfield(options,'damping')
    damping = options.damping;
elseif isfield(options,'linewidth')
    if all(g == 0)
        damping = options.linewidth * pi;
    else
        error('Cannot handle linewidth for lines that are not Lorentzian.');
    end
else
    damping = [50 50];
end

if isfield(options,'chemicalShift')
    chemicalShift = options.chemicalShift;
else
    chemicalShift = [3 -4];
end

if isfield(options,'peakAmplitudes')
    peakAmplitudes = options.peakAmplitudes;
else
    peakAmplitudes = [1 0.35];
end

if isfield(options,'beginTime')
    beginTime = options.beginTime;
else
    beginTime = 0;
end

t = ((0:(nPoints-1)).'/(bandwidth)); % In seconds
tTrue = t + beginTime;

% Generate random noise in a cell array
noise = covarianceRand(noiseCovarianceMatrix,size(tTrue),1);

fids = zeros(numel(tTrue),numel(coilAmplitudes));

perfectFid = zeros(numel(tTrue),1);

for peakdx=1:numel(chemicalShift)
    % Lorentzian peak at chemicalShift ppm
    perfectFid = perfectFid + peakAmplitudes(peakdx) * ...
        exp(- damping(peakdx)*(1-g(peakdx)+g(peakdx)*tTrue).*tTrue ...
        + 1i*2*pi*chemicalShift(peakdx)*imagingFrequency*tTrue);
end

for idx=1:numel(coilAmplitudes)
    fids(:,idx) = coilAmplitudes(idx)*exp(coilPhases(idx)*1i)*perfectFid + noise{idx};
end

freqAxis = ((-nPoints/2):(nPoints/2-1)).'/(t(2)*nPoints); % In Hz

structFid=struct('fids',fids,'t',t,'perfectFid',perfectFid,...
    'bandwidth',bandwidth,'imagingFrequency',imagingFrequency,'nPoints',nPoints,...
    'dwellTime',t(2),'acquisitionTime',t(2)*nPoints,'tTrue',tTrue,...
    'freqAxis',freqAxis);

if nargout>1
    strFields={'coilAmplitudes','coilPhases','noiseCovarianceMatrix',...
        'damping','g',...
        'chemicalShift','peakAmplitudes','beginTime'};
    for idx=1:numel(strFields)
        optout.(strFields{idx}) = eval(strFields{idx});
    end
end
