function refPane_reload(obj,newFileData_Data,refdx)
% Redraw a reference image pane with a new DICOM image.
%
% newFileData_Data must contain:
% newFileData_Data.SOPInstanceUID
% newFileData_Data.InstanceNumber

% TODO: This code should be gathered together in an object for each
% reference image.

    delete(get(obj.misc.panes(refdx).hCsiAxis,'Children'))
    
    obj.misc.panes(refdx).nSlice = [];
    obj.misc.panes(refdx).hImages = [];
    obj.misc.panes(refdx).geom = [];
    obj.misc.panes(refdx).hIntersectLines = [];
    obj.misc.panes(refdx).hVoxels = [];
    obj.misc.panes(refdx).hMarkImagePosition = [];

    obj.data.refUid{refdx} = newFileData_Data.SOPInstanceUID;

    obj.data.pathRef{refdx,1} = searchForUid(obj.data.dicomTree,obj.data.refUid{refdx});
    
    for refdx1=1:numel(obj.data.refUid)
        refSeries = obj.data.dicomTree.study(obj.data.pathRef{refdx1}.studyDx).series(obj.data.pathRef{refdx1}.seriesDx);
        for refdx2=1:numel(refSeries.instance)
            strRef{refdx1,1}{refdx2,1} = refSeries.instance(refdx2).Filename; %#ok<AGROW>
        end
    end
    
    % Preallocate in case no data files for a reference image were found
    obj.data.infoRef{refdx,1} = cell(numel(strRef{refdx}),1);
    obj.data.imgRef{refdx,1} = cell(numel(strRef{refdx}),1);
    for refdx2=1:numel(strRef{refdx})
        obj.data.infoRef{refdx}{refdx2}=dicominfo(strRef{refdx}{refdx2});
        obj.data.imgRef{refdx}{refdx2}=myDicomRead(obj.data.infoRef{refdx}{refdx2}); % Don't swap row/col in DICOM files
    end

    obj.misc.panes(refdx).nSlice = newFileData_Data.InstanceNumber;

    axes(obj.misc.panes(refdx).hCsiAxis);
    for refdx2=1:numel(obj.data.imgRef{refdx})
        obj.misc.panes(refdx).hImages(refdx2) = ...
            obj.impatch2d(obj.data.imgRef{refdx}{refdx2},...
            obj.data.infoRef{refdx}{refdx2}.PixelSpacing);
        
        if refdx2~=obj.misc.panes(refdx).nSlice
            set(obj.misc.panes(refdx).hImages(refdx2),'Visible','off')
        end
        
        set(obj.misc.panes(refdx).hImages(refdx2),'HitTest','off');
        hold on
    end
    axis tight
    obj.projectVector_Prepare(refdx);
    
    % TODO: There is a bug when the first slice of a stack doesn't intersect
    % another reference image but other slices do. Needs to be handled better.

    % Mark intersection with other reference images a la Syngo
    for refdx1=1:obj.data.numRefs
        axes(obj.misc.panes(refdx1).hCsiAxis);
        for refdxOther=1:obj.data.numRefs
            obj.misc.panes(refdx1).hIntersectLines{refdxOther} = [];
            if refdx1 ~= refdxOther % Don't intersect with self
                for refdxOther2=1:numel(obj.data.imgRef{refdxOther})
                    try
                    obj.misc.panes(refdx1).hIntersectLines{refdxOther}(refdxOther2) ...
                        = obj.calcPlaneIntersect(obj.data.infoRef{refdx1}{1},obj.data.infoRef{refdxOther}{refdxOther2});
                    catch
                        obj.misc.panes(refdx1).hIntersectLines{refdxOther}(refdxOther2) = NaN;
                    end
                end
            end
        end
    end
    
    obj.updatePlaneIntersect()

    % Update spinner
    spinnerModel=obj.misc.panes(refdx).spinner.jhSpinner.getModel();
    spinnerModel.setMaximum(java.lang.Double(numel(strRef{refdx})));
    spinnerModel.setValue(obj.misc.panes(refdx).nSlice);
    
    % Update voxel display
    obj.csiSlice = obj.csiSlice;
    