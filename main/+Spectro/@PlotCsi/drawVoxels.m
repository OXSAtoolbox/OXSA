function drawVoxels(obj)

% oldAxis=get(obj.handles.mainWindow,'CurrentAxes');
% for refdx=1:numel(obj.misc.panes)
%     set(obj.handles.mainWindow,'CurrentAxes',obj.misc.panes(refdx).hCsiAxis);
%     obj.drawVoxels(refdx);
% end
% set(obj.handles.mainWindow,'CurrentAxes',oldAxis);

fulldataRaw = obj.data.spec.calcVoxelVertexCoordsForSlice(obj.csiSlice);

for refdx=1:numel(obj.misc.panes)
% Project into the refdx'th axis i.e. image plane
fulldata = fulldataRaw;
[tmp, fulldata(:,:), tmp2] = obj.projectVector(refdx,obj.misc.panes(refdx).nSlice,fulldataRaw(:,:),'position');

% For speed:
if isfield(obj.misc.panes(refdx),'hVoxels')
    hVoxels = obj.misc.panes(refdx).hVoxels;
else
    hVoxels = [];
end

% Support for clicking any part of voxel in Matlab R2014b
if verLessThan('matlab','8.4')
    extraProp = {};
else
    extraProp = {'PickableParts','all'};
end

% Create voxel patches if there are not enough already
numVoxels = obj.data.spec.rows*obj.data.spec.columns;
for voxeldx=1:numVoxels
    if numel(hVoxels) < voxeldx || ~ishandle(hVoxels(voxeldx))
        hVoxels(voxeldx) = patch(NaN,NaN,NaN,...
            'Parent',obj.misc.panes(refdx).hCsiAxis,...
            'FaceAlpha',0,'FaceColor',[1 0 0],'EdgeColor',[1 0 0],...          % ROW, COL
            'Tag','VoxelOutline',...
            'Vertices', NaN(8,3),...
            'Faces', ...
            [1 2 3 4;
            2 6 7 3;
            3 7 8 4;
            1 5 6 2;
            1 4 8 5;
            8 7 6 5; ],...
            'ButtonDownFcn',@obj.voxelClicked_Callback,...
            'UserData',voxeldx,extraProp{:});
    end
end

% Hide excess voxels
for voxeldx=(numVoxels+1):numel(hVoxels)
    set(hVoxels(voxeldx),'Visible','off');
end

% Now draw each voxel:
voxeldx=1;
voxInfo = struct('Zdx',obj.csiSlice);

propName = {'Vertices'};

propVal = cell(numVoxels,1);

for jdx=1:obj.data.spec.rows
    voxInfo.Ydx = jdx;
    
    for idx=1:obj.data.spec.columns
        voxInfo.Xdx = idx;
        voxInfo.nVoxelInPlane = voxeldx;
        
        propVal{voxeldx,1} = [fulldata(:,idx,jdx,1).'
            fulldata(:,idx,jdx+1,1).'
            fulldata(:,idx+1,jdx+1,1).'
            fulldata(:,idx+1,jdx,1).'
            fulldata(:,idx,jdx,2).'
            fulldata(:,idx,jdx+1,2).'
            fulldata(:,idx+1,jdx+1,2).'
            fulldata(:,idx+1,jdx,2).'];

        voxeldx=voxeldx+1;
    end
end

set(hVoxels(1:numVoxels), propName, propVal);
set(hVoxels(1:numVoxels), 'Visible', 'on');

% Assign back local copy (for speed).
obj.misc.panes(refdx).hVoxels = hVoxels;

%% Mark the selected voxel
idxInSlice = obj.data.spec.voxelToIdxInSliceAndSlice(obj.voxel);
set(hVoxels(idxInSlice),'FaceColor',[1 0 0],'FaceAlpha',0.2) % TODO: Use overlay!

%% Sanity check: mark the image position
[tmp, projPosition(:,:), tmp2] = obj.projectVector(refdx,obj.misc.panes(refdx).nSlice,obj.data.spec.imagePositionPatient,'position');
try delete(obj.misc.panes(refdx).hMarkImagePosition); catch end
obj.misc.panes(refdx).hMarkImagePosition = plot(obj.misc.panes(refdx).hCsiAxis,projPosition(1),projPosition(2),'*','markersize',20,'color',[1 1 1]);
end
