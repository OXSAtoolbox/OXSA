function voxelClicked_Callback(obj,hObject,eventdata) %#ok<INUSL>

idxInSlice = get(hObject,'UserData');
obj.voxel = obj.data.spec.idxInSliceAndSliceToVoxel(idxInSlice,obj.csiSlice);
