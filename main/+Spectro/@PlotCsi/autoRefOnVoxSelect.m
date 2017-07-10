function autoRefOnVoxSelect(obj,refdx1,newVoxel)

% for each of the reference slices calculate the center of voxel distance to
% the plane, but only if there are multiple slices!
voxelCentre = obj.data.spec.calcVoxelCentreCoords(newVoxel);

if numel(obj.misc.panes(refdx1).geom) > 1
    for refdx2 = 1:numel(obj.misc.panes(refdx1).geom)
        absDistance(refdx2) = abs(norm(dot(obj.misc.panes(refdx1).geom{refdx2}.normal,(obj.misc.panes(refdx1).geom{refdx2}.imagePositionPatient-voxelCentre))));
    end
    
    [~,sliceToShow] = min(absDistance);
    
    if obj.debug && obj.misc.panes(refdx1).nSlice ~= sliceToShow
        fprintf('Setting image %d, slice %d to visible\n',refdx1,sliceToShow)
    end
    
  

  % Update the spinner, this stops the spinner still registering the old
  % value even when the image has been updated.
   %Disable the callback temporarily, this obviously stops the image being
   %updated but stops the autoCSISliceOnRefSelect function getting vcalled
   %by refCallback.m
    tmpCallbackfunc = get(obj.misc.panes(refdx1).spinner.jhSpinner,'StateChangedCallback');
    set(obj.misc.panes(refdx1).spinner.jhSpinner,'StateChangedCallback',{});
    
    % Update spinner value.
    obj.misc.panes(refdx1).spinner.jhSpinner.setValue(sliceToShow); 
    
    % Reenable callback
    set(obj.misc.panes(refdx1).spinner.jhSpinner,'StateChangedCallback',tmpCallbackfunc);

    %Update the image

    set(obj.misc.panes(refdx1).hImages,'Visible','off');
    set(obj.misc.panes(refdx1).hImages(sliceToShow),'Visible','on')
    
    obj.misc.panes(refdx1).nSlice = sliceToShow;
    
    % Update the plotted intersections
    obj.updatePlaneIntersect()
    
    % Fire event for listening client code
    notify(obj,'ReferenceSliceChange',Spectro.ReferenceSliceChangeData(obj,refdx1,sliceToShow))
    
  
    
end

        
        
     
