function arrowKey_Callback(obj,hObject,eventData)
% Allow voxel selection with the arrow keys.

whichKey = strcmp(eventData.Key,{'uparrow','downarrow','leftarrow','rightarrow'});
if ~any(whichKey)
    return
end

crs = obj.data.spec.voxelToColRowSlice(obj.voxel);

if whichKey(1) % Up
    crs(2) = max(1, crs(2) - 1);
elseif whichKey(2) % Down
    crs(2) = min(obj.data.spec.rows, crs(2) + 1);
elseif whichKey(3) % Left
    crs(1) = max(1, crs(1) - 1);
else % Right
    crs(1) = min(obj.data.spec.columns, crs(1) + 1);
end

newVox = obj.data.spec.colRowSliceToVoxel(crs);

if obj.voxel ~= newVox
    obj.voxel = newVox;
end

end
