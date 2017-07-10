function refCmdButton_Load(obj,hObject,eventdata,refdx)
    disp('refCmdButton_Load')

    autoObj = autoWaitCursor(obj.handles.mainWindow); %#ok<NASGU>
    
    h = Spectro.FileOpenGui(obj.data.dicomTree.path, false, 'Select new reference image');
    h.hTree.setSelection(obj.data.dicomTree.path, obj.data.refUid{refdx});
    
    newFileData = struct('Type','NULL');
    while ~isempty(newFileData) && ~any(strcmp(newFileData.Type,{'Instance','Series'}))
        newFileData = h.waitForItemChosen;
    end
    
    % Close GUI dialog
    delete(h);
    drawnow
    
    if isempty(newFileData)
        % User aborted
        return
    end
    
    %% Now redraw the reference image
    if strcmp(newFileData.Type,'Series')
        % Load first image in series
        obj.refPane_reload(newFileData.Data.instance(1),refdx);
    else
        % Or load the specified image
        obj.refPane_reload(newFileData.Data,refdx);
    end
end
