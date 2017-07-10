function outStruct = PK_SinglePeak_chooseInit(chemShift,amplitude,linewidth,phase)
%% .M file to assemble the bounds, priorKnowledge and initialValues structs for the matlab implementation of AMARES

%Each of B, PK and IV is a 1xN struct, where N is the number of peaks. Note
%multiplets are counted as one peak.
%The fields are as follows:
%bounds           initialValues          priorKnowledge

%peakName         peakName               peakName
%chemShift        chemShift              multiplet
%damping          damping                chemShiftDelta
%amplitude        amplitude              amplitudeRatio
%phase            phase                  G_damping
%chemShiftDelta                          G_amplitude
%amplitudeRatio                          G_phase
%                                        G_chemShiftDelta
%                                        refPeak

%% Single peak at 0ppm

%% Bounds
fields.Bounds = {
'peakName',                                 'chemShift',     'linewidth',   'amplitude',    'phase',     'chemShiftDelta',   'amplitudeRatio'};
values.boundsCellArray = {...
'Peak1',                                     [-inf,inf],       [0,inf],   [0,inf],        [0,360],     [],                 [];
};

%% initialValues
fields.IV = {
'peakName',                                   'chemShift',     'linewidth',   'amplitude',    'phase'};
values.IVCellArray = {...
'Peak1',                                        chemShift,               linewidth,         amplitude,               phase;
};

%% 
fields.PK = {
'peakName',                                 'multiplet',     'chemShiftDelta',   'amplitudeRatio',    'G_linewidth',   'G_amplitude',    'G_phase'     'G_chemShiftDelta',   'refPeak'};
values.PKCellArray = {...
'Peak1',                                      [],             [],               [],                  [],            [],               [],           [],                    0;
};

%% Pass to the function which assembles the constraints into structs and saves them
outStruct = AMARES.priorKnowledge.preparePriorKnowledge(fields,values);
outStruct.svnVersion = '$Rev: 6782 $'; 
outStruct.svnHeader = '$Header:$';

