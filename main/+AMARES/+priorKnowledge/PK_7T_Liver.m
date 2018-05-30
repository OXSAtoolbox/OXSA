function outStruct = PK_7T_Liver()
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

%% 7T file
% First attempt at liver prior knowledge


%% Bounds
fields.Bounds = {
'peakName',                                 'chemShift',     'linewidth',   'amplitude',    'phase',     'chemShiftDelta',   'amplitudeRatio'};
values.boundsCellArray = {...
{'ATP_BETA1','ATP_BETA2','ATP_BETA3'},   [-inf,inf],       [0,inf],        [0,inf],     [0,360],      [],                [];
{'ATP_ALPHA1','ATP_ALPHA2'},             [-inf,inf],       [0,inf],        [0,inf],     [0,360],      [],                []; 
{'ATP_GAMMA1','ATP_GAMMA2'},             [-inf,-0.5],       [0,inf],        [0,inf],     [0,360],      [],                [];
'PCR',                                   [-inf,inf],       [0,inf],        [0,5],     [0,360],      [],                [];
'Pi',                                    [0,10],        [0,inf],     [0,inf],         [0,360],      [],                [];
'GPC',                                     [3,6],      [0,inf],     [0,inf],         [0,360],      [],                [];
'GPE',                                     [3,6],      [0,inf],     [0,inf],         [0,360],      [],                [];
'PC',                                   [5,10],       [0,inf],        [0,inf],     [0,360],      [],                [];
'PE',                                   [5,10],       [0,inf],        [0,inf],     [0,360],      [],                [];
'NADH',                                   [-15,-5],        [0,inf],        [0,inf],     [0,360],      [],                [];
'UDPG',                                   [-15,-5],       [0,100],        [0,inf],     [0,360],      [],                [];
'PEP',                                   [2,5],       [0,100],        [0,inf],     [0,360],      [],                [];

};

%% initialValues
fields.IV = {
'peakName',                                   'chemShift',     'linewidth',   'amplitude',    'phase'};
values.IVCellArray = {...
{'ATP_BETA1','ATP_BETA2','ATP_BETA3'},          -15.996,           70,         3,               0;
{'ATP_ALPHA1','ATP_ALPHA2'},                     -7.404,           70,         3.7,               0;     
{'ATP_GAMMA1','ATP_GAMMA2'},                     -2.208,           60,         3,               0;   
'PCR',                                               0,           25,         0.5,               0;     
'Pi',                                             5.366,           80,        2,               0;   
'GPC',                                         3.1936,           50,        2.5,               0;      
'GPE',                                         3.7109,           50,        2.5,               0;      
'PC',                                          6.617,              50,       1.5,               0;               
'PE',                                              7.104,              40,        0.8,               0;               
'NADH',                                       -8.251,                      50,        1,               0;         
'UDPG',                                        -9.478,                      50,       0.6,               0;         
'PEP',                                         2.2,                      50,        0.6,               0;         

}; 

%% 
fields.PK = {
'peakName',                                 'multiplet',     'chemShiftDelta',   'amplitudeRatio',    'G_linewidth',   'G_amplitude',    'G_phase'     'G_chemShiftDelta',   'refPeak'};
values.PKCellArray = {...
{'ATP_BETA1','ATP_BETA2','ATP_BETA3'},   [1,0,1],            11.47 / 120.3,            0.5,                  [],            [],               1,            [],                    0;
{'ATP_ALPHA1','ATP_ALPHA2'},               [0,0],            19.25 / 120.3,             [],                  [],            [],               1,            [],                    0;
{'ATP_GAMMA1','ATP_GAMMA2'},               [0,0],            15.86 / 120.3,             [],                  [],            [],               1,            [],                    1;
'PCR',                                            [],             [],                [],                  [],            [],               [],           [],                    0;
'Pi',                                             [],             [],                [],                  [],            [],               1,           [],                    0;
'GPC',                                       [],             [],                [],                  [],            [],               1,           [],                    0;
'GPE',                                       [],             [],                [],                  [],            [],               1,           [],                    0;
'PC',                                            [],             [],                [],                  [],            [],               1,           [],                    0;
'PE',                                            [],             [],                [],                  [],            [],               1,           [],                    0;
'NADH',                                            [],             [],                [],                  [],            [],               1,           [],                    0;
'UDPG',                                            [],             [],                [],                  [],            [],               1,           [],                    0;
'PEP',                                            [],             [],                [],                  [],            [],               1,           [],                    0;

};

%% Pass to the function which assembles the constraints into structs and saves them
outStruct = AMARES.priorKnowledge.preparePriorKnowledge(fields,values);
outStruct.svnVersion = '$Rev: 8504 $'; 
outStruct.svnHeader = '$Header: https://cardiosvn.fmrib.ox.ac.uk/repos/crodgers/FromJalapeno/MATLAB/RodgersSpectroToolsV2/main/+AMARES/+priorKnowledge/PK_7T_Liver.m 8504 2015-07-30 12:19:08Z lucian $';
