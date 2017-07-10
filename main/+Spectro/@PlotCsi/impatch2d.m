function [h] = impatch2d(img,pixelSpacing)
% Display image as a surface in 2D

% imageOrientationPatient = reshape(imageOrientationPatient,3,2);

[rowdata,coldata]=ndgrid([-0.5:(size(img,1)-0.5)]*pixelSpacing(2),[-0.5:(size(img,2)-0.5)]*pixelSpacing(1));

% % Convert to full 3D
% fullXdata = imagePositionPatient(1) + ...
%     imageOrientationPatient(1,1) * rowdata + ...
%     imageOrientationPatient(1,2) * coldata;
% 
% fullYdata = imagePositionPatient(2) + ...
%     imageOrientationPatient(2,1) * rowdata + ...
%     imageOrientationPatient(2,2) * coldata;
% 
% fullZdata = imagePositionPatient(3) + ...
%     imageOrientationPatient(3,1) * rowdata + ...
%     imageOrientationPatient(3,2) * coldata;

% hTmp = surf(coldata,rowdata,zeros(size(coldata)),double(img));
hTmp = surf(rowdata,coldata,zeros(size(coldata)),double(img));
view(2)

shading flat

% It would be nice to be able to get
% shading interp
% but that requires that we supply cdata of the same size as the zdata.
% I.e. We have to move the grid so that now VERTICES are placed at the
% locations that have the voxel values. I.e. VERTICES at (0,0), (0,1), ...
% * pixelSpacing.

set(gca,'DataAspectRatio',[1 1 1])
set(gca,'Visible','off')

colormap(gray)

% From the DICOM standard, section 3:
% C.7.6.1.1 General Image Attribute Descriptions
% C.7.6.1.1.1 Patient Orientation
% In: Documents\MRI\Siemens\DICOM\DICOM_Standard_2008\08_03pu.pdf page 314.
% The x-axis is increasing to the left hand side of the patient. The y-axis
% is increasing to the posterior side of the patient. The z-axis is
% increasing toward the head of the patient.
%
% There is a significant possibility for confusion - DICOM standard says
% counting in an image goes
%
% 1 2 3 4
% 5 6 7 8
% etc.
%
% whereas Matlab matrices go
%
% 1 3 5 7
% 2 4 6 8
% etc.
%


if nargout>0
    h = hTmp;
end
