function drawSatBands(obj)
% Draw sat band on the localiser image

% Read RSat geometry from the protocol

rsatNum = obj.data.spec.getMrProtocolNumber('sRSatArray.lSize');

for rsatDx = 1:rsatNum
    rsat(rsatDx).position = [...
        obj.data.spec.getMrProtocolNumber(sprintf('sRSatArray.asElm[%d].sPosition.dSag',rsatDx-1));...
        obj.data.spec.getMrProtocolNumber(sprintf('sRSatArray.asElm[%d].sPosition.dCor',rsatDx-1));...
        obj.data.spec.getMrProtocolNumber(sprintf('sRSatArray.asElm[%d].sPosition.dTra',rsatDx-1))];
    
    rsat(rsatDx).normal = [...
        obj.data.spec.getMrProtocolNumber(sprintf('sRSatArray.asElm[%d].sNormal.dSag',rsatDx-1));...
        obj.data.spec.getMrProtocolNumber(sprintf('sRSatArray.asElm[%d].sNormal.dCor',rsatDx-1));...
        obj.data.spec.getMrProtocolNumber(sprintf('sRSatArray.asElm[%d].sNormal.dTra',rsatDx-1))];
    
    rsat(rsatDx).thickness = obj.data.spec.getMrProtocolNumber(sprintf('sRSatArray.asElm[%d].dThickness',rsatDx-1));
end

%% Mark intersection of saturation band with displayed reference images
for refdx=1:obj.data.numRefs
    axes(obj.misc.panes(refdx).hCsiAxis);
    
    % Clear existing RSat lines
    delete(findobj(obj.misc.panes(refdx).hCsiAxis,'Tag','RSat'))
    
    % Now calculate and plot new lines
    infoRef = obj.data.infoRef{refdx}{obj.misc.panes(refdx).nSlice};

    % Ref is the plane of the image on screen. Rectangle.
    ref_geom = obj.misc.panes(refdx).geom{obj.misc.panes(refdx).nSlice};
    
    for rsatDx=1:rsatNum
        %% Calculate the intersection of two planes.
        % Plane 2 is the RSat. Infinite extent.
        rsat_geom = rsat(rsatDx);
        
        % Test for parallel planes
        if norm(cross(ref_geom.normal,rsat_geom.normal)) < 1e-14
            warning('Spectro:PlotCsi:calcPlaneIntersect','Parallel sat band. Cannot yet plot intersection.')
            
            hLine = NaN;
            pointOnLine = [];
            directionVector = [];
            
            continue
        end
        
        % unitVecs' is a ROTATION MATRIX from i, j, k PATIENT COORDS to the
        % coordinate system of the reference image
        % (and unitVecs goes the other way).
        
        ref_geom.RotMatrix = ref_geom.unitVecs';
        
        minusPRef = dot(ref_geom.normal, ref_geom.imagePositionPatient);
        minusP2 = dot(rsat_geom.normal, rsat_geom.position);

        minusP2 = minusP2 - rsat_geom.thickness / 2; % Show edges of sat band not centre
        
        % Calculate direction vector along line of intersection
        directionVector = null([ref_geom.normal rsat_geom.normal]');
        directionVectorProjected = ref_geom.RotMatrix*directionVector;
        
        % Calculate a point on the (extension of the) line of intersection
        pointOnLine = [ref_geom.normal rsat_geom.normal]' \ [minusPRef; minusP2];
        pointOnLineProjected = ref_geom.RotMatrix*(pointOnLine - infoRef.ImagePositionPatient);
        
        % % Check commonPoint is in both planes
        % maxdiff(dot(normalRef,pointOnLine),minusPRef)
        % maxdiff(dot(normal2,pointOnLine),minusP2)
        
        %% Find the start and end of this line, by seeing whether/where it
        %% intersects the four sides of the displayed reference image rectangle.
        
        % We will do this calculation in the projected plane to make it a 2D rather
        % than full 3D geometric problem.
        
        % TODO: I'm sure these don't need calculating like this... They are just
        % pixelspace .* [rows columns] or something like that.
        cornerOrigin_InPlane = ref_geom.unitVecs'*(ref_geom.imagePositionPatient - ref_geom.imagePositionPatient);
        cornerEndRow1_InPlane = ref_geom.unitVecs'*(ref_geom.imagePositionEndRow1 - ref_geom.imagePositionPatient);
        cornerEndColumn1_InPlane = ref_geom.unitVecs'*(ref_geom.imagePositionEndColumn1 - ref_geom.imagePositionPatient);
        cornerFar_InPlane = ref_geom.unitVecs'*(ref_geom.imagePositionFarCorner - ref_geom.imagePositionPatient);
        
        res{1} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected,directionVectorProjected,cornerOrigin_InPlane,cornerEndRow1_InPlane);
        res{2} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected,directionVectorProjected,cornerOrigin_InPlane,cornerEndColumn1_InPlane);
        res{3} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected,directionVectorProjected,cornerEndRow1_InPlane,cornerFar_InPlane);
        res{4} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected,directionVectorProjected,cornerEndColumn1_InPlane,cornerFar_InPlane);
        
        lineEnds = zeros(3,0);
        for idx=1:4
            lineEnds = [lineEnds res{idx}.points]; %#ok<AGROW>
        end
        
        %% Now calculate for the other side of the sat band
        minusP2_plus = dot(rsat_geom.normal, rsat_geom.position) + rsat_geom.thickness / 2;
        
        % Calculate a point on the (extension of the) line of intersection
        pointOnLine_plus = [ref_geom.normal rsat_geom.normal]' \ [minusPRef; minusP2_plus];
        pointOnLineProjected_plus = ref_geom.RotMatrix*(pointOnLine_plus - infoRef.ImagePositionPatient);

        res_plus{1} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected_plus,directionVectorProjected,cornerOrigin_InPlane,cornerEndRow1_InPlane);
        res_plus{2} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected_plus,directionVectorProjected,cornerOrigin_InPlane,cornerEndColumn1_InPlane);
        res_plus{3} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected_plus,directionVectorProjected,cornerEndRow1_InPlane,cornerFar_InPlane);
        res_plus{4} = Spectro.PlotCsi.intersectLineAndLineSegment(pointOnLineProjected_plus,directionVectorProjected,cornerEndColumn1_InPlane,cornerFar_InPlane);
        
        lineEnds_plus = zeros(3,0);
        for idx=1:4
            lineEnds_plus = [lineEnds_plus res_plus{idx}.points]; %#ok<AGROW>
        end
        
        %% Check whether any vertices are included
        inRegion = @(x) sign(dot(x - pointOnLineProjected, cross(directionVectorProjected,[0 0 1]))) ~= sign(dot(x - pointOnLineProjected_plus, cross(directionVectorProjected,[0 0 1])));
        
        allPts = [lineEnds lineEnds_plus];
        if inRegion(cornerOrigin_InPlane)
            allPts(:,end+1) = cornerOrigin_InPlane;
        end
        if inRegion(cornerEndRow1_InPlane)
            allPts(:,end+1) = cornerEndRow1_InPlane;
        end
        if inRegion(cornerEndColumn1_InPlane)
            allPts(:,end+1) = cornerEndColumn1_InPlane;
        end
        if inRegion(cornerFar_InPlane)
            allPts(:,end+1) = cornerFar_InPlane;
        end
        
        allPts = allPts(1:2,:);
        allPtsDx = convhull(allPts.');
        
        allPts = allPts(:,allPtsDx);
        
        %% Special handling for Matlab R2014b to prevent clicking on the patch
        if verLessThan('matlab','8.4')
            hitTestProp = {'HitTest','off'};
        else
            hitTestProp = {'HitTest','off','PickableParts','none'};
        end
        
        %% Plot all
        hold on
        hPatch = patch(allPts(1,:),allPts(2,:),[1 1 0],'FaceAlpha',0.2,'Tag','RSat',hitTestProp{:},'UserData',rsatDx);
        
        hLine = line(lineEnds(1,:),lineEnds(2,:));
        set(hLine,'xliminclude','off','yliminclude','off','Color',[1 1 0],'Tag','RSat',hitTestProp{:},'UserData',rsatDx)
        
        hLine_plus = line(lineEnds_plus(1,:),lineEnds_plus(2,:));
        set(hLine_plus,'xliminclude','off','yliminclude','off','Color',[1 1 0],'Tag','RSat',hitTestProp{:},'UserData',rsatDx)
    end
end
