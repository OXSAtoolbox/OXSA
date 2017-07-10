function autoCSISliceOnRefSelect(obj,refdx1,refdx2)

% What is the column and row of the current voxel.
voxIndicies = obj.data.spec.voxelToColRowSlice(obj.voxel);

% Get ans array of voxel numbers for the set col and row in each slice
for iDx = 1:obj.data.spec.slices
    voxelNum = obj.data.spec.colRowSliceToVoxel([voxIndicies(1) voxIndicies(2) iDx]);
    voxelCentres(:,iDx) = obj.data.spec.calcVoxelCentreCoords(voxelNum);
end

% for the current plane calculate the distance to
% the centre of each voxel.
slicePosition = obj.misc.panes(refdx1).geom{refdx2}.imagePositionPatient;
for vDx=1:size(voxelCentres,2)
    % Point to plane distance = norm.(x1-x0);
    absDistance(vDx) = abs(norm(dot(obj.misc.panes(refdx1).geom{refdx2}.normal,(voxelCentres(:,vDx)-slicePosition))));
end        

[~,sliceToSelect] = min(absDistance);

if obj.debug && sliceToSelect ~= obj.csiSlice 
    fprintf('Setting CSI slice to %i.\n',sliceToSelect)
end

obj.misc.panes(refdx1).autoUpdate = false;

obj.csiSlice = sliceToSelect;
        
obj.misc.panes(refdx1).autoUpdate = true;

