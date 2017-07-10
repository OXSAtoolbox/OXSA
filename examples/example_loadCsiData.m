%% Example of methods of loading a CSI dataset.

%% Make sure relevant code is added to path.
mydir = fullfile(fileparts(mfilename('fullpath')));
cd(mydir)
cd ..
startup

%%
% Either:
dt = Spectro.dicomTree('dir','sample-data/csi-3tCardiac');
matched = dt.searchForSeriesInstanceNumber(22, 1);

%  Which is the same as:
%   matched = dt.search('target','instance','return','instance','query',@(inst,ser,stu) ser.SeriesNumber == 22 && inst.InstanceNumber == 1);

ss = Spectro.Spec(matched);


% % Or use GUI to pick which series to load for further scripted processing:
% ss = guiLoad('sample-data/csi-3tCardiac');

% % Or use GUI for fully interactive inspection of the data
% obj = guiPromptSpectroPlotCsi('sample-data/csi-3tCardiac');
% disp('Done loading: obj.data.spec contains the equivalent of the "ss" object.')

%% Set required experimental parameters

% beginTime is the time for first FID point in s. It is used for first
% order phase correction. This should be the same for any identical coil
% using the same sequence.
beginTime = 4.7e-4;

% The expected offset for the reference peak vs. the centre of readout in
% the experiment / ppm.
expOffset = 5;


%% Choose an instance and voxel number

% In this case there is only a single instance is included, so:
instanceNum = 1;

% Pick a voxel to load:

voxelNum = 9676;

%% Set the prior knowledge.

pk = AMARES.priorKnowledge.PK_3T_Cardiac;

%% Set plot handle
% 0 to not show plot, 1 to give lowest unused figure handle, or a
% double to assign figure handle. e.g. :

showPlot = 8008;

%% Run AMARES.amares

Results = AMARES.amares(ss, instanceNum ,voxelNum, beginTime, expOffset, pk, showPlot);

sprintf('Processing complete!\n')