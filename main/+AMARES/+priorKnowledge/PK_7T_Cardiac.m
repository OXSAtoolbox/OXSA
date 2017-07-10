function outStruct = PK_7T_Cardiac()

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
% This is version 7. Based on screenshots of 3T prior knowledge (cardiac
% C31P 3T_LEC.*) in jMRUI AMARES 3T Oxford standard prior knowledge.docx.
% With adaptations for the change in imaging frequency.


%% Bounds
fields.Bounds = {
'peakName',                                 'chemShift',     'linewidth',   'amplitude',    'phase',     'chemShiftDelta',   'amplitudeRatio'};
values.boundsCellArray = {...
{'ATP_BETA1','ATP_BETA2','ATP_BETA3'},   [-inf,inf],       [0,inf],        [0,inf],     [0,360],      [],                [];
{'ATP_ALPHA1','ATP_ALPHA2'},             [-inf,inf],       [0,inf],        [0,inf],     [0,360],      [],                []; 
{'ATP_GAMMA1','ATP_GAMMA2'},             [-inf,inf],       [0,inf],        [0,inf],     [0,360],      [],                [];
'PCR',                                   [-inf,inf],       [0,inf],        [0,inf],     [0,360],      [],                [];
'PDE',                                     [1.5,3],       [20,100],       [0,inf],     [0,360],      [],                [];
'x2_3_DPG1',                             [3.5,7.5],        [20,100],       [0,inf],     [0,360],      [],                [];
'x2_3_DPG2',                             [4.0,8.0],        [20,100],       [0,inf],     [0,360],      [],                [];
};

%% initialValues
fields.IV = {
'peakName',                                   'chemShift',     'linewidth',   'amplitude',    'phase'};
values.IVCellArray = {...
{'ATP_BETA1','ATP_BETA2','ATP_BETA3'},          -16.33,           56,         1,               0;
{'ATP_ALPHA1','ATP_ALPHA2'},                     -7.65,           50,         1,               0;     
{'ATP_GAMMA1','ATP_GAMMA2'},                     -2.47,           34,         1,               0;   
'PCR',                                               0,           33,         1,               0;     
'PDE',                                            2.69,           60,         1,               0;      
'x2_3_DPG1',                                       5.2,           60,         1,               0;      
'x2_3_DPG2',                                      6.35,           60,         1,               0; 
};

%% 
fields.PK = {
'peakName',                                 'multiplet',     'chemShiftDelta',   'amplitudeRatio',    'G_linewidth',   'G_amplitude',    'G_phase'   ,'RelPhase',  'G_chemShiftDelta',   'refPeak'};
values.PKCellArray = {...
{'ATP_BETA1','ATP_BETA2','ATP_BETA3'},        [1,0,1],            15 / 120.3,            0.5,                 [],            [],                1,          [],       [],                    0;
{'ATP_ALPHA1','ATP_ALPHA2'},                    [0,0],            16 / 120.3,            [],                  [],            [],                1,          [],     [],                    0;
{'ATP_GAMMA1','ATP_GAMMA2'},                   [0,0],            15 / 120.3,             [],                  [],            [],                1,          [],    [],                    0;
'PCR',                                           [],                [],                  [],                  [],            [],                1,          [],    [],                    1;
'PDE',                                           [],                [],                  [],                  [],            [],                1,          [],     [],                    0;
'x2_3_DPG1',                                     [],                [],                  [],                  [],            6,                 1,          [],      [],                    0;
'x2_3_DPG2',                                     [],                [],                  [],                  [],            6,                 1,          [],     [],                    0;
};


%% Pass to the function which assembles the constraints into structs and saves them
outStruct = AMARES.priorKnowledge.preparePriorKnowledge(fields,values);
outStruct.svnVersion = '$Rev: 7662 $';
outStruct.svnHeader = '$Header: https://cardiosvn.fmrib.ox.ac.uk/repos/crodgers/FromJalapeno/MATLAB/RodgersSpectroToolsV2/main/+AMARES/+priorKnowledge/PK_7T_Cardiac.m 7662 2014-05-07 13:26:32Z will $';
