classdef CustomReconSpec < Spectro.ShiftCsi
% Subclass to store spectra combined in custom (external) code so they can
% be plotted, fitted, etc as normal.
%
% Based on Tobias Sjolander's SenseSpec class.
%
% TODO: This class should not exist in this form. Instead, the
% functionality should be implemented as part of the base Spectro.Spec
% class. That way one can apply CSI shift and CSI de-interp to the modified
% spectra.

properties(Access = private)
    coils_Original; % Store the number of actual DICOM data files.
end

% properties(SetAccess = private)
%     isSense = false;
%     sensMaps = struct;
%     transmitMap
%     TxCorrectionFactor
% end

methods
    function obj = CustomReconSpec(info_or_existingObj, varargin)
        % Support two syntaxes for creating a CustomReconSpec object.
        %
        % Either: pass "info" which is a struct or cell array of structs.
        % This will create a corresponding ShiftCsi object which can then
        % be overridden from there.
        %
        % Or (WTC new mode): pass a Spectro.Spec object which will be
        % cloned and can then be overridden.
        
        if isa(info_or_existingObj,'Spectro.Spec')
            % WTC new mode:
            existingObj = info_or_existingObj;
            info = existingObj.info;
        elseif isa(info_or_existingObj,'struct') || isa(info_or_existingObj,'cell')
            % CTR original mode:
            info = info_or_existingObj;
        else
            error('Unknown input type!')
        end
        
        obj = obj@Spectro.ShiftCsi(info, varargin{:}); % You can only have a single superclass constructor call, so this has to be outside the if...end block above.
        
        if isa(info_or_existingObj,'Spectro.Spec')
            % WTC new mode:
        
            % Override the Obj called above with the relavent parts of the existing obj
            obj.setSpectra(existingObj.spectra)
            obj.setCoil(existingObj.coilStrings,existingObj.coilIndex)
            obj.coils_Original = obj.coils;
            
        elseif isa(info_or_existingObj,'struct') || isa(info_or_existingObj,'cell')
            % CTR original mode:
            
            % Store an unmodified copy of important variables.
            obj.coils_Original = obj.coils;
        else
            error('Unknown input type!')
        end

    end
    
    function setCustomSpectra(obj, varargin)
        
        %% Read in input arguments
        options = processVarargin(varargin{:});
        
        %% Store the supplied custom spectra into this CustomReconSpec object as an additional "coil(s)" or totally replace the loaded data.
        % Update the coilStrings and coilIndex properties of the main
        % object to reflect the new reconstructed data.
        
        bReplaceAllData = (isfield(options,'replaceAllData') && options.replaceAllData);
        
        % TODO: Remove this HACK.
        origCsiShift = obj.csiShift;
        obj.csiShift = [0 0 0];
        
        %% Check new data OK
        if ~isfield(options,'newSpec')
            error('newSpec must be a samples x columns x rows x slices matrix of doubles or a cell array of these.')
        end
        
        if ~iscell(options.newSpec)
            options.newSpec = { options.newSpec };
        end
        
        for newSpecDx=1:numel(options.newSpec)
            if (~isequal(size(options.newSpec{newSpecDx}),[ obj.samples,obj.columns,obj.rows,obj.slices ])&&prod([obj.columns,obj.rows,obj.slices ])~=1) || ~isa(options.newSpec{newSpecDx},'double')
                error('newSpec must be a samples x columns x rows x slices matrix of doubles or a cell array of these.')
            end
            
        end
        
        if ~isfield(options,'newName')
            error('newName must mark the custom recon name e.g. for jMRUI/AMARES export or a cell array of names.')
        end
        
        if ~iscell(options.newName)
            options.newName = { options.newName };
        end
        
        if bReplaceAllData
            if ~isfield(options,'newCoilIndex')
                error('You must pass in the appropriate CoilIndex when replacing all data.')
            end
            
            newSpec = options.newSpec;
            newCoil = options.newName;
            newCoilIndex = options.newCoilIndex;
        else
            newSpec = obj.spectra(1:obj.coils_Original);
            newCoil = obj.coilStrings(1:obj.coils_Original);
            newCoilIndex = obj.coilIndex(1:obj.coils_Original);
            
            newSpec(end+1:end+numel(options.newSpec)) = options.newSpec;
            newCoil(end+1:end+numel(options.newSpec)) = options.newName;
            newCoilIndex(end+1:end+numel(options.newSpec)) = numel(newCoilIndex) + (1:numel(options.newSpec));
        end
        
        obj.setSpectra(newSpec)
        obj.setCoil(newCoil,newCoilIndex)
        
        obj.update_ShiftCsi_from_CustomReconSpec_HACK();
        obj.csiShift = origCsiShift;
    end
end


%% Edit this method as desired, but it must be private.
methods(Access=private)
    % Callback function executed when a superclass object changes spectra
    function spectraChangeCallback(obj)
    end
end

%% Special methods to deal with spectra - DO NOT ALTER EXCEPT TO CHANGE BASE CLASS.
methods(Access=protected)
    function setSpectraWorker(obj,src,newval)
        % N.B. BASE CLASS MUST BE SET CORRECTLY ON THIS LINE!!!
        setSpectraWorker@Spectro.ShiftCsi(obj,src,newval)
        
        this = meta.class.fromName(mfilename('class'));
        if any(src == this.SuperclassList)
            % This is true IFF src is a direct (one step) superclass of the current class.
            fprintf('%s.setSpectra POST\n',mfilename('class'))
            obj.spectraChangeCallback();
        end
    end
    function setCoilWorker(obj,src,varargin)
        % N.B. BASE CLASS MUST BE SET CORRECTLY ON THIS LINE!!!
        setCoilWorker@Spectro.ShiftCsi(obj,src,varargin{:})
        
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