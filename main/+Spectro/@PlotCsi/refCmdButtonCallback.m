function refCmdButtonCallback(obj,hObject,eventdata,refdx)
% Show pop-up menu for localizers.

figPoint = get(hObject,'Position');
new_pt = hgconvertunits(obj.handles.mainWindow,figPoint,get(hObject,'Units'),'pixels',obj.handles.mainWindow);
set(obj.misc.panes(refdx).refMenu.menu,'Position',[new_pt(1)+new_pt(3) new_pt(2)+new_pt(4)],'Visible','on');
