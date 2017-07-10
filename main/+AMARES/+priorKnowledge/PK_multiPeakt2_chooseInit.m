function outStruct = PK_multiPeakt2_chooseInit(chemShift,amplitude,linewidth,phase,base_linewidth, addlinewidth)
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



%% Bounds
values.boundsCellArray = {};
fields.Bounds = {
'peakName',                                 'chemShift',     'linewidth',   'amplitude',    'phase',     'chemShiftDelta',   'amplitudeRatio'};
for peakDx = 1:numel(chemShift)
    values.boundsCellArray = [values.boundsCellArray;{...
    sprintf('peak%i',peakDx),                                     [-inf,inf],       [0,inf],   [0,inf],        [0,360],     [],                 [];
    }];
end
%% initialValues
values.IVCellArray = {};
fields.IV = {
'peakName',                                   'chemShift',     'linewidth',   'amplitude',    'phase', 'addlinewidth'};
for peakDx = 1:numel(chemShift)
    values.IVCellArray =[values.IVCellArray; {...
        sprintf('peak%i',peakDx),                                        chemShift(peakDx),               linewidth(peakDx),         amplitude(peakDx),               phase(peakDx), addlinewidth(peakDx);
         }];
end
%% 
values.PKCellArray = {};
fields.PK = {
'peakName',                                                      'multiplet',     'chemShiftDelta',   'amplitudeRatio',    'G_linewidth',   'G_amplitude',    'G_phase'     'G_chemShiftDelta', 'base_linewidth',  'refPeak'};
for peakDx = 1:numel(chemShift)
    values.PKCellArray = [values.PKCellArray; {...
        sprintf('peak%i',peakDx),                                      [],             [],               [],                  1,            [],               [],          [],        base_linewidth(peakDx),            0;
        }];
end
%% Pass to the function which assembles the constraints into structs and saves them
outStruct = AMARES.priorKnowledge.preparePriorKnowledge(fields,values);
outStruct.svnVersion = '$Rev: 6844 $'; 
outStruct.svnHeader = '$Header: https://cardiosvn.fmrib.ox.ac.uk/repos/crodgers/FromJalapeno/MATLAB/RodgersSpectroToolsV2/main/+AMARES/+priorKnowledge/PK_multiPeak_chooseInit.m 6844 2013-08-05 10:56:02Z will $';

