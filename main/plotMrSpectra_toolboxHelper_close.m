function plotMrSpectra_toolboxHelper_close(hObject, eventData)
% Helper function - disable toolbar button if we close the child window

hMainFig = get(hObject,'userdata');

if ishandle(hMainFig) % If main figure still onscreen
    data = guidata(hMainFig);

    set(data.tth,'state','off');
    data.hPanel = [];

    guidata(hMainFig,data);
end
