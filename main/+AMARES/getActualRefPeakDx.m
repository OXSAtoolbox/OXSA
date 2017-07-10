function actualRefPeak = getActualRefPeakDx(pk)
% Extract the ID of the actual reference peak.
%
% TODO: This is an ugly hack. Surely we should just have consistent peak
% numbering without making a special case for "multiplet component" vs
% "peak"...?

refPeak = find([pk.priorKnowledge.refPeak],1,'first');

if isempty(refPeak)
    actualRefPeak = [];
else
    actualRefPeak = 0; % This is horrible. Find the reference peak results.
    for tmpDx=1:refPeak
        if iscell(pk.priorKnowledge(tmpDx).peakName)
            actualRefPeak = actualRefPeak + numel(pk.priorKnowledge(tmpDx).peakName);
        else
            actualRefPeak = actualRefPeak + 1;
        end
    end
end
