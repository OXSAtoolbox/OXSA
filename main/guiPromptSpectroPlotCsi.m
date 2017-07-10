function [ret] = guiPromptSpectroPlotCsi(startDir, varargin)
% Load spectra interactively.
%
% EXAMPLE:
%
% guiPromptSpectroPlotCsi \\idea7t\data\dicom\2014-02
% 
% Or to mask PPA retrospectively:
% guiPromptSpectroPlotCsi('\\idea7t\data\dicom\2014-02','wsvdOffline',true)

% $Id$

if nargin < 1
    startDir = 'D:\Users\crodgers\Documents\TrioData';
end

options = processVarargin(varargin{:});

if isfield(options,'debug') && options.debug
    bDebug = true;
else
    bDebug = false;
end

% Enable several options that would be by default off for simplicity.
if isfield(options,'clinicianMode')
    options.clinicianMode = trueFalse_interpretChar(options.clinicianMode);
else
    options.clinicianMode = false;
end

% Only allow loading to check data is OK.
if isfield(options,'viewOnlyMode')
    options.viewOnlyMode = trueFalse_interpretChar(options.viewOnlyMode);
else
    options.viewOnlyMode = false;
end

% Scan folders recursively in Spectro.dicomTree.
if isfield(options,'recursive')
    options.recursive = trueFalse_interpretChar(options.recursive);
else
    options.recursive = false;
end

if ~exist(startDir,'dir')
    error('Requested directory does not exist.')
end

% Check code is on path
if ~exist('ProcessLong31pSpectra','file')
    addpath(fullfile(RodgersSpectroToolsRoot(),'main'))
end

% Show DICOM folder tree
ret.h = Spectro.FileOpenGui(startDir,[],[],options.recursive);

% Handle data loading...
while isvalid(ret.h)
    thisData = ret.h.waitForItemChosen();
    
    if isempty(thisData)
        % Clean up if user closes GUI
        break
    end
    
    if any(strcmp(thisData.Type,{'Folder','Study'}))
        % Selecting a folder won't work so try again!
        disp('Please select a DICOM series or instance.')
        continue
    end

    try
    % Load the relevant data
    if strcmp(thisData.Type,'Series')
        % theDicomPath = fileparts(thisData.Data.instance(1).Filename);
        % identifyDicomFilesInDir(theDicomPath); % Run this to check which files wanted below.
        spectraUid = thisData.Data.SeriesInstanceUID;
        fprintf('\n\nLoading SERIES spectra <a href="matlab:clipboard(''copy'',''%s'')">%s</a> from <a href="matlab:clipboard(''copy'',''%s'')">%s</a>...\n\n',spectraUid,spectraUid,thisData.dicomTree.path,thisData.dicomTree.path);
    else
        % theDicomPath = fileparts(thisData.Data.Filename);
        spectraUid = {thisData.Data.SOPInstanceUID};
        fprintf('\n\nLoading INSTANCE spectra <a href="matlab:clipboard(''copy'',''%s'')">%s</a> from <a href="matlab:clipboard(''copy'',''%s'')">%s</a>...\n\n',spectraUid{1},spectraUid{1},thisData.dicomTree.path,thisData.dicomTree.path);
    end        
    
    waitObj = autoWaitCursor(ret.h.hFig); %#ok<NASGU>
   
    % AZL ED8CH data set...
%     dt = Spectro.dicomTree('dir','\\ideapc\dicom\2014-07\20140715_C08_01_091_AZL_ED8CH')    
%     refUid = {dt.searchForSeriesInstanceNumber(3,1,'return','instance').SOPInstanceUID,dt.searchForSeriesInstanceNumber(4,1,'return','instance').SOPInstanceUID,dt.searchForSeriesInstanceNumber(6,1,'return','instance').SOPInstanceUID}
%     ret.obj = ProcessLong31pSpectra(theDicomPath, spectraUid,refUid,options);

    ret.obj = ProcessLong31pSpectra(thisData.dicomTree, spectraUid,[],options);

    % Handle offline WSVD combination if requested
    if isfield(options,'wsvdOffline') && trueFalse_interpretChar(options.wsvdOffline)
       % Prompt for the appropriate PPA mask
       maskPpa = reshape(str2double(inputdlg({['WSVD MASK (exclude points in spectrum)' char(10) 'PRESS ESC ESC OR CLICK CANCEL TO INCLUDE ALL DATA.' char(10) char(10) 'minimum / ppm'],'maximum / ppm'},'guiPromptSpectroPlotCsi',1,{'15','Inf'})),1,[]);
       
       % Perform offline WSVD recon
       offlineReconed = wsvdOffline(ret.obj,'maskPpa',maskPpa);
       
       % Reshape the retroReconed data
       newInstNames = {'Offline No PPA WSVD'};
       
       newSpecArray = {reshape(offlineReconed.svdRecombination,size(ret.obj.data.spec.spectra{1}))};
       
       % Add the new stuff to the original ret.obj
       customReconSpec = Spectro.CustomReconSpec(ret.obj.data.spec.info);
       
       customReconSpec.setCustomSpectra('newSpec',newSpecArray,...
           'newName',newInstNames);
       
       % Override into the GUI...
       ret.obj.setCustomReconSpec(customReconSpec);
    end
    
    
    if isfield(options,'clinicianMode') && options.clinicianMode % Enable several options that would be by default off.
        for refdx = 1:numel(ret.obj.misc.panes)
            % Enable the auto CSI slice selection
            set(ret.obj.misc.panes(refdx).refMenu.autoCsiSlice,'checked','on');
            ret.obj.misc.panes(refdx).autoUpdate = true;
            
            % Enable the contrast spinners
            set(ret.obj.misc.panes(refdx).refMenu.adjContrast,'checked','on');
            set(ret.obj.misc.panes(refdx).contrast_spinnerB.jhSpinnerComponent,'visible','on')
            set(ret.obj.misc.panes(refdx).contrast_spinnerA.jhSpinnerComponent,'visible','on')
            ret.obj.plotCSI_contrastCallback([],[],refdx)
            
        end
        
        %Half voxel shift on by defualt
        set(ret.obj.menu.halfVoxelShift,'Checked','on')
        % Shift by half a voxel in the "slice" direction
        ret.obj.csiShift = [0 0 -0.5]; % The minus shifts towards the apex (usually).
        
        % Force update of reference image planes and any plotted spectra.
        ret.obj.voxel = ret.obj.voxel;
        
        % Grey out unecessary buttons
        set(ret.obj.handles.quickPlotSpec,'Enable','off');
        set(ret.obj.handles.quickPlotFid,'Enable','off');
        set(ret.obj.handles.debugBreak,'Enable','off');
    end
    
    if isfield(options,'viewOnlyMode') && trueFalse_interpretChar(options.viewOnlyMode) % Only allow loading to check data is OK.
        for refdx = 1:numel(ret.obj.misc.panes)
            % Enable the auto CSI slice selection
            set(ret.obj.misc.panes(refdx).refMenu.autoCsiSlice,'checked','on');
            ret.obj.misc.panes(refdx).autoUpdate = true;
            
            % Enable the contrast spinners
            set(ret.obj.misc.panes(refdx).refMenu.adjContrast,'checked','on');
            set(ret.obj.misc.panes(refdx).contrast_spinnerB.jhSpinnerComponent,'visible','on')
            set(ret.obj.misc.panes(refdx).contrast_spinnerA.jhSpinnerComponent,'visible','on')
            ret.obj.plotCSI_contrastCallback([],[],refdx)
            
        end
        
        %Half voxel shift on by defualt
        set(ret.obj.menu.halfVoxelShift,'Checked','on')
        % Shift by half a voxel in the "slice" direction
        ret.obj.csiShift = [0 0 -0.5]; % The minus shifts towards the apex (usually).
        
        % Force update of reference image planes and any plotted spectra.
        ret.obj.voxel = ret.obj.voxel;
        
        % Hide unnecessary buttons
        delete(ret.obj.handles.quickFit);
        delete(ret.obj.handles.quickPlotSpec);
        delete(ret.obj.handles.quickPlotFid);
        delete(ret.obj.handles.debugBreak);
%         delete(ret.obj.handles.processVoxel31P.ui);
%         delete(ret.obj.handles.roughMap.ui);
%         delete(ret.obj.handles.roughMapFreq.ui);
%         delete(ret.obj.handles.metaboliteMap.ui);

        % Hide unnecessary menu items
%         delete(ret.obj.handles.menu31p.processVoxel31P)
%         delete(ret.obj.handles.menu31p.metaboliteMap)
        delete(ret.obj.menu.quickFit)
    end
    
    clear waitObj;
    
    % Close figure now
    delete(ret.h)
    catch ME
        disp('Caught error loading')
        fprintf('%s',getReport(ME))
        
        if bDebug
            rethrow(ME)
        end
    end
end

try
    delete(ret.h);
catch
end

if exist('ret','var') && isfield(ret,'obj')
    fprintf('Setting obj in the base workspace to current GUI object...\n')
    assignin('base','obj',ret.obj)
elseif nargout < 1
    clear ret
end

disp('Done!')
