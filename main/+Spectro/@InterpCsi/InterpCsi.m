% Class encapsulating CSI spectra with or without interpolation.
%
% Provides methods to index voxel number <--> row, col, slice.
%
% Removes interpolation and caches result.

% Copyright Chris Rodgers, University of Oxford, 2008-11.
% $Id: PlotCsi.m 4072 2011-04-08 13:30:59Z crodgers $

classdef InterpCsi < Spectro.Spec
% N.B. Any changes to the base class must also be updated in the
% constructor and in the setSpectraWorker method.
    
properties(Access=private)
    interp = [];
    
    deInterp = [];
    
    privateCsiInterpolated = 1;
end

properties(Dependent)
    csiInterpolated;
end

methods
    function obj = InterpCsi(varargin)
        % Construct an InterpSpec object from a Siemens MR dicominfo struct.
        %
        % This code assumes that all spectra were acquired during the
        % same scan, so that they have identical coordinates.
        
        obj = obj@Spectro.Spec(varargin{:});
        
        % Store a copy of the interpolated values for later use.
        obj.interp.spectra = obj.spectra;
        obj.interp.rows=obj.rows;
        obj.interp.columns=obj.columns;
        obj.interp.slices=obj.slices;
        obj.interp.pixelSpacing=obj.pixelSpacing;
        obj.interp.sliceThickness=obj.sliceThickness;
        
        obj.deInterp.rows=obj.info{1}.csa.SpectroscopyAcquisitionPhaseRows;
        obj.deInterp.columns=obj.info{1}.csa.SpectroscopyAcquisitionPhaseColumns; % First two in CSI plane
        obj.deInterp.slices=obj.info{1}.csa.SpectroscopyAcquisitionOutofplanePhaseSteps; % Number of CSI planes
        obj.deInterp.pixelSpacing = obj.interp.pixelSpacing ...
            .* [obj.interp.rows / obj.deInterp.rows, ...
            obj.interp.columns / obj.deInterp.columns];
        obj.deInterp.sliceThickness = obj.interp.sliceThickness ...
            * obj.interp.slices / obj.deInterp.slices;
    end
    
    function retval = get.csiInterpolated(obj)
        retval = obj.privateCsiInterpolated;
    end
    
    function set.csiInterpolated(obj,newVal)
        if newVal
            obj.privateCsiInterpolated = 1;
            
            fn = fieldnames(obj.interp);
            for idx=1:numel(fn)
                if strcmp(fn{idx},'spectra')
                    obj.setSpectra(obj.interp.(fn{idx}));
                else
                    obj.(fn{idx}) = obj.interp.(fn{idx});
                end
            end
        else
            obj.privateCsiInterpolated = 0;
            
            % Convert data if necessary
            if ~isfield(obj.deInterp,'spectra') || isempty(obj.deInterp.spectra)
                obj.deinterpolateData();
            end
            
            fn = fieldnames(obj.deInterp);
            for idx=1:numel(fn)
                if strcmp(fn{idx},'spectra')
                    obj.setSpectra(obj.deInterp.(fn{idx}));
                else
                    obj.(fn{idx}) = obj.deInterp.(fn{idx});
                end
            end
        end
    end
    
    function deinterpolateData(obj)
        %% Converting interpolated spectra to original CSI matrix
        fprintf('Deinterpolating coil #');
        
        for coilDx = 1:numel(obj.interp.spectra)
            fprintf('%d',coilDx);
            
            %% Invert spatial FFT (image-space --> k-space)
            bbb = obj.interp.spectra{coilDx}(:,:,:,:);
            bbb=ifftshift(ifft(ifftshift(conj(bbb),2),[],2),2);
            bbb=ifftshift(ifft(ifftshift(bbb,3),[],3),3);
            bbb=ifftshift(ifft(ifftshift(bbb,4),[],4),4);
            
            if obj.debug
                figure(90)
                clf
                for idx=1:size(bbb,2)
                    subplot(4,8,idx)
                    spy(squeeze(abs(bbb(1,idx,:,:))>1e-6));
                    title(sprintf('idx = %d',idx))
                    set(gca,'YDir','normal')
                end
            end
            
            %% Truncate k-space
            
            % Now chop off the excess, such that the maximally sampled slice is
            % middle (rounded up). E.g. 17 in a set of 32.
            
            mask2 = true(1,obj.interp.columns);
            mask2(1:ceil((obj.interp.columns-obj.deInterp.columns)/2))=0;
            mask2((end-floor((obj.interp.columns-obj.deInterp.columns)/2)+1):end)=0;
            
            mask3 = true(1,obj.interp.rows);
            mask3(1:ceil((obj.interp.rows-obj.deInterp.rows)/2))=0;
            mask3((end-floor((obj.interp.rows-obj.deInterp.rows)/2)+1):end)=0;
            
            mask4 = true(1,obj.interp.slices);
            mask4(1:ceil((obj.interp.slices-obj.deInterp.slices)/2))=0;
            mask4((end-floor((obj.interp.slices-obj.deInterp.slices)/2)+1):end)=0;
            
            
            ccc=bbb(:,mask2,mask3,mask4);
            
            if obj.debug
                figure(91)
                clf
                for idx=1:size(ccc,2)
                    subplot(4,6,idx)
                    spy(squeeze(abs(ccc(1,idx,:,:))>1e-6));
                    title(sprintf('idx = %d',idx))
                    set(gca,'YDir','norm')
                end
            end
            
            %% New spatial FFT (k-space --> image-space)
            % Do the FFTs again (opposite order to inverse above):
            ccc = fftshift(fft(fftshift(ccc,2),[],2),2);
            ccc = fftshift(fft(fftshift(ccc,3),[],3),3);
            ccc = fftshift(fft(fftshift(ccc,4),[],4),4);
            ccc = conj(ccc);
            
            obj.deInterp.spectra{coilDx} = ccc;
            
            if coilDx == numel(obj.interp.spectra)
                fprintf('.\n');
            else
                fprintf(', ');
            end
        end
    end
end

%% Edit this method as desired, but it must be private.
methods(Access=private)
    % Callback function executed when a superclass object changes spectra
    function spectraChangeCallback(obj)
%         obj.setSpectra(obj.spectra + 20);
        error('Not implemented. Presently, Spectro.InterpCsi cannot handle changes to the base Spectro.Spec object''s data.')
    end
end

%% Special methods to deal with spectra - DO NOT ALTER EXCEPT TO CHANGE BASE CLASS.
methods(Access=protected)
    function setSpectraWorker(obj,src,newval)
        % N.B. BASE CLASS MUST BE SET CORRECTLY ON THIS LINE!!!
        setSpectraWorker@Spectro.Spec(obj,src,newval)
        
        this = meta.class.fromName(mfilename('class'));
        if any(src == this.SuperclassList)
            % This is true IFF src is a direct (one step) superclass of the current class.
            fprintf('%s.setSpectra POST\n',mfilename('class'))
            obj.spectraChangeCallback();
        end
    end
    function setCoilWorker(obj,src,varargin)
        % N.B. BASE CLASS MUST BE SET CORRECTLY ON THIS LINE!!!
        setCoilWorker@Spectro.Spec(obj,src,varargin{:})
        
        this = meta.class.fromName(mfilename('class'));
        if any(src == this.SuperclassList)
            % This is true IFF src is a direct (one step) superclass of the current class.
            fprintf('%s.setCoil POST\n',mfilename('class'))
            obj.spectraChangeCallback();
        end
    end    
end

methods(Access=private)
    function setSpectra(obj,newval)
        obj.setSpectraWorker(meta.class.fromName(mfilename('class')),newval);
    end
    function setCoil(obj,varargin)
        obj.setCoilWorker(meta.class.fromName(mfilename('class')),varargin{:});
    end    
end
%% End of spectra code.
end
