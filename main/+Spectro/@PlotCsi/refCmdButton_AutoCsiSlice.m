function refCmdButton_AutoCsiSlice(obj,hObject,eventdata,refdx)

if strcmp(get(obj.misc.panes(refdx).refMenu.autoCsiSlice,'checked'),'off')
   set(obj.misc.panes(refdx).refMenu.autoCsiSlice,'checked','on');
   obj.misc.panes(refdx).autoUpdate = true;   
   
elseif strcmp(get(obj.misc.panes(refdx).refMenu.autoCsiSlice,'checked'),'on')
   set(obj.misc.panes(refdx).refMenu.autoCsiSlice,'checked','off');
   obj.misc.panes(refdx).autoUpdate = false;
end
   


