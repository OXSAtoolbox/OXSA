function [fulldata] = calcVoxelCentreCoordsForSlice(obj, slice)
% Calculate coordinates of the centres of the voxels in the
% DICOM coordinate system for the specified slice.
%
% Slice indexing is from 1 --> #slices.

% See calcVoxelVertexCoordsForSlice.m for details of the interpretation of
% the DICOM standard.

% Copyright Chris Rodgers, University of Oxford, 2008-12.
% $Id$

if nargin < 2
    error('Slice must be specified.')
end

if slice ~= 1
    error('Slice selection NOT YET TESTED!')
    % TODO: Test loading a volumetric DICOM file.
end

[coldata,rowdata]=ndgrid((0.5:double(obj.info{1}.Columns)-0.5)*obj.info{1}.PixelSpacing(2), ...
                         (0.5:double(obj.info{1}.Rows)-0.5   )*obj.info{1}.PixelSpacing(1));

thisSliceOffset = obj.imagePositionPatient + ...
    ((slice-1)*obj.info{1}.SliceThickness) * obj.sliceNormal;

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
