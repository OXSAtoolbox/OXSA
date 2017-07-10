function voxelNumberCallback(obj,sliderNVoxel)
% nVoxel slider has moved

% Force new value to be an integer.
newValue = floor(sliderNVoxel.value);

if obj.voxel ~= newValue
    obj.voxel = newValue;
end
