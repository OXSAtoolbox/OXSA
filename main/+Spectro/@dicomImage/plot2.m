function [h] = plot2(obj,varargin)
% Display image as a surface in 2D.
%
% TODO: This function should be replaced with a general-purpose piece of
% code that projects from 3D into an arbitrary plane.

options = processVarargin(varargin{:});

% Normalise if required
myData = double(obj.image);
if isfield(options,'norm') && options.norm
    myData = Spectro.dicomImage.normalizeMinMax(myData);
end

warning('2D plot code not yet complete - needs to project into specified plane.')

pixelSpacing = obj.info{1}.PixelSpacing;

% Allow interpolation
if isfield(options,'interpolateFactor')
    pixelSpacing = pixelSpacing / options.interpolateFactor;
    myData = kron(myData,ones(options.interpolateFactor));
end

[rowdata,coldata]=ndgrid([-0.5:(size(myData,1)-0.5)]*pixelSpacing(2),[-0.5:(size(myData,2)-0.5)]*pixelSpacing(1));

% The -ve z position is a work-around for a Matlab bug that can give
% problems plotting over the top of a 2D image like this.
hTmp = surf(rowdata,coldata,repmat(-max(size(myData)),size(coldata)),myData);
view(2)

shading flat

set(gca,'DataAspectRatio',[1 1 1])
set(gca,'Visible','off')
set(gca,'YDir','rev')

colormap(gray)

if nargout>0
    h = hTmp;
end
