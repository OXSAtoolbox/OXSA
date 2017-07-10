% Class permitting spatial shifts of CSI matrix.

% Copyright Chris Rodgers, University of Oxford, 2011.
% $Id: PlotCsi.m 4072 2011-04-08 13:30:59Z crodgers $

classdef ShiftCsi < Spectro.InterpCsi
% N.B. Any changes to the base class must also be updated in the
% constructor and in the setSpectraWorker method.

properties(Access=private)
    base = [];
    
    privateCsiShift = [0 0 0];
end

properties(Dependent)
	csiShift;
end
    
methods
    function obj = ShiftCsi(varargin)
        % Construct a ShiftCsi object from a Siemens MR dicominfo struct.
        %
        % See Spectro.Spec for the permissible constructor syntax.
        
        obj = obj@Spectro.InterpCsi(varargin{:});
        
        % Store a copy of the interpolated values for later use.
        obj.spectraChangeCallback();
    end
    
    function retval = get.csiShift(obj)
        retval = obj.privateCsiShift;
    end
    
    function set.csiShift(obj,newval)
        if isequal(obj.csiShift,newval)
            return
        end
        
        if ~isequal(size(newval),[1 3])
            error('csiShift must be a vector with [X Y Z] increment.')
        end
        
        obj.privateCsiShift = newval;
        
        obj.imagePositionPatient = obj.base.imagePositionPatient ...
            - obj.unitVecs * ...
              diag([obj.pixelSpacing(2);
               obj.pixelSpacing(1);
               obj.sliceThickness]) * obj.csiShift.';
        
        % Perform phase shift and update spectra property.
        for idx=1:numel(obj.base.spectra)
            newSpec{idx} = shiftCsiMatrix(obj.base.spectra{idx}, obj.csiShift(1), obj.csiShift(2), obj.csiShift(3)); %#ok<AGROW>
        end
        obj.setSpectra(newSpec);
        
        fprintf('CSI grid shifted by [ %0.1f, %0.1f, %0.1f] voxels.\n',newval(1), newval(2), newval(3));
    end
end

%%% HACK HACK HACK
% TODO: Spectro.Spec should be modified to take over the functionality of
% CustomReconSpec. Then each of Spectro.InterpCsi and Shift.ShiftCsi should
% be adapted to automatically recalculate if the base data is updated.
methods(Access=protected)
    function update_ShiftCsi_from_CustomReconSpec_HACK(obj)
        if ~isequal(obj.privateCsiShift,[0 0 0])
            error('csiShift must = [0 0 0] to update base spec.')
        end
        
        obj.base.spectra = obj.spectra; % Update this to include the new data!
    end
end

%% Edit this method as desired, but it must be private.
methods(Access=private)
    % Callback function executed when a superclass object changes spectra
    function spectraChangeCallback(obj)
        % Store a copy of the unshifted spectra.
        obj.base.spectra = obj.spectra;
        obj.base.imagePositionPatient=obj.imagePositionPatient;
        
        fprintf('Stored unshifted spectra.\n')
    end
end

%% Special methods to deal with spectra - DO NOT ALTER EXCEPT TO CHANGE BASE CLASS.
methods(Access=protected)
    function setSpectraWorker(obj,src,newval)
        % N.B. BASE CLASS MUST BE SET CORRECTLY ON THIS LINE!!!
        setSpectraWorker@Spectro.InterpCsi(obj,src,newval)
        
        this = meta.class.fromName(mfilename('class'));
        if any(src == this.SuperclassList)
            % This is true IFF src is a direct (one step) superclass of the current class.
            fprintf('%s.setSpectra POST\n',mfilename('class'))
            obj.spectraChangeCallback();
        end
    end
    function setCoilWorker(obj,src,varargin)
        % N.B. BASE CLASS MUST BE SET CORRECTLY ON THIS LINE!!!
        setCoilWorker@Spectro.InterpCsi(obj,src,varargin{:})
        
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
