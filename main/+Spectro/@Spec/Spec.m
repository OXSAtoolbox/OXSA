classdef Spec < Spectro.dicom
% Base class encapsulating Siemens MR spectroscopy data.

% Copyright Chris Rodgers, University of Oxford, 2011.
% $Id: PlotCsi.m 4072 2011-04-08 13:30:59Z crodgers $

% The "spectra" property here is handled so that it may be referred to
% transparently by client code. Within Spectro.Spec and its subclasses,
% "spectra" is updated to reflect CSI interpolation and CSI matrix shifts
% as necessary.
%
% This necessitates some additional code to work around the lack of support
% for overloaded property get and set methods in Matlab. This is described
% in detail in jobs\2011-07\ParentNotifyTest_*.m.
    
% TODO:
% Possibly override subsref to perform FFT on the fly during data access.
%
% Remove the "info" property and force client code to use the "dicom.info"
% property instead.

% Public properties
properties
%     debug = false;
end

% These are copied from the CSA header once during object construction.
properties(SetAccess=private)
    samples;
    
    bandwidth;
    dwellTime;
    freqAxis;
    timeAxis;
    imagingFrequency;
    imageOrientationPatient;
    ppmAxis;
    sliceNormal;
    unitVecs;

    signals;
    dicom;

%     info;
end

properties(Dependent,SetAccess=private)
    size;
end

%% Special methods to deal with spectra - DO NOT ALTER EXCEPT TO CHANGE BASE CLASS.
% Publicly accessible value for "spectra".
% It is set through the setSpectra method.
properties(Transient,SetAccess=private)
    spectra;
    coils;
    coilIndex;
    coilStrings;
    coilStringsUncombined;
end

methods(Access=private)
    function setSpectra(obj,newval)
        obj.setSpectraWorker(meta.class.fromName(mfilename('class')),newval);
    end
end

methods(Access=protected)
    function setSpectraWorker(obj,src,newval)
        if ~obj.quiet
            fprintf('%s.setSpectra: src = %s, newval =%s\n',mfilename('class'),src.Name,evalc('disp(newval)')) %wtc diabled this output which identified the class and dimensionality of the loaded spectra  
        end
        obj.spectra = newval;
    end
end
%% End of spectra code.

%% Special methods to update coilstrings if some kind of reconstruction is performed after exporting from scanner. 
%Set coilStrings using the setCoil method
methods(Access=private)
    function setCoil(obj,newval,newval2)
        obj.setCoilWorker(meta.class.fromName(mfilename('class')),newval,newval2);
    end
end

methods(Access=protected)
    function setCoilWorker(obj,src,newval,newval2)
        fprintf('%s.setCoil: src = %s, newval = %s, newval2 = %s\n',mfilename('class'),src.Name,evalc('disp(newval)'),evalc('disp(newval2)'));
        obj.coilStrings = newval;
        obj.coilIndex = newval2;
        obj.coils = numel(newval);
    end
end
%% End of Coil methods

%% Other overridable properties
% These may be overridden in sub-classes
properties(SetAccess=protected)
    rows;
    columns;
    slices;
    pixelSpacing;
    sliceThickness;
    imagePositionPatient;
    coilInfo; % Struct storing information about the coil used for acquisition. Used for locating coil.
end
   
methods
    function obj = Spec(varargin)
        % Construct a Spec object from a Siemens MR dicominfo struct.
        %
        % This code assumes that all spectra were acquired during the
        % same scan, so that they have identical coordinates.
        
        % Step 1: Convert input arguments to a cell array of
        %         structures returned from SiemensCsaParse.
        %
        % Step 2: Optionally sort that cell array into canonical coil
        %         order.
        %
        % Step 3: Convert the spectroscopy data into a helpful format.
        
        % Sanity-check supplied arguments:
        if nargin < 1
            error('Spectra to load must be specified.')
        end
                
        %% Call parent constructor
        obj = obj@Spectro.dicom(varargin{:});
        
        %% Check DICOM file for coil, identify possible coils, select and store data for coil.
        obj.coilInfo = obj.getCoilInfo();
        
        %% Sort coils
        info = reshape(obj.info,[],1);
        
        if ~isfield(obj.options,'sortCoils') || obj.options.sortCoils
            info = obj.sortCoils(info);
        else
            % TODO: Clean this code up - merge relevant bits with sortCoils
            % method.
 
            obj.coilIndex = 1:numel(info);
            
            for filedx=1:numel(info)
                obj.coilStrings{filedx} = [info{filedx}.ImageComments ...
                                           info{filedx}.csa.ImaCoilString];
            end
        end
        
        %% Load FIDs
        try
        obj.LoadFids(info, obj.options);
        catch
            error('Unable to load FIDs. Check that target data is correct.')
        end
        % Store the raw dicominfo (sorted) if desired.
        obj.info = info;

        obj.dicom = cell(size(obj.info));
        for idx=1:numel(info)
            obj.dicom{idx} = Spectro.dicom(obj.info{idx});
        end
    end

    function info = sortCoils(obj, unsortedInfo)
        %% Load the FIDs specified in info
        %
        % N.B. Any special cases here MUST BE REPLICATED INTO THE
        % getMrProtocolCoilDetails method.
        numCoils = numel(unsortedInfo);
        
        for filedx=1:numCoils
            if isfield(unsortedInfo{filedx},'ImageComments')
                unsortedImageComments{filedx} = unsortedInfo{filedx}.ImageComments;
            else
                unsortedImageComments{filedx} = '';
            end
               
            if (strcmp(unsortedInfo{filedx}.Private_0029_1009, 'syngo MR E11') && ~strcmp(unsortedImageComments{filedx}, '_u'))
                temp = strfind(unsortedImageComments{filedx}, '_');
                %unsortedCoilNames{filedx} = substr(unsortedImageComments{filedx}, temp(2));
                unsortedCoilNames{filedx} = unsortedImageComments{filedx}(temp(2) + 1:end);
            else
                unsortedCoilNames{filedx} = unsortedInfo{filedx}.csa.ImaCoilString;
            end;
            
            % Workaround for broken ICE code on the 7T
            if isfield(unsortedInfo{filedx}.csa,'MagneticFieldStrength')
                MagneticFieldStrength = unsortedInfo{filedx}.csa.MagneticFieldStrength;
            elseif isfield(unsortedInfo{filedx},'MagneticFieldStrength')
                MagneticFieldStrength = unsortedInfo{filedx}.MagneticFieldStrength;
            else
                error('Unknown field strength.')
            end
            
            % Special case for WSVDv2 or product IceSpectroscopy combination on the 7T
            if abs(MagneticFieldStrength - 6.98) < 0.1 ...
                    && strcmp(unsortedInfo{filedx}.csa.ImaCoilString,'XXX')
                
                % Algorithm (reverse-engineered from IceSpectro code):
                %
                % Assemble list of sCoilElementID.tElement.
                % Assemble list of lRxChannelConnected.
                % Sort these by lRxChannelConnected.
                % Then this is the ID for the TWIX/DICOM uncombined data in order.
                
                elementList = obj.regexpMrProtocol(['asCoilSelectMeas\[0\]\.asList\[([0-9]+)\]\.sCoilElementID\.tElement *= ""(.*)""$'],'tokens');
                rxChaList = obj.regexpMrProtocol(['asCoilSelectMeas\[0\]\.asList\[([0-9]+)\]\.lRxChannelConnected *= (.*)$'],'tokens');
                
%                 digInto(elementList)
%                 digInto(rxChaList)
                
                [~,rxDx] = sort(cellfun(@(x) str2double(x{2}), rxChaList));
                
                elementListDicomOrder = cellfun(@(x) x{2},elementList(rxDx),'uniformoutput',false);
                try
                    unsortedCoilNames{filedx} = elementListDicomOrder{unsortedInfo{filedx}.InstanceNumber};
                end
            end
            
            % Special case for the Oxford 7T 16-element array
            % N.B. Any special cases here MUST BE REPLICATED INTO THE
            % getMrProtocolCoilDetails method.
            if isfield(obj.coilInfo,'name') && strcmp(obj.coilInfo.name,'OXF_7T_31P_Rapid16chArray')
                % And fix the stupid (non-alphabetical) coil numbering from Rapid!!
                unsortedCoilNames{filedx} = regexprep(unsortedCoilNames{filedx},'^CH','C0');
            end
        end
        
        %% Sort the coils by name if required.
        % Sort uncombined coils
        idx_uncombined = strcmp(unsortedImageComments,'_u');
        if (sum(idx_uncombined) == 0)
            % Try to see whether these spectra were collected on a
            % VE line scanner. Uncombined spectra comments originating from VE line start
            % with _upw_
            idx_uncombined = strncmp(unsortedImageComments, '_upw_', 5);
        end;
        [tmp1,idx1] = sort(unsortedCoilNames);
        
        coilIndexUncomb = idx1(idx_uncombined(idx1)); % Raw coils
        coilIndexComb = idx1(~idx_uncombined(idx1));
        
        [tmp2,idx2] = sort(unsortedImageComments(idx1(~idx_uncombined(idx1))));   % Combinations
        coilIndexCombSorted = coilIndexComb(idx2(end:-1:1));
        
        obj.coilIndex = [coilIndexUncomb coilIndexCombSorted];
        
        % Shuffle strFiles, info and csaBlock
        info = unsortedInfo(obj.coilIndex);
        obj.coilStrings = arrayfun(@(x,y) [x{1} y{1}],unsortedCoilNames(obj.coilIndex),unsortedImageComments(obj.coilIndex),'UniformOutput',false);
        
        obj.coilStringsUncombined = unsortedCoilNames(coilIndexUncomb);
        % If single-element acquired, then include this too...
        if obj.getMrProtocolCoilDetails.numElements == 1 && isempty(obj.coilStringsUncombined)
            obj.coilStringsUncombined = obj.coilStrings(1);
        end
        
        if obj.debug
            for tmp=1:numel(obj.coilIndex)
                fprintf('Remapped coils %d (raw) ==> %d (new) [%s]\n',obj.coilIndex(tmp),tmp,obj.coilStrings{tmp});
            end
        end
    end
    
    function [out] = getMrProtocolCoilDetails(obj)
        % Load details of the Rx elements used from the ASCII protocol.
        % This means that information is available for all connected Rx
        % channels from the DICOM file for any ONE channel.
        
        % N.B. Any special cases here MUST BE REPLICATED INTO THE
        % sortCoils method.
        
        % Load all channel names and sort them as per WSVD_v4 code in
        % IceSpectroConfigurator.cpp.
        out = getMrProtocolCoilDetails@Spectro.dicom(obj);
        
        % Special case for Rapid 16ch coil
        if isfield(obj.coilInfo,'name') && strcmp(obj.coilInfo.name,'OXF_7T_31P_Rapid16chArray')
            % And fix the stupid (non-alphabetical) coil numbering from Rapid!!
            out.tElement_TwixOrder = regexprep(out.tElement_TwixOrder,'^CH','C0');
        end
        
        % Compute the ordering that Spectro.obj WOULD APPLY
        [~,out.coilIndex_for_SpectroSpecOrder] = sort(out.tElement_TwixOrder);
         
%         %% Extra output for debugging... compare to DICOM headers
%         % Compare against the DICOM coil strings
%         out.coilStrings_TwixOrder(obj.coilIndex) = obj.coilStrings;
%         
%         % Extract only the uncombined DICOM coil strings (i.e. those not
%         % ending with "_u")
%         out.coilStrings_TwixOrder_onlyUncombined = regexp(out.coilStrings_TwixOrder,'(^.*)_u','tokens','once');
%         for idx=numel(out.coilStrings_TwixOrder_onlyUncombined):-1:1
%             if isempty(out.coilStrings_TwixOrder_onlyUncombined{idx})
%                 out.coilStrings_TwixOrder_onlyUncombined(idx) = [];
%             else
%                 out.coilStrings_TwixOrder_onlyUncombined(idx) = out.coilStrings_TwixOrder_onlyUncombined{idx};
%             end
%         end
    end
    
    
    function LoadFids(obj, info, options)
        %% Now load in the spectroscopy data
        for coilDx=1:numel(info)
            % We ignore the VOI at this time
            oldWarningState = warning('off','SiemensCsaReadFid:Interpolated');
            % N.B. We economise on memory by wiping the FID raw data from the DICOM struct
            [obj.signals{coilDx,1}, info{coilDx,1}] = SiemensCsaReadFid(info{coilDx},true,'conj',obj.debug);
            warning(oldWarningState);
            
            % Fourier transform (no phasing or other processing yet)
            obj.spectra{coilDx,1} = specFft(obj.signals{coilDx,1});
            
            % Clear the "signals" for memory efficiency unless they are needed
            if ~isfield(options,'keepFids') || ~options.keepFids
                obj.signals{coilDx} = [];
            end

            if ~isequal(size(obj.spectra{1}),size(obj.spectra{coilDx}))
                error('All spectra must have matching dimensions, timings, etc.')
            end
        end
        
        % Allow override of the "spectra" data...
        if isfield(options,'overrideSpectra') && ~isempty(options.overrideSpectra)
            if ~isequal(size(obj.spectra),size(options.overrideSpectra))
                error('All spectra must have matching dimensions, timings, etc.')
            else
                obj.spectra = options.overrideSpectra;
            end
        end
        
        tmp = size(obj.spectra{coilDx},1)/2;
        obj.dwellTime = info{1}.csa.RealDwellTime*1e-9;
        obj.bandwidth = 1/obj.dwellTime;
        obj.imagingFrequency = info{1}.csa.ImagingFrequency;
        obj.samples = size(obj.spectra{1},1);
        
        % In Hz
        obj.freqAxis = ((-tmp):(tmp-1)).'/(obj.dwellTime*tmp*2);
        
        % In ppm
        obj.ppmAxis = obj.freqAxis / obj.imagingFrequency;
        
        % In s
        obj.timeAxis = obj.dwellTime*(0:obj.samples-1).';
        
        obj.columns=info{1}.csa.Columns; % First two in CSI plane
        obj.rows=info{1}.csa.Rows;
        obj.slices=info{1}.csa.NumberOfFrames; % Number of CSI planes
        obj.pixelSpacing=info{1}.csa.PixelSpacing;
        obj.sliceThickness=info{1}.csa.SliceThickness;
        
        obj.imageOrientationPatient=reshape(info{1}.csa.ImageOrientationPatient,3,2);
        obj.imagePositionPatient=reshape(info{1}.csa.ImagePositionPatient,3,1);
        
        % Siemens have a bizarre convention. The largest component of the slice
        % normal vector is taken to be positive. This means sometimes the CSI
        % coordinate system is right-handed and sometimes its left-handed.
        obj.sliceNormal = cross(obj.imageOrientationPatient(:,1),obj.imageOrientationPatient(:,2));
        if -min(obj.sliceNormal) > max(obj.sliceNormal)
            obj.sliceNormal = -obj.sliceNormal; % Reverse sign of normal vector.
        end
        
        obj.unitVecs = [obj.imageOrientationPatient obj.sliceNormal];
        
        obj.coils = numel(info);
    end
    
    function retval = get.size(obj)
        % N.B. Siemens spectroscopy data are loaded in as COLUMNS, ROWS,
        % SLICES because this makes the voxels count first along row #1.
        retval = [obj.columns obj.rows obj.slices];
    end
        
    function crs = voxelToColRowSlice(obj,voxel)
        if voxel < 1 || voxel > prod(obj.size)
            crs = [];
        else
            crs = zeros(1,3);
            [crs(1) crs(2) crs(3)] = ind2sub(obj.size,voxel);
        end
    end
    
    function voxel = colRowSliceToVoxel(obj,crs)
        if any(crs < 1) || crs(1) > obj.columns ...
                || crs(2) > obj.rows ...
                || crs(3) > obj.slices
            voxel = [];
        else
            voxel = sub2ind(obj.size, crs(1), crs(2), crs(3));
        end
    end
    
    function [idxInSlice, slice] = voxelToIdxInSliceAndSlice(obj,voxel)
        crs = voxelToColRowSlice(obj,voxel);
        
        if isempty(crs)
            idxInSlice = [];
            slice = [];
            return
        end
        
        slice = crs(3);
        
        idxInSlice = sub2ind(obj.size(1:2),crs(1),crs(2));
    end
    
    function [voxel] = idxInSliceAndSliceToVoxel(obj, idxInSlice, slice)
        if ischar(idxInSlice) && strcmp(idxInSlice,'end')
            idxInSlice = obj.columns * obj.rows;
        end
        
        if slice < 1 || slice > obj.slices ...
                || idxInSlice < 1 || idxInSlice > obj.columns*obj.rows
            voxel = [];
            return
        end
        
        crs(3) = slice;
        
        [crs(1) crs(2)] = ind2sub(obj.size(1:2), idxInSlice);
        
        voxel = obj.colRowSliceToVoxel(crs);
    end
    
    function [digits] = maxVoxelDigits(obj)
        digits = ceil(log10(prod(obj.size)));
    end
    
%     [retval] = calcVoxelCentreCoordsForSlice(obj, slice);
%     [retval] = calcVoxelVertexCoordsForSlice(obj, slice);
%     
%     [fulldata] = calcVoxelCentreCoords(obj, voxel);
%     [fulldata] = calcVoxelVertexCoords(obj, voxel);

    function s = saveobj(obj)
        s.version = 2; % This must match the version in loadobj() below.
        s.info = obj.info;
        s.debug = obj.debug;
        s.options = obj.options;
    end
    
    function [hOut] = plot(obj,varargin)
        % Default plot is of either all coils/instances or all voxels.
        % Multi-coil and multi-voxel data must supply options to override
        % the default selection.
        %
        % Options may be provided as a struct or name/value pairs.
        
        % TODO: Extend the plotting options.
        
        options = processVarargin(varargin{:});

        if ~isfield(options,'coils') && ~isfield(options,'voxels')
            % Default plot
            if numel(obj.spectra) == 1
                tmpSpec = obj.spectra{1}(:,:);
            else
                tmpSize = size(obj.spectra{1});
                if numel(tmpSize) == 2 && tmpSize(2) == 1
                    tmpSpec = [obj.spectra{:}];
                else
                    error('You must specify the coils and voxels to plot.')
                end
            end
        else
            error('Not yet implemented.')
        end
        
        h = plotMrSpectra(obj.ppmAxis,tmpSpec,options);
        
        if nargout > 0
            hOut = h;
        end
    end
    
    function [outSpec] = apodize(obj,spectra,amount)
        outSpec = specApodize(obj.timeAxis,spectra,amount);
    end
    
    function overrideSpectra(obj,newSpec)
        % Allow override of the "spectra" data...
        if ~isequal(size(obj.spectra),size(newSpec))
            error('All spectra must have matching dimensions, timings, etc.')
        else
            obj.setSpectra(newSpec);
            obj.options.overrideSpectra = newSpec;
        end
    end
    
    % WTC: Methods for calling the _static methods which have been made static
    % so they are accessible for the synthSpec class. The purpose of these
    % methods is to keep compatability with the large amounts of code which
    %  call the original methods. This has to be done as the syntax
    %  obj.staticMethod(2nd argument here) does not pass the class object automatically. 
    
    function [retval] = calcVoxelCentreCoordsForSlice(obj, slice)
        [retval] = Spectro.Spec.calcVoxelCentreCoordsForSlice_static(obj, slice);
    end
    
    function [retval] = calcVoxelVertexCoordsForSlice(obj, slice)
        [retval] = Spectro.Spec.calcVoxelVertexCoordsForSlice_static(obj, slice);
    end
    
    function [fulldata] = calcVoxelCentreCoords(obj, voxel)
        [fulldata] = Spectro.Spec.calcVoxelCentreCoords_static(obj, voxel);
    end
    
    function [fulldata] = calcVoxelVertexCoords(obj, voxel)
        [fulldata] = Spectro.Spec.calcVoxelVertexCoords_static(obj, voxel);
    end
    
end

methods (Static)
    % Load method notes:
    %
    % V1: options aren't saved so e.g. coil sorting might have changed
    %     between save/load.
    % V2: Saves options too.
    function obj = loadobj(s)
        if s.version > 2 % This must match the version in saveobj(...).
            error('Data saved with later Spectro.Spec version. You must upgrade!');
        elseif s.version >= 2
            % V2 load
            obj = Spectro.Spec(s.info,s.options);
        elseif s.version >= 1
            % V1 load
            obj = Spectro.Spec(s.info,'debug',s.debug);
        else
            error('Error loading Spectro.Spec object data - missing version ID.')
        end
    end
    
    
    [retval] = calcVoxelCentreCoordsForSlice_static(obj, slice);
    [retval] = calcVoxelVertexCoordsForSlice_static(obj, slice);
    
    [fulldata] = calcVoxelCentreCoords_static(obj, voxel);
    [fulldata] = calcVoxelVertexCoords_static(obj, voxel);

end
end

