function obj = guiLoad(dir)

if isempty(dir)
   dir = uigetdir('D:/Data/');
end

ret.h = Spectro.FileOpenGui(dir,[],[],1);
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
%         spectraUid = thisData.Data.SeriesInstanceUID;
        fprintf('\n\nLoading SERIES spectra <a href="matlab:clipboard(''copy'',''%s'')">%s</a> from <a href="matlab:clipboard(''copy'',''%s'')">%s</a>...\n\n',thisData.Data.SeriesInstanceUID,thisData.Data.SeriesInstanceUID,thisData.dicomTree.path,thisData.dicomTree.path);
    
        matched = thisData.dicomTree.search('target','series','return','series','query',@(ser,stu) isequal(ser.SeriesInstanceUID,thisData.Data.SeriesInstanceUID));

    else
        % theDicomPath = fileparts(thisData.Data.Filename);
%         spectraUid = thisData.Data.SOPInstanceUID;
        fprintf('\n\nLoading INSTANCE spectra <a href="matlab:clipboard(''copy'',''%s'')">%s</a> from <a href="matlab:clipboard(''copy'',''%s'')">%s</a>...\n\n',thisData.Data.SOPInstanceUID,thisData.Data.SOPInstanceUID,thisData.dicomTree.path,thisData.dicomTree.path);
    
        matched = thisData.dicomTree.search('target','instance','return','instance','query',@(inst,ser,stu) isequal(inst.SOPInstanceUID,thisData.Data.SOPInstanceUID));

    end        
    
    waitObj = autoWaitCursor(ret.h.hFig); %#ok<NASGU>
 
    
    
   
    
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

% dt = thisData.dicomTree;

% %     matched = dt.searchForUid(spectraUid, 0);
%     thisData.dicomTree.search('target','instance','return','instance','query',@(inst,ser,stu) inst.SOPInstanceUID == spectraUid);
%     if isempty(matched)
%         error('No matching data could be found.')
%     else
%         fprintf('Loading "%s"... \n',matched.Filename)
%         %     obj{iDx} = ProcessLong31pSpectra(dt, {matched.SOPInstanceUID});
%         
try
        obj = Spectro.Spec(matched);
catch
            obj = Spectro.dicomImage(matched);
end

        
    end