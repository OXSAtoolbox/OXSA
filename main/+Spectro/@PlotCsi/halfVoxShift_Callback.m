function halfVoxShift_Callback(obj,hObject,eventData)
% Handle clicking on "Half voxel shift" menu item. Calls the property
% access method set.csiShift.

if strcmp(get(hObject,'Type'),'uimenu') && strcmp(get(hObject,'Checked'),'on'); %  Shift is currently applied, so revert to original
    set(hObject,'Checked','off') %
    % Shift to original position
 
    obj.csiShift = [0 0 0];
 
    % Force update of reference image planes and any plotted spectra.
    obj.voxel = obj.voxel;
    
elseif strcmp(get(hObject,'Type'),'uimenu') && strcmp(get(hObject,'Checked'),'off'); % Currently original position, apply shift.
    set(hObject,'Checked','on')
    % Shift by half a voxel in the "slice" direction
    obj.csiShift = [0 0 -0.5]; % The minus shifts towards the apex.
    
    % Force update of reference image planes and any plotted spectra.
    obj.voxel = obj.voxel;
    
else
    error('Called from unknown ui element')
end

