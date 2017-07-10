classdef dicomImage < Spectro.dicom
% Base class encapsulating Siemens MR DICOM IMAGE data.

% Copyright Chris Rodgers, University of Oxford, 2012.
% $Id: PlotCsi.m 4072 2011-04-08 13:30:59Z crodgers $

% Public properties
properties
    image; % Make image public so that it can be touched up to illustrate analysis.
end

properties(SetAccess=protected)
    columns;
    imageOrientationPatient;
    imagePositionPatient;
    pixelSpacing;
    rows;
end

methods
    function obj = dicomImage(varargin)
        % Call dicom object constructor first.
        obj = obj@Spectro.dicom(varargin{:});

        %% Initialise DICOM object in memory
        % TODO - clean this up!
        if ~isempty(getDicomPrivateTag(obj.info{1},'0029','SIEMENS CSA NON-IMAGE'))
            % Siemens spectroscopy DICOM files require special handling!
            error('This class is not designed to process spectroscopy data. Use Spectro.Spec instead.')
        end

        % Normal processing
        obj.imageOrientationPatient = reshape(obj.info{1}.ImageOrientationPatient,3,2);
        obj.imagePositionPatient = reshape(obj.info{1}.ImagePositionPatient,3,1);
        obj.pixelSpacing = obj.info{1}.PixelSpacing;
        
        % Load pixel data
        obj.image = myDicomRead(obj.info{1}.Filename);

        obj.columns = size(obj.image,1);
        obj.rows = size(obj.image,2);
    end

    function [ret] = sliceNormal(obj)
        % N.B. For Siemens SPECTROSCOPY DATA this calculation would be INCORRECT.
        % See Spectro.Spec's sliceNormal code for details.
        ret = cross(obj.imageOrientationPatient(:,1),obj.imageOrientationPatient(:,2));
    end

    function [ret] = unitVecs(obj)
        ret = [obj.imageOrientationPatient obj.sliceNormal];
    end

    [retval] = calcVoxelCentreCoordsForSlice(obj, slice);
    [retval] = calcVoxelVertexCoordsForSlice(obj, slice);
    [retval] = calcVoxelInPlaneVertexCoordsForSlice(obj, slice);
    [h] = plot3(obj,varargin);
    [h] = plot2(obj,varargin);
    plot(obj,varargin); % Dummy function to give a more helpful error.
    
    function targetCamera(obj)
        % Target the view straight on to an image plotted with plot3()
        % method.
        
        % TODO: The on-axis rotation may need to be updated to satisfy the
        % DICOM standard.
        
        voxelPos = obj.calcVoxelCentreCoordsForSlice(1);
        
        % Average the C,R coords but keep x,y,z separate
        centrePos = mean(mean(voxelPos,2),3);
        imgSize = norm(voxelPos(:,1,1)-centrePos); % Half of one diagonal

        unitVecs = obj.unitVecs();
        
        set(gca,'CameraTarget',centrePos, ...
        	    'CameraPosition',centrePos+imgSize*1.5*obj.sliceNormal, ...
                'CameraUpVector',unitVecs(:,1), ...
                'CameraViewAngleMode','auto');
    end
end

methods(Static)
    function myData = normalizeMinMax(myData)
        % Scale image data so it varies between 0 and 1.
        
        myDataMin = min(myData(:));
        myDataMax = max(myData(:));
        
        if myDataMax == myDataMin
            % Avoid divide by zero errors.
            myDataMax = myDataMin + 1;
        end
        
        myData = (myData - myDataMin) / (myDataMax - myDataMin);
    end
end
end
