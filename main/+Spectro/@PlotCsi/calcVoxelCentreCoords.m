function position = calcVoxelCentreCoords(obj,nVoxel)
% Helper-method that calculates voxel centre coordinates for a single
% voxel.
%
% N.B. This actually calculates the entire slice, and throws away all other
% values. Efficient code should use the Spectro.Spec.calcVoxel* methods
% directly.

% Copyright Chris Rodgers, Univ Oxford, 2012.
% $Id$

if nargin < 2
    nVoxel = obj.voxel;
end

[idxInSlice, slice] = obj.data.spec.voxelToIdxInSliceAndSlice(nVoxel);

slicePositions = obj.data.spec.calcVoxelCentreCoordsForSlice(slice);

position = slicePositions(:,idxInSlice);
