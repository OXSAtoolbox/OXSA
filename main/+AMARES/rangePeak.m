% RANGEPEAK identifies the peak center, range, and multiplet indices and
% outputs them in cell arrays. It also generates an array with multiplets
% combined.
%
% Inputs:
%   - fitResults
%   - fitStatus
%   - fit
%   - wfact
%
% Outputs:
%   - pDx
%   - mDx
%   - cDx
%   - fitComb

function [pDx, mDx, cDx, fitComb] = rangePeak(fitResults, fitStatus, fit, wfact)
if nargin < 4
    wfact = 2.5;
end

% Extract data from structure
exptParams = fitStatus.exptParams;
pk = fitStatus.pkWithLinLsq.bounds;

np = length(pk);
hzPerPoint = (1/exptParams.dwellTime)/exptParams.samples;
normAmp = 0.25 + ((fitResults.amplitude - min(fitResults.amplitude))/(max(fitResults.amplitude) - min(fitResults.amplitude)))*(1 - 0.25); % rescale amplitudes to range [0.25, 1]

% Preallocate
fitComb = zeros(size(fit,1), np);
pDx = cell(1, np); % peak indices (along x-axis)
cDx = cell(1, np); % center indices
mDx = cellfun(@(x) [0,0], cell(1, np), 'UniformOutput', false); % multiplet indices (along results structures/arrays)

for p = 1:np
    if p > 1
        mDx{p}(1) = mDx{p-1}(end) + 1;
    else
        mDx{p}(1) = 1;
    end

    % Check if multiplet
    if iscell(pk(p).peakName)
        mDx{p} = mDx{p}(1):(mDx{p}(1)+length(pk(p).peakName)-1);
    else
        mDx{p} = mDx{p}(1);
    end

    fitComb(:,p) = sum(fit(:,mDx{p}),2);

    % Calculate the points to plot over so we don't end up with lots of baselines overlapping
    for m = 1:length(mDx{p})
        [~,cDx{p}(m)] =  min(abs(exptParams.ppmAxis - fitResults.chemShift(mDx{p}(m)))); % Find the point in ppmAxis that is most similar to chemical shift
    end
    peakCentreIndex = round(mean(cDx{p}));

    if isscalar(mDx{p})
        Jcoup = 0;
    else
        Jcoup = (fitResults.chemShift(mDx{p}(2))-fitResults.chemShift(mDx{p}(1)))*exptParams.imagingFrequency; % in Hz
    end
    AmpMult = max(normAmp(mDx{p})); % amplitude multiplier so shorter peaks are not weighted more than taller peaks
    TrueLW = fitResults.linewidth(mDx{p}(1)) + Jcoup*(length(mDx{p})-1); % takes into account j-coupling
    PeakWidth = wfact*round((TrueLW+2*sqrt(2*log(2))*fitResults.sigma(mDx{p}(1))/hzPerPoint)*AmpMult); % linewidth x 5
    pDx{p} = floor(peakCentreIndex-PeakWidth):ceil(peakCentreIndex+PeakWidth);

    % Ensure indices stay within bounds
    if pDx{p}(1) < 1
        pDx{p} = 1:pDx{p}(end);
    end
    if pDx{p}(end) > exptParams.samples
        pDx{p} = pDx{p}(1):exptParams.samples;
    end
end
end