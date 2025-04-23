function outStruct = PK_twoPeaksWithFixedSeparation()
% Apply grouping with phases fixed equal.

%% .M file to assemble the bounds, priorKnowledge and initialValues structs for the matlab implementation of AMARES

%Each of B, PK and IV is a 1xN struct, where N is the number of peaks. Note
%multiplets are counted as one peak.
%The fields are as follows:
%bounds           initialValues          priorKnowledge

%peakName         peakName               peakName
%chemShift        chemShift              multiplet
%linewidth        linewidth              chemShiftDelta
%amplitude        amplitude              amplitudeRatio
%phase            phase                  G_linewidth
%chemShiftDelta                          G_amplitude
%amplitudeRatio                          G_phase
%                                        G_chemShiftDelta
%                                        refPeak

%% Bounds
fields.Bounds = {
'peakName',                                 'chemShift',     'linewidth',   'amplitude',    'phase',     'chemShiftDelta',   'amplitudeRatio'};
values.boundsCellArray = {...
'HDO',                                   [4.5 4.9],       [0,30],        [0,inf],     [0,360],      [],                [];
'Glc',                                   [3.2 4.2],        [0,30],     [0,inf],         [0,360],      [],                [];
};

%% initialValues
fields.IV = {
'peakName',                                   'chemShift',     'linewidth',   'amplitude',    'phase'};
values.IVCellArray = {...
'HDO',                                        4.7,           10,         1,               0;     
'Glc',                                        3.7,           10,        .25,               0;   
}; 

%% 
fields.PK = {
'peakName',                                 'multiplet',     'chemShiftDelta',   'amplitudeRatio',    'G_linewidth',   'G_amplitude',    'G_phase'     'G_chemShiftDelta',   'refPeak'};
values.PKCellArray = {...
'HDO',                                            [],             [],                [],                  [],            [],               1,           [],                    1;
'Glc',                                             [],             0.9,                [],                  [],            [],               1,           [],                    0;
};

%% Pass to the function which assembles the constraints into structs and saves them
outStruct = AMARES.priorKnowledge.preparePriorKnowledge(fields,values);
