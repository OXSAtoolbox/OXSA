%% Example of using AMARES.amares using 31P phantom data.

%% Make sure relevant code is added to path.
mydir = fullfile(fileparts(mfilename('fullpath')));
cd(mydir)
cd ..
startup
%% Load the struct 'spec' which contains:
%              'spectra'/'signals'
%              'dwellTime'
%              'ppmAxis'
%              'timeAxis'
%              'imagingFrequency'
%              'samples'

load sampleData.mat

%% Set required experimental parameters

% beginTime is the time for first FID point in s. It is used for first
% order phase correction.
beginTime = 4.7038e-4;

% The expected offset for the reference peak vs. the centre of readout in
% the experiment / ppm.
expOffset = 0;


%% Choose an instance and voxel number

% In this case only a single instance is included, so:
instanceNum = 1;

% 5 voxels included. Using voxel 3:

voxelNum = 3;

%% Set the prior knowledge.

pk = AMARES.priorKnowledge.PK_SinglePeak;

%% Set plot handle
% 0 to not show plot, 1 to give lowest unused figure handle, or a
% double to assign figure handle. e.g. :

showPlot = 8008;

%% Run AMARES.amares

Results = AMARES.amares(spec, instanceNum ,voxelNum, beginTime, expOffset, pk, showPlot);

sprintf('Processing complete!\n')