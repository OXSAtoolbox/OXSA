function outStruct = PK_multiPeak_chooseInit(chemShift,amplitude,linewidth,phase,varargin)
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


options = processVarargin(varargin{:});
%% Bounds
values.boundsCellArray = {};
fields.Bounds = {
'peakName',                                 'chemShift',     'linewidth',   'amplitude',    'phase',     'chemShiftDelta',   'amplitudeRatio'};
for peakDx = 1:numel(chemShift)
    values.boundsCellArray = [values.boundsCellArray;{...
    sprintf('peak%i',peakDx),                [-inf,inf],       [0,inf],   [0,inf],        [0,360],     [],                 [];
    }];
end

if isfield(options,'fixChemicalShift')
    for iDx = 1:numel(options.fixChemicalShift)
        if iscell(options.fixChemicalShift)
            values.boundsCellArray{iDx,2} = chemShift(iDx) + options.fixChemicalShift{iDx};
            
        elseif isa(options.fixChemicalShift(iDx),'logical')
            if options.fixChemicalShift(iDx) == true
                values.boundsCellArray{iDx,2} = [];
            end
        else
            error('Input type not recognised')
        end
    end
   
end


if isfield(options,'fixLinewidth')
    for iDx = 1:numel(options.fixLinewidth)
        if iscell(options.fixLinewidth)
            values.boundsCellArray{iDx,3} = linewidth(iDx) + options.fixLinewidth{iDx};
            
        elseif isa(options.fixLinewidth(iDx),'logical')
            if options.fixLinewidth(iDx) == true
                values.boundsCellArray{iDx,3} = [];
            end
        else
            error('Input type not recognised')
        end
    end
   
end

if isfield(options,'fixPhase')
    for iDx = 1:numel(options.fixPhase)
        if iscell(options.fixPhase)
            values.boundsCellArray{iDx,5} = phase(iDx) + options.fixPhase{iDx};
            
        elseif isa(options.fixPhase(iDx),'logical')
            if options.fixPhase(iDx) == true
                values.boundsCellArray{iDx,5} = [];
            end
        else
            error('Input type not recognised')
        end
    end
   
end

%% initialValues
values.IVCellArray = {};
fields.IV = {
'peakName',                                   'chemShift',     'linewidth',   'amplitude',    'phase'};
for peakDx = 1:numel(chemShift)
    values.IVCellArray =[values.IVCellArray; {...
        sprintf('peak%i',peakDx),                                        chemShift(peakDx),               linewidth(peakDx),         amplitude(peakDx),               phase(peakDx);
         }];
end
%% 
values.PKCellArray = {};
fields.PK = {
'peakName',                                 'multiplet',     'chemShiftDelta',   'amplitudeRatio',    'G_linewidth',   'G_amplitude',    'G_phase'     'G_chemShiftDelta',   'refPeak'};
for peakDx = 1:numel(chemShift)
    values.PKCellArray = [values.PKCellArray; {...
        sprintf('peak%i',peakDx),                                      [],             [],               [],                  [],            [],               [],           [],                    0;
        }];
end

if isfield(options,'multiplet')
    for iDx = 1:numel(options.multiplet)
        values.PKCellArray{iDx,2} = options.multiplet{iDx}{1};%Multiplet structure
        values.PKCellArray{iDx,3} = options.multiplet{iDx}{2};%Chemshift delta
        values.PKCellArray{iDx,4} = options.multiplet{iDx}{3};%Amplitude array
        if numel(options.multiplet{iDx})>3
            values.boundsCellArray{iDx,1} = options.multiplet{iDx}{4};
            values.IVCellArray{iDx,1} = options.multiplet{iDx}{4};
            values.PKCellArray{iDx,1} = options.multiplet{iDx}{4};
        end

    end    
end


if isfield(options,'GPhase')
    for iDx = 1:numel(options.GPhase)
        values.PKCellArray{iDx,7} = options.GPhase(iDx);
    end    
end

if isfield(options,'refPeak')
    for iDx = 1:numel(options.refPeak)
        values.PKCellArray{iDx,9} = options.refPeak(iDx);
    end    
end

%% Pass to the function which assembles the constraints into structs and saves them
outStruct = AMARES.priorKnowledge.preparePriorKnowledge(fields,values);
outStruct.svnVersion = '$Rev: 10363 $'; 
outStruct.svnHeader = '$Header: https://cardiosvn.fmrib.ox.ac.uk/repos/crodgers/FromJalapeno/MATLAB/RodgersSpectroToolsV2/main/+AMARES/+priorKnowledge/PK_multiPeak_chooseInit.m 10363 2016-12-05 13:33:36Z lucian $';

