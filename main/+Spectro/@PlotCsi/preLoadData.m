function [data] = preLoadData(dicomPathOrTree, spectraUid, options)
% Load the CSI data sets specified in spectraUid into memory in a format
% that can be used by the PlotCsi GUI.
%
% Either a DICOM series UID or a cell array of DICOM instance UIDs may be
% supplied. The data for either the entire series or for the selected
% instances will be returned. Data is sorted by the coil name for simpler
% handling later.

% Copyright Chris Rodgers, University of Oxford, 2008-11.
% $Id: preLoadData.m 8053 2014-10-06 03:22:11Z crodgers $

%% Load DICOM tree
if ischar(dicomPathOrTree)
    dicomTree = Spectro.dicomTree('dir',dicomPathOrTree);
else
    dicomTree = dicomPathOrTree;
end
clear dicomPathOrTree

%% Evaluate the UIDs supplied
if iscell(spectraUid)
    % Load only the requested individual spectra
    for instanceDx = 1:numel(spectraUid)
        specPath = searchForUid(dicomTree, spectraUid{instanceDx});
        instance(instanceDx) = dicomTree.study(specPath.studyDx).series(specPath.seriesDx).instance(specPath.instanceDx); %#ok<AGROW>
        
        % Check that these spectra are all from one series
        SeriesInstanceUID{instanceDx} = dicomTree.study(specPath.studyDx).series(specPath.seriesDx).SeriesInstanceUID; %#ok<AGROW>
        if ~strcmp(SeriesInstanceUID{instanceDx}, SeriesInstanceUID{1})
            error('It is not permitted to load spectra from different series.')
        end
        
        % Chop of instance from specPath because it is meaningless
        specPath = rmfield(specPath,'instanceDx');
    end
elseif ischar(spectraUid)
    % Load all instances in the DICOM series
    specPath = searchForUid(dicomTree, spectraUid);
    instance = dicomTree.study(specPath.studyDx).series(specPath.seriesDx).instance;
else
    error('Bad spectraUid - see help for details.')
end

%% Load the spectroscopy DICOM files
for instanceDx=1:numel(instance)
    tmpInfo{instanceDx} = SiemensCsaParse(dicominfo(instance(instanceDx).Filename));
    
    % Add null-strings for key fields if they are missing
    tmpInfo{instanceDx} = ensureFieldPresent(tmpInfo{instanceDx},{'SeriesDescription','ProtocolName','ImageComments'});
    
    fprintf('Loaded file %d --> protocol (%s (%s)), coil "%s"\n',...
        instanceDx,tmpInfo{instanceDx}.SeriesDescription,tmpInfo{instanceDx}.ProtocolName,...
        tmpInfo{instanceDx}.csa.ImaCoilString);
end

% spec = Spectro.InterpCsi(tmpInfo, options);
spec = Spectro.ShiftCsi(tmpInfo, options);
% spec = Spectro.SenseSpec(tmpInfo, options);

%% Load reference images
if ~isfield(options,'referenceImages') || ~iscell(options.referenceImages)
    if ~isfield(options,'refUid') || ~iscell(options.refUid)
        % FIDs have no reference images
        if ~isfield(tmpInfo{1},'ReferencedImageSequence')
            numRefs = 0;
        else
            % Find refenced images by their UID
            numRefs = numel(fields(tmpInfo{1}.ReferencedImageSequence));
        end
        
        refUid = cell(numRefs,1);
        for refdx=1:numRefs
            refUid{refdx,1} = tmpInfo{1}.ReferencedImageSequence.(['Item_' num2str(refdx)]).ReferencedSOPInstanceUID;
        end
    else
        numRefs = numel(options.refUid);
        refUid = options.refUid;
    end
    
    strRef = cell(numRefs,1);
    pathRef = cell(numRefs,1);
    for refdx=1:numRefs
        pathRef{refdx,1} = searchForUid(dicomTree,refUid{refdx});
        
        % If there are duplicate files with the same UID, keep only one
        if numel(pathRef{refdx,1}) > 1
            pathRef{refdx,1} = pathRef{refdx,1}(1);
        end
        
        if ~isempty(pathRef{refdx,1})
            refSeries = dicomTree.study(pathRef{refdx}.studyDx).series(pathRef{refdx}.seriesDx);
            for refdx2=1:numel(refSeries.instance)
                strRef{refdx,1}{refdx2,1} = refSeries.instance(refdx2).Filename;
            end
        end
    end
    
    % Don't leave gaps if reference images couldn't be loaded
    strRefEmptyMask=cellfun(@isempty,strRef);
    if any(strRefEmptyMask)
        strRef(strRefEmptyMask) = [];
        numRefs = numel(strRef);
        fprintf('WARNING: Could not load all reference images!\nContinuing with only %d out of %d images.\n\n',...
            numRefs,numel(fields(tmpInfo{1}.ReferencedImageSequence)));
    end
else
    % The actual reference image DICOM filenames have been supplied.
    strRef = options.referenceImages;
    numRefs = numel(strRef);
    
    % HACK. There are no checks here to see whether the specified filename
    % has any relation to the spectral data being loaded.
    pathRef = [];
    refUid = [];
end

infoRef = cell(numRefs,1);
imgRef = cell(numRefs,1);
for refdx=1:numRefs
    % Preallocate in case no data files for a reference image were found
    infoRef{refdx,1} = cell(numel(strRef{refdx}),1);
    imgRef{refdx,1} = cell(numel(strRef{refdx}),1);
    for refdx2=1:numel(strRef{refdx})
        infoRef{refdx}{refdx2}=dicominfo(strRef{refdx}{refdx2});
        imgRef{refdx}{refdx2}=myDicomRead(infoRef{refdx}{refdx2}); % Don't swap row/col in DICOM files
    end
end

theVars = {
    'dicomTree'
    'imgRef'
    'infoRef'
    'numRefs'
    'options'
    'pathRef'
    'refUid'
    'specPath'
    'spec'
    'spectraUid'
    };

for vardx=1:numel(theVars)
    data.(theVars{vardx}) = eval(theVars{vardx});
end
