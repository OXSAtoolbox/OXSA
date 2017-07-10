function plotMrSpectra_rephaseHelper(hObject, eventData)

% eventData.Indices holds the lines which are selected

% Find the panel figure handle
hFig = hObject;
while ~isempty(hFig) && ~strcmp('figure', get(hFig,'type'))
    hFig = get(hFig,'parent');
end

% Get the parent figure, containing the spectra
hParentFig = get(hFig,'userdata');

% Load guidata
data = guidata(hParentFig);

data.currLines = false(size(data.hLines,1),1);
data.currLines(eventData.Indices(:,1)) = 1;

set(data.hLines(data.currLines,:),'selected','on')
set(data.hLines(~data.currLines,:),'selected','off')

if ~isfield(data,'oldCursor')
    data.oldCursor = get(hParentFig,'Pointer');
    data.oldCursorCData = get(hParentFig,'PointerShapeCData');
    data.oldCursorHotspot = get(hParentFig,'PointerShapeHotspot');
end

set(hParentFig,'Pointer','custom','PointerShapeCData',data.phiCursor,...
    'PointerShapeHotspot',[9 9])

set(data.hAxes(1),'ButtonDownFcn',@plotMrSpectra_rephaseHelper_buttonDown);

guidata(hParentFig,data);
