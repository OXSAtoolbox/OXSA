function actualRefPeak = getActualRefPeakDx(pk)
% Extract the ID of the actual reference peak.

refPeak = find([pk.priorKnowledge.refPeak],1,'first');

if isempty(refPeak)
    actualRefPeak = [];
else
    actualRefPeak = 0; 
    for tmpDx=1:refPeak
        if iscell(pk.priorKnowledge(tmpDx).peakName)
            actualRefPeak = actualRefPeak + numel(pk.priorKnowledge(tmpDx).peakName);
        else
            actualRefPeak = actualRefPeak + 1;
        end
    end
end
