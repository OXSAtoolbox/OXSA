function [h] = plot(obj,varargin)
% Plot a DICOM image in 3D using the DICOM coordinate system.
%
% OPTIONS may be passed as key-value pairs, or a struct.
%
% shading: "interp" or "flat" (default).
% norm: true (normalise) or false (plot as-is, default).

% TODO: This function needs the ability to specify the axis into which to
%       plot.
% TODO: Use an improved version of mypcolour2() instead of surf().

% N.B. See help for calcVoxelCentreCoordsForSlice() method to understand
% the coordinate system defined in the DICOM standard.

% Copyright Chris Rodgers, University of Oxford, 2008-12.
% $Id$

% Read options from varargin
options = processVarargin(varargin{:});

% Normalise if required
myData = double(obj.image);
if isfield(options,'norm') && options.norm
    myData = Spectro.dicomImage.normalizeMinMax(myData);
end

if isfield(options,'shading') && strcmpi(options.shading,'interp')
    coordsDicom = obj.calcVoxelCentreCoordsForSlice(1);
    hTmp = surf(squeeze(coordsDicom(1,:,:)),squeeze(coordsDicom(2,:,:)),squeeze(coordsDicom(3,:,:)),myData);
    set(hTmp,'EdgeAlpha',0,'FaceColor','interp')
else
    coordsDicom = obj.calcVoxelInPlaneVertexCoordsForSlice(1);
    hTmp = surf(squeeze(coordsDicom(1,:,:)),squeeze(coordsDicom(2,:,:)),squeeze(coordsDicom(3,:,:)),myData);
    set(hTmp,'EdgeAlpha',0,'FaceColor','flat')
end

axis equal vis3d

if nargout > 0
    h = hTmp;
end