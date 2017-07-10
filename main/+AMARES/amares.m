function Results = amares(spec, instanceNum ,voxelNum, beginTime, expOffset, pk, showPlot, varargin)
% Main AMARES routine which pre-processes spectra, passes them to amaresFit and post-processes the results.
% 
% Results = AMARES.amares(spec, instanceNum ,voxelNum, beginTime, expOffset, pk, showPlot, varargin)
%
% Inputs:
%
%        spec: Spectro.Spec object
%              OR a struct with at least the following members:
%              'spectra'/'signals'
%              'dwellTime'
%              'ppmAxis'
%              'timeAxis'
%              'imagingFrequency'
%              'samples'
%              (these are defined in the Spectro.Spec class).
% instanceNum: Fit the spectrum in spec.spectra{instanceNum}(:,voxelNum).
%    voxelNum: Fit the spectrum in spec.spectra{instanceNum}(:,voxelNum).
%   beginTime: Time for first FID point. Units: s.
%   expOffset: Expected offset for the reference peak vs centre of readout in
%              experiment. Units: ppm.
%          pk: AMARES prior knoweldge struct as returned e.g. by AMARES.priorKnowledge.PK_SinglePeak
%     options: struct or name/value pairs.
%
% Supported Options:
%
% FID: If set, this overrides the spectrum supplied in the Spectro.Spec
%      object "spec. options.FID will be fitted, but using the freqAxis,
%      etc acquisition parameters stored in Spectro.Spec. The idea is to
%      enable fitting of data that have been manipulated e.g. averaged or
%      phased in Matlab first.
% 
% Output:
% 
% "Results" struct.
% 
% Pre-processing:
% * Calculates the offset from the reference peak and corrects that peak
%   to 0ppm.
% * Performs a crude DC correction.
%
% Post-processing:
% * This function displays and assembles the results.
%
% This function is intended for any process that is separate from the
% fitting but has to be run for each voxel in turn.
% 
% Options:
% * 'fixOffset' set to a value in ppm skips all attempts to find the offset
% and fixes it at the value supplied.
% * 'noConvOffset' set to true skips the convolution offset finding and
% reverts to finding the maximum point within the range of searchlimit.
% * 'searchlimit' sets the range (inppm) each side of the expected offset that the
% peak is allowed to be located in before the maximum point method is used.
% searchlimit is then used as a limit for that maximum search aroun the
% expected offset.
%
% Inputs:
%   spec - Spec object
%   instanceNum - The index of the spec.signal cell array.
%   voxelNum - voxel to fit. 
%   beginTime - time from pulse centroid to the ADC event in s.
%   expOffset - the ppm offset betweent he reference peak and the
%               excitation centre.
%   pk - AMARES prior knowledge structure
%   showplot - true or false to enable or disable plotting of result. Can
%               accept number for figure handle.
%
% Outputs:
% Results - A structure containing all fitted values for all the peaks but
%           not sorted by peak.
%           Fields for the peak position include both ppm and Hz values for
%           both 0 at excitation frequency (FrequenciesHz, ChemicalShifts)
%           and 0 at the reference peak (FrequenciesHzIncOffset,
%           ChemicalShiftsIncOffset).

% TODO:
%
% * Remove explicit dependence on Spectro.Spec. Allow the user to specify
% options for all important spectral parameters instead for processing of
% simulated data.

%% Process options
options = processVarargin(varargin{:});

if isfield(options,'FID')
    dataFID = options.FID;
elseif isfield(spec,'signals') && ~isempty(spec.signals{instanceNum})
    dataFID = double(spec.signals{instanceNum}(:,voxelNum));
else
    dataFID = specInvFft(double(spec.spectra{instanceNum}(:,voxelNum)));
end

if isfield(options,'noConvOffset')
    noConvOffset = options.noConvOffset;
else
    noConvOffset = false;
end
    
dataSpec = specApodize(spec.dwellTime*(0:size(dataFID,1)-1).',specFft(dataFID),30);
% filteredSpec = specApodize(spec.timeAxis, dataSpec, 30);

if ~isfield(options,'fixOffset')

if ~noConvOffset
%% Find the reference peak, calculate the offset and apply it to the PK
%Take the filtered (by noise level) spectrum from above and look for the
%maximum when it is convolved with the prior knowledge spectrum.

% Create the initial value spectrum
for i=1:numel(pk.initialValues)
    initial_chemShift(i) = pk.initialValues(i).chemShift; %#ok<AGROW>
    initial_linewidth(i) = pk.initialValues(i).linewidth; %#ok<AGROW>
    initial_amp(i) = pk.initialValues(i).amplitude; %#ok<AGROW>
    initial_phase(i) = pk.initialValues(i).phase; %#ok<AGROW>
end

initialmodelFid = makeSyntheticData('coilAmplitudes',1,'noiseLevels',0,'bandwidth',1/spec.dwellTime,'imagingFrequency',spec.imagingFrequency,...
    'nPoints',spec.samples,'linewidth',initial_linewidth,'g',zeros(1,numel(pk.initialValues)),'chemicalShift',initial_chemShift,'peakAmplitudes',initial_amp.*exp(1i*pi/180*initial_phase),'beginTime',0);
%Change to Frequency Domain
initialmodel = abs(specFft(initialmodelFid.perfectFid));
%Scale it to near the spectal amplitude.
model = (initialmodel/ max(abs(initialmodel))) * max(abs((dataSpec)));

% Do the convolution and find the maximum point in the result.
data = abs(dataSpec);
convolutionRes = conv(data,flipud(model),'same');
[~,coarseIndex] = max(abs(convolutionRes));

searchRange =  round((0.5/abs(spec.ppmAxis(1)-spec.ppmAxis(2)))/2);
%Refine the point by searching around the location
searchVec = [coarseIndex-searchRange coarseIndex+searchRange];
if searchVec(1) < 1, searchVec(1) = 1; end
if searchVec(2) > spec.samples, searchVec(2) = spec.samples; end

[~,index] = max(data(searchVec(1):searchVec(2)));
index = coarseIndex + (index - searchRange);
if index < 1, index = 1; elseif index > spec.samples, index = spec.samples; end

% Uncomment to plot the convolution result.
% shift = coarseIndex-spec.samples/2;
% figure;
% plot(abs(convolutionRes));
% hold on
% plot(data+abs(max(convolutionRes)),'r')
% plot((1:spec.samples)+shift,abs((model))+abs(max(convolutionRes)),'g')
% set(gca,'xdir','reverse')
% 
% ylimits = get(gca,'ylim');
% plot(index,linspace(ylimits(1),ylimits(2),100),'k')

offset = spec.ppmAxis(index);
end

if isfield(options,'offsetSearchLimit')
    searchlimit = options.offsetSearchLimit;
else    
    searchlimit = 2;
end
if noConvOffset || abs(offset - expOffset) > searchlimit
    warning('AMARES:ConvolutionOffsetFailed','Convolution offset finding failed! Reverting to highest peak in expected region method.')
    
    
    % Search "searchlimit" ppm each side of the expected offset for the largest peak.
    % obj.misc.sequenceParams.expectedoffset set in function
    % "loadSequenceParams__UTE_CSI.m".
    
    if ~isempty(expOffset)
        ppmStep = spec.ppmAxis(2)-spec.ppmAxis(1);
        [~, index] = min(abs(spec.ppmAxis - expOffset));
        [~, i] = max(abs(dataSpec(index-round(searchlimit/ppmStep):index+round(searchlimit/ppmStep))));
        i = i-round(2/ppmStep) + index;
        offset = spec.ppmAxis(i);    
    else % Go back to original method.
        [~, i] = max(abs(dataSpec));
        offset = spec.ppmAxis(i);
    end
end

else
    offset = options.fixOffset;
end

% Apply the offset. Removed the rounding!
for i=1:length(pk.initialValues)
    pk.initialValues(i).chemShift = (pk.initialValues(i).chemShift + offset);
    pk.bounds(i).chemShift = (pk.bounds(i).chemShift + offset);
end

% TODO. N.B. We need to distinguish between ppmPlusOffset and the experimental ppmAxis.
% ppmAxis = spec.ppmAxis - offset; %???

%% DC Correction 
% Fit Line to last 25% of points to do a DC correction.
p = polyfit(spec.timeAxis(end-round(size(spec.timeAxis,1)*0.25):end),(dataFID(end-round(size(spec.timeAxis,1)*0.25):end)),0);

dataFID = dataFID - p;


%% Experiment parameters
expParams.dwellTime = spec.dwellTime;
expParams.samples = spec.samples;
expParams.imagingFrequency = spec.imagingFrequency;
expParams.timeAxis = spec.timeAxis;
expParams.dwellTime = spec.dwellTime;

expParams.beginTime = beginTime;
expParams.ppmAxis = spec.ppmAxis;
expParams.offset = offset;

%% Call the main fitting function
[fitResults,fitStatus,figureHandle,CRBResults] = AMARES.amaresFit(dataFID, expParams, pk, showPlot, options);

%% Take the output data and place it in a consistently named structure
Results.Linewidths = fitResults.linewidth;
Results.Dampings = fitResults.linewidth .* pi; % TODO: This is only valid when g=0 (Lorentzian lines).
Results.Phases = fitResults.phase;
Results.Amplitudes = fitResults.amplitude ;

%The poition of the peaks expressed in all the different ways possible.
Results.ChemicalShifts = fitResults.chemShift;
Results.ChemicalShiftsIncOffset = fitResults.chemShift - offset;
Results.FrequenciesHz = fitResults.chemShift .* spec.imagingFrequency; % Deliberately change the name to smoke out errors in other code that assumes "Frequencies" actually contains chemical shifts.
Results.FrequenciesHzIncOffset = (fitResults.chemShift - offset).* spec.imagingFrequency;
Results.offsetPPM = offset; % in ppm
Results.offsetHz = offset*spec.imagingFrequency; % in Hz

Results.Standard_deviation_of_Amplitudes = CRBResults.amplitude;
Results.Standard_deviation_of_Phases = CRBResults.phase;
Results.Standard_deviation_of_Dampings = CRBResults.linewidth*pi;
Results.Standard_deviation_of_FrequenciesHz = CRBResults.chemShift .* spec.imagingFrequency;
Results.Standard_deviation_of_ChemicalShifts = CRBResults.chemShift;
Results.Standard_deviation_of_Linewidths = CRBResults.linewidth ;

Results.resFigureHandle = figureHandle;
Results.relativeNorm = fitStatus.relativeNorm;

Results.fitStatus = fitStatus;
