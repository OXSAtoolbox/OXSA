function plotMrSpectra_toolboxHelper_off(hObject, eventData)

% Find the parent figure in which the toolbar button lay
hFig = hObject;
while ~isempty(hFig) && ~strcmp('figure', get(hFig,'type'))
    hFig = get(hFig,'parent');
end

% Retrieve the GUI data
data = guidata(hObject);
if isempty(data)
    data = struct();
end

try
    delete(data.hPanel);
catch
end
data.hPanel=[];

if isfield(data, 'oldCursorCData')
    set(gcf,'PointerShapeCData',data.oldCursorCData,'PointerShapeHotspot',data.oldCursorHotspot);
    set(gcf,'Pointer',data.oldCursor);
end

set(data.hLines,'selected','off')

% Save the GUI data
guidata(hObject,data);

end
