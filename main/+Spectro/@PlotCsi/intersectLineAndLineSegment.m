function [isect] = intersectLineAndLineSegment(x0,xL,rA,rB)
% Check whether a line and a line segment overlap in 2D
%
% x0 - point on line
% xL - line UNIT direction vector
% rA - end of segment
% rB - other end of segment

% Sanity checks - may be disabled for speed later
if abs(norm(xL)-1) > 1e-10
    error('xL is not normalised')
end

if abs(dot(xL,cross((rA-x0),(rB-x0)))) > 1e-9
    error('x0, x0 + xL, rA and rB must be coplanar for intersection')
end

perpVec = cross(xL,(rB-rA));

if norm(perpVec) < 1e-10
    % Either rA==rB or the line and line-segment are parallel
    
    % Are we colinear?
    if norm(cross((rA-x0),xL)) >= 1e-10
%         disp('no intersection')
        isect.status = 0; % NO INTERSECT
        isect.points = zeros(3,0);
    else
        % We are colinear
        if norm(rA-rB) < 1e-10
            isect.status = 1; % POINT INTERSECTION
            isect.points = rA;
        else
%             disp('colinear')
            isect.status = 2; % COLINEAR
            
            isect.points = [rA rB];
        end
    end
else % Not parallel
    h = dot((x0 - rA),cross(xL,perpVec)) / dot((rB - rA),cross(xL,perpVec));
    
    if h>0 && h<1 % Don't count if line goes through just rA or rB
        isect.status = 1; % POINT INTERSECTION
        isect.points = rA + h*(rB-rA);
    else
        isect.status = 0; % NO INTERSECT
        isect.points = zeros(3,0);
    end
end
end
