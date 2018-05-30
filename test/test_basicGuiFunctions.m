%This file is a basic run test of some of the basic functions used by the GUI.
%These are not meant to be exhaustive, but instead are a simple sanity check.
%For clearer examples, the scripts in /examples/ should be used.

%% Load prior knowledge

pk = AMARES.priorKnowledge.PK_7T_Cardiac;

%% Load data

dt = Spectro.dicomTree('dir','sample-data/csi-3tCardiac');
matched = dt.searchForSeriesInstanceNumber(22, 1);

% Version 1: Spec obj only

ss = Spectro.Spec(matched);

% Version 2: load GUI

obj = ProcessLong31pSpectra(dt, matched);

%% Check basic button callbacks

quickPlotAllSpectra_Callback(obj,[],[])

quickPlotFid_Callback(obj,[],[])

quickPlotSpectrum_Callback(obj,[],[])

hObject = patch(NaN,NaN,NaN);

set(hObject, 'UserData',390)

voxelClicked_Callback(obj,hObject,[])

quickFit_Callback(obj,[],[])


