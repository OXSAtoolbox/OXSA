function multipletComponentToPeakIndex = getMultipletComponentToPeakIndex(pk)
%
% Decode the prior knowledge "peakName" cell arrays to show the names of
% every "multiplet component" and the "peak" that each one came from.
%
% N.B. There is a split in Matlab AMARES between "peaks" and "multiplet
% components". For singlets, these are the same thing. But e.g. a triplet
% is 1 "peak" but 3 "multiplet components".

multipletComponentToPeakIndex = {};
for idx=1:numel(pk.priorKnowledge)
    if iscell(pk.priorKnowledge(idx).peakName)
        multipletComponentToPeakIndex(1,end+1:end+numel(pk.priorKnowledge(idx).peakName)) = pk.priorKnowledge(idx).peakName;
        multipletComponentToPeakIndex(2,end+1-numel(pk.priorKnowledge(idx).peakName):end) = num2cell(repmat(idx,1,numel(pk.priorKnowledge(idx).peakName)));
    else
        multipletComponentToPeakIndex{1,end+1} = pk.priorKnowledge(idx).peakName; %#ok<AGROW>
        multipletComponentToPeakIndex{2,end} = idx;
    end
end
