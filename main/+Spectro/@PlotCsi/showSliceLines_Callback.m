function showSliceLines_Callback(obj,hObject,eventData)
% Handle clicking on "Show Slice Lines" menu or the command button

if strcmp(get(hObject,'Type'),'uimenu')
    % For the menu, swap to the other value
    obj.showSliceLines = strcmp(get(hObject,'Checked'),'off');
else
    % For a togglebutton, the value is already swapped by Matlab
    obj.showSliceLines = get(hObject,'Value');
end

% The set.showSliceLines function handles updating the user interface.