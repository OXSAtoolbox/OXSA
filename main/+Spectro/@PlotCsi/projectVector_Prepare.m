function projectVector_Prepare(obj, refdx)
% Prepare to convert a free vector in 3D in the DICOM patient coordinate
% system into a 2D projection in the plane of the specified localizer image.

for refdx2=1:numel(obj.data.infoRef{refdx})
    thisInfo = obj.data.infoRef{refdx}{refdx2};
    thisGeom = struct();
    
    thisGeom.imageOrientationPatient = ...
        reshape(thisInfo.ImageOrientationPatient,3,2);
    thisGeom.normal = ...
        cross(thisGeom.imageOrientationPatient(:,1),...
              thisGeom.imageOrientationPatient(:,2));
    thisGeom.unitVecs = ...
        [thisGeom.imageOrientationPatient ...
        thisGeom.normal];
    
    % Store dimensions
    thisGeom.pixelSpacing = thisInfo.PixelSpacing;
    thisGeom.rows = double(thisInfo.Rows);
    thisGeom.columns = double(thisInfo.Columns);

    % Mark corner positions
    thisGeom.imagePositionPatient = ...
        thisInfo.ImagePositionPatient;
    
    thisGeom.imagePositionEndRow1 = thisGeom.imagePositionPatient...
    + thisGeom.imageOrientationPatient(:,1) * thisGeom.pixelSpacing(2) * thisGeom.columns;

    thisGeom.imagePositionEndColumn1 = thisGeom.imagePositionPatient...
    + thisGeom.imageOrientationPatient(:,2) * thisGeom.pixelSpacing(1) * thisGeom.rows;
  
    thisGeom.imagePositionFarCorner = ...
        thisGeom.imagePositionPatient + ...
        thisGeom.imageOrientationPatient(:,1) * thisGeom.pixelSpacing(2) * thisGeom.columns + ...
        thisGeom.imageOrientationPatient(:,2) * thisGeom.pixelSpacing(1) * thisGeom.rows;
    
    obj.misc.panes(refdx).geom{refdx2} = thisGeom;
end

% Check if unit vector sets are orthonormal, as they ought to be:
% maxdiff(unitVecsRef*unitVecsRef',eye(3),'unitVecsRef*unitVecsRef''',1e-12)
% maxdiff(unitVecsRef'*unitVecsRef,eye(3),'unitVecsRef''*unitVecsRef',1e-12)

% unitVecsRef' is a ROTATION MATRIX from i, j, k PATIENT COORDS to the
% coordinate system of the reference image
% (and unitVecsRef goes the other way).
