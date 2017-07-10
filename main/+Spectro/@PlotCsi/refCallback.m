function refCallback(obj,hObject,eventdata,refdx)

nSlice = hObject.getValue;

if obj.debug
    fprintf('Setting image %d, slice %d to visible\n',refdx,nSlice)
end

set(obj.misc.panes(refdx).hImages,'Visible','off');
set(obj.misc.panes(refdx).hImages(nSlice),'Visible','on')

obj.misc.panes(refdx).nSlice = nSlice;

% Update the plotted intersections
obj.updatePlaneIntersect()

% Fire event for listening client code
notify(obj,'ReferenceSliceChange',Spectro.ReferenceSliceChangeData(obj,refdx,nSlice))

%if auto CSI is on update the csi slice as appropriate
if obj.misc.panes(refdx).autoUpdate
    obj.autoCSISliceOnRefSelect(refdx,nSlice);
end