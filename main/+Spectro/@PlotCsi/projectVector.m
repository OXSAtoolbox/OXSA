function [projVec, projVecInPlane, projVecPerp] = projectVector(obj,refdx,refdx2,inputVec,strType)
% Convert one or more free vectors in 3D in the DICOM patient coordinate
% system into a 2D projection in the plane of the specified localizer image

if numel(size(inputVec)) ~= 2 || size(inputVec,1) ~= 3
    error('inputVec must be a 3 x n matrix.')
end

if nargin >= 3 && strcmpi(strType,'position')
    projVec = obj.misc.panes(refdx).geom{refdx2}.unitVecs'...
        *bsxfun(@minus,...
                inputVec,...
                obj.data.infoRef{refdx}{refdx2}.ImagePositionPatient);
elseif nargin >= 3 && strcmpi(strType,'free')
    projVec = obj.misc.panes(refdx).geom{refdx2}.unitVecs'*inputVec;
else
    error('Unknown vector type: must be ''position'' or ''free''.')
end

% Split up into in-plane and out-of-plane components if desired
if nargout > 1
	projVecInPlane = [projVec(1,:);
                      projVec(2,:);
                      zeros(1,size(projVec,2))];
    projVecPerp = projVec(3,:);
end
