function results = sortFitData(results,unsortedData,spec,pk,beginTime,varargin)

options = processVarargin(varargin{:});

if isfield(options,'voxel')
    vdx = options.voxel;
else
    vdx = 1;
end

%% Sort the data by peaks 
[results, thePeakNames, theResTypes] = AMARES.sortDataByPeaks(results,unsortedData,pk,vdx,options);

%% Additional results information added to structure per slice
% options, offset and peak names
results.peakNames = thePeakNames;
results.fitFields = theResTypes;
if isfield(options,'fitOptions')
    results.options = options.fitOptions;
end
results.headers.imagingFrequency = spec(1).imagingFrequency;
results.headers.beginTime = beginTime;
% Get subversion revision of calling file
stack = dbstack('-completenames');
try
    results.svnVersion = getSubversionRevision(fileparts(stack(2).file)); % Tag with SVN revision
end
%% Further per-voxel output
results.offsetHz(vdx,1) = unsortedData.offsetHz;

actualRefPeak = AMARES.getActualRefPeakDx(pk);
if ~isempty(actualRefPeak)
    results.headers.zeroOrderPhase(vdx,1) = unsortedData.Phases(actualRefPeak); % Use phase from the reference peak specified in the prior knowledge file.
else
    results.headers.zeroOrderPhase(vdx,1) = 0; % No overall phase.
end
results.relativeNorm(vdx,1) = unsortedData.relativeNorm;
% Tag computation time
results.iterations(vdx,1) = unsortedData.fitStatus.OUTPUT.iterations;
results.fitStatus{vdx,1} = unsortedData.fitStatus;
