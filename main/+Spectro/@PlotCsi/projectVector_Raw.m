function [projVec, projVecInPlane, projVecPerp] = projectVector_Raw(infoRef,inputVec,strType)
% Convert a free vector in 3D in the DICOM patient coordinate system into a
% 2D projection in the plane of the specified localizer image.

imageOrientationPatientRef = reshape(infoRef.ImageOrientationPatient,3,2);
normalRef = cross(imageOrientationPatientRef(:,1),imageOrientationPatientRef(:,2));
unitVecsRef = [imageOrientationPatientRef normalRef];

% Check if unit vector sets are orthonormal, as they ought to be:
% maxdiff(unitVecsRef*unitVecsRef',eye(3),'unitVecsRef*unitVecsRef''',1e-12)
% maxdiff(unitVecsRef'*unitVecsRef,eye(3),'unitVecsRef''*unitVecsRef',1e-12)

% unitVecsRef' is a ROTATION MATRIX from i, j, k PATIENT COORDS to the
% coordinate system of the reference image
% (and unitVecsRef goes the other way).

if nargin >= 3 && strcmpi(strType,'position')
    projVec = unitVecsRef'*(inputVec - infoRef.ImagePositionPatient);
elseif nargin >= 3 && strcmpi(strType,'free')
    projVec = unitVecsRef'*inputVec;
else
    error('Unknown vector type: must be ''position'' or ''free''.')
end

% Split up into in-plane and out-of-plane components if desired
if nargout > 1
	projVecInPlane = [projVec(1);
                      projVec(2);
                      0];
    projVecPerp = projVec(3);
end
