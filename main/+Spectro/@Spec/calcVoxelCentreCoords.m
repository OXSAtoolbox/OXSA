function [fulldata] = calcVoxelCentreCoords(obj, voxel)
% Calculate coordinates of the centre of a spectroscopy voxel in the DICOM
% coordinate system.

% See calcVoxelVertexCoordsForSlice.m for details of the interpretation of
% the DICOM standard.

% Assume that indexing of spectroscopy data is [(time), COLUMN, ROW,
% slice]. This is related to whether an array is row-major or column-major.
% Matlab and C differ in this regard.

% Copyright Chris Rodgers, University of Oxford, 2008-13.
% $Id$

crs = obj.voxelToColRowSlice(voxel);

[coldata,rowdata]=ndgrid((crs(1)-0.5)*obj.pixelSpacing(2), ...
                         (crs(2)-0.5)*obj.pixelSpacing(1));

thisSliceOffset = obj.imagePositionPatient + ...
    ((crs(3)-1)*obj.sliceThickness) * obj.sliceNormal;

% Convert to 3D
fulldata=[];
fulldata(1,:,:) = thisSliceOffset(1) + ...
    obj.imageOrientationPatient(1,1) * coldata + ...
    obj.imageOrientationPatient(1,2) * rowdata;

fulldata(2,:,:) = thisSliceOffset(2) + ...
    obj.imageOrientationPatient(2,1) * coldata + ...
    obj.imageOrientationPatient(2,2) * rowdata;

fulldata(3,:,:) = thisSliceOffset(3) + ...
    obj.imageOrientationPatient(3,1) * coldata + ...
    obj.imageOrientationPatient(3,2) * rowdata;
end
