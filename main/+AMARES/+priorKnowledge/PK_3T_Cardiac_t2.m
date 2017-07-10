function outStruct = PK_3T_Cardiac_t2()

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
'PDE',                                   [-inf,inf],       [20,100],       [0,inf],     [0,360],      [],                [];
'x2_3_DPG1',                             [3.5,7.5],        [20,100],       [0,inf],     [0,360],      [],                [];
'x2_3_DPG2',                             [4.0,8.0],        [20,100],       [0,inf],     [0,360],      [],                [];
};

%% initialValues
% linewidths changed from 10,10,10,10,20,20,20
fields.IV = {
'peakName',                                   'chemShift',     'linewidth',   'amplitude',    'phase', 'addlinewidth'};
values.IVCellArray = {...
{'ATP_BETA1','ATP_BETA2','ATP_BETA3'},          -16.74,           10,         1,               0,           30;
{'ATP_ALPHA1','ATP_ALPHA2'},                     -7.88,           10,         1,               0,          30;     
{'ATP_GAMMA1','ATP_GAMMA2'},                     -2.82,           10,         1,               0,          30;   
'PCR',                                               0,           10,         1,               0,           30;     
'PDE',                                            2.69,           20,         1,               0,           30;      
'x2_3_DPG1',                                       5.1,           20,         1,               0,           30;      
'x2_3_DPG2',                                      6.58,           20,         1,               0,           30; 
};

%% 
fields.PK = {
'peakName',                                 'multiplet',     'chemShiftDelta',   'amplitudeRatio',    'G_linewidth',   'G_amplitude',    'G_phase'     'G_chemShiftDelta',      'base_linewidth',   'refPeak'};
values.PKCellArray = {...
{'ATP_BETA1','ATP_BETA2','ATP_BETA3'},      [1,0,1],            15 /  49.898,         0.5,                 1,            [],               1,                [],                 3.0144,         0;
{'ATP_ALPHA1','ATP_ALPHA2'},                  [0,0],            16 /  49.898,         [],                  1,            [],               1,                [],                 7.0255,        0;
{'ATP_GAMMA1','ATP_GAMMA2'},                  [0,0],            15 /  49.898,         [],                  1,            [],               1,                [],                  2.644,        0;
'PCR',                                            [],             [],               [],                  1,            [],               1,                 [],                  0,         1;
'PDE',                                            [],             [],               [],                  1,            [],               1,                 [],                 43.0273,          0;
'x2_3_DPG1',                                     [],             [],                 [],                 1,            [],               1,               [],                  9.6821,        0;
'x2_3_DPG2',                                     [],             [],                 [],                 1,            [],               1,               [],                  9.6821,        0;
};


%% Pass to the function which assembles the constraints into structs and saves them
outStruct = AMARES.priorKnowledge.preparePriorKnowledge(fields,values);
outStruct.svnVersion = '$Rev: 7634 $';
outStruct.svnHeader = '$Header: https://cardiosvn.fmrib.ox.ac.uk/repos/crodgers/FromJalapeno/MATLAB/RodgersSpectroToolsV2/main/+AMARES/+priorKnowledge/PK_3T_Cardiac_t2.m 7634 2014-05-02 09:49:26Z lucian $';
