function [hLine, pointOnLine, directionVector] = calcPlaneIntersect(infoRef,info2)
% Calculate the intersection of two planes.

% Copyright Chris Rodgers, University of Oxford, 2010-11.
% $Id: calcPlaneIntersect.m 4257 2011-05-26 13:46:34Z crodgers $

imageOrientationPatientRef = reshape(infoRef.ImageOrientationPatient,3,2);
imageOrientationPatient2 = reshape(info2.ImageOrientationPatient,3,2);

normalRef = cross(imageOrientationPatientRef(:,1),imageOrientationPatientRef(:,2));
normal2 = cross(imageOrientationPatient2(:,1),imageOrientationPatient2(:,2));

% Test for parallel planes
if norm(cross(normalRef,normal2)) < 1e-14
    warning('Spectro:PlotCsi:calcPlaneIntersect','Parallel reference planes. Cannot plot line of intersection.')
    
    hLine = NaN;
    pointOnLine = [];
    directionVector = [];
    
    return
end

unitVecsRef = [imageOrientationPatientRef normalRef];
% unitVecs2 = [imageOrientationPatient2 normal2];

% % Check if unit vector sets are orthonormal, as they ought to be:
% maxdiff(  unitVecsRef*unitVecsRef',eye(3),'values',1e-12);
% maxdiff(  unitVecsRef'*unitVecsRef,eye(3),'values',1e-12);
% maxdiff(  unitVecs2*unitVecs2',eye(3),'values',1e-12);
% maxdiff(  unitVecs2'*unitVecs2,eye(3),'values',1e-12);

% unitVecsRef' is a ROTATION MATRIX from i, j, k PATIENT COORDS to the
% coordinate system of the reference image
% (and unitVecsRef goes the other way).

RotMatrix = unitVecsRef';

minusPRef = dot(normalRef, infoRef.ImagePositionPatient);
minusP2 = dot(normal2, info2.ImagePositionPatient);

% Calculate direction vector along line of intersection
directionVector = null([normalRef normal2]');
directionVectorProjected = RotMatrix*directionVector;

% Calculate a point on the (extension of the) line of intersection
pointOnLine = [normalRef normal2]' \ [minusPRef; minusP2];
pointOnLineProjected = RotMatrix*(pointOnLine - infoRef.ImagePositionPatient);

% % Check commonPoint is in both planes
% maxdiff(dot(normalRef,pointOnLine),minusPRef)
% maxdiff(dot(normal2,pointOnLine),minusP2)

%% Find the start and end of this line, by seeing whether/where it
%% intersects the four sides of the info2 image plane.

% We will do this calculation in the projected plane to make it a 2D rather
% than full 3D geometric problem.

cornerOrigin = info2.ImagePositionPatient;
cornerEndRow1 = info2.ImagePositionPatient...
                + imageOrientationPatient2(:,1) * info2.PixelSpacing(2) * double(info2.Columns);
cornerEndCol1 = info2.ImagePositionPatient...
                + imageOrientationPatient2(:,2) * info2.PixelSpacing(1) * double(info2.Rows);
cornerFar = info2.ImagePositionPatient...
                + imageOrientationPatient2(:,1) * info2.PixelSpacing(2) * double(info2.Columns)...
                + imageOrientationPatient2(:,2) * info2.PixelSpacing(1) * double(info2.Rows);

[tmp, cornerOrigin_InPlane] = Spectro.PlotCsi.projectVector_Raw(infoRef,cornerOrigin,'position'); %#ok<ASGLU>
[tmp, cornerEndRow1_InPlane] = Spectro.PlotCsi.projectVector_Raw(infoRef,cornerEndRow1,'position'); %#ok<ASGLU>
[tmp, cornerEndCol1_InPlane] = Spectro.PlotCsi.projectVector_Raw(infoRef,cornerEndCol1,'position'); %#ok<ASGLU>
[tmp, cornerFar_InPlane] = Spectro.PlotCsi.projectVector_Raw(infoRef,cornerFar,'position'); %#ok<ASGLU>

res{1} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected,directionVectorProjected,cornerOrigin_InPlane,cornerEndRow1_InPlane);
res{2} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected,directionVectorProjected,cornerOrigin_InPlane,cornerEndCol1_InPlane);
res{3} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected,directionVectorProjected,cornerEndRow1_InPlane,cornerFar_InPlane);
res{4} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected,directionVectorProjected,cornerEndCol1_InPlane,cornerFar_InPlane);

lineEnds = zeros(3,0);
for idx=1:4
    lineEnds = [lineEnds res{idx}.points]; %#ok<AGROW>
end

hold on
% hLine = line([transRoot(1)+10000*rotatedVector(1);...
%       transRoot(1)-10000*rotatedVector(1)],...
%      [transRoot(2)+10000*rotatedVector(2);...
%       transRoot(2)-10000*rotatedVector(2)])
hLine = line(lineEnds(1,:),lineEnds(2,:));
set(hLine,'xliminclude','off','yliminclude','off')

% TODO: There is a bug when the first slice of a stack doesn't intersect
% another reference image but other slices do. Needs to be handled better.
if isempty(hLine)
    hLine = NaN;
end
