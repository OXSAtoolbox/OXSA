function [fulldata] = calcVoxelVertexCoordsForSlice(obj, slice)
% Calculate coordinates of the vertices of the voxels in the
% DICOM coordinate system for the specified slice.
%
% Slice indexing is from 1 --> obj.slices.

% Copyright Chris Rodgers, University of Oxford, 2008-12.
% $Id$

if nargin < 2
    error('Slice must be specified.')
end

if slice ~= 1
    error('Slice selection NOT YET TESTED!')
    % TODO: Test loading a volumetric DICOM file.
end

%% Interpretation of DICOM standard
%
% I am not sure whether the DICOM standard intends (row,col) or (col,row)
% indicies for images, nor whether these begin with voxel (0,0) or (1,1).
% See my posting at 23:15 on 8 June 2010 to comp.protocols.dicom for
% further information.
%
% *************************************************************************
%
% Dear All,
%
% How should I reconcile the definitions of image coordinates in the "Pixel Data" and "Image Position and Image Orientation" sections of the 2009 DICOM standard?
%
% "Pixel Data" says that the pixels are labelled:
%
% (1,1)  (1,2)  (1,3)  (1,4)  etc.
% (2,1)  (2,2)  (2,3)  (2,4)  etc.
% etc.
%
% i.e. (row starting at 1, column starting at 1)
%
% But the formula on the "Image Position And Image Orientation" section it say is said to determine "The mapping of pixel location (i, j)" but WHERE i Column index to the image plane. The first column is index zero. and j Row index to the image plane. The first row index is zero.
%
% Should the image data be considered to be indexed from 0 or from 1?
%
% Should the pixel coordinates (i,j) be (row, col) or (col, row)?
%
% Many thanks,
%
% Dr Chris Rodgers
% University of Oxford.
%
%
% -- QUOTE from the standard --
% ftp://medical.nema.org/medical/dicom/2009/09_03pu3.pdf
%
% C.7.6.3.1.4 Pixel Data
% Pixel Data (7FE0,0010) for this image. The order of pixels sent for each image plane is left to
% right, top to bottom, i.e., the upper left pixel (labeled 1,1) is sent first followed by the remainder of
% row 1, followed by the first pixel of row 2 (labeled 2,1) then the remainder of row 2 and so on.
% For multi-plane images see Planar Configuration (0028,0006) in this Section.
%
% C.7.6.2.1.1 Image Position And Image Orientation
%
% ...
% The Image Plane Attributes, in conjunction with the Pixel Spacing Attribute, describe the position
% and orientation of the image slices relative to the patient-based coordinate system. In each image
% frame the Image Position (Patient) (0020,0032) specifies the origin of the image with respect to
% the patient-based coordinate system. RCS and the Image Orientation (Patient) (0020,0037)
% attribute values specify the orientation of the image frame rows and columns. The mapping of
% pixel location (i, j) to the RCS is calculated as follows:
%
% <FORMULA>
%
% Where:
% Pxyz The coordinates of the voxel (i,j) in the frame’s image plane in units of mm.
% Sxyz The three values of the Image Position (Patient) (0020,0032) attributes. It is the
% location in mm from the origin of the RCS.
% Xxyz The values from the row (X) direction cosine of the Image Orientation (Patient)
% (0020,0037) attribute.
% Yxyz The values from the column (Y) direction cosine of the Image Orientation (Patient)
% (0020,0037) attribute.
% i Column index to the image plane. The first column is index zero.
% ?i Column pixel resolution of the Pixel Spacing (0028,0030) attribute in units of mm.
% j Row index to the image plane. The first row index is zero.
% ?j Row pixel resolution of the Pixel Spacing (0028,0030) attribute in units of mm."
%
% *************************************************************************

%% Now perform the calculation

[coldata,rowdata]=ndgrid((0:double(obj.info{1}.Columns))*obj.info{1}.PixelSpacing(2), ...
                         (0:double(obj.info{1}.Rows)   )*obj.info{1}.PixelSpacing(1));

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

fulldata=repmat(fulldata,[1,1,1,2]);

fulldata(:,:,:,1) = fulldata(:,:,:,1) + repmat(0.5*obj.info{1}.SliceThickness*obj.sliceNormal,[1,obj.info{1}.Columns+1,obj.info{1}.Rows+1,1]);
fulldata(:,:,:,2) = fulldata(:,:,:,2) - repmat(0.5*obj.info{1}.SliceThickness*obj.sliceNormal,[1,obj.info{1}.Columns+1,obj.info{1}.Rows+1,1]);
end
