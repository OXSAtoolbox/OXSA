function setOverlay(obj,varargin)
% Set an overlay on top of the displayed CSI matrix.
%
% Syntax:
% setOverlay('off'): Removes existing overlay.
%
% setOverlay(data,clim): Sets a new overlay.
% setOverlay(data,clim,mask): Sets a new overlay with a mask
% setOverlay(data,clim,mask,threshold): Sets a threshold for the overlay mask

if ischar(varargin{1}) && strcmp(varargin{1},'off')
    % Disable overlay.
    
    obj.overlay = [];
    
    set(obj.misc.panes(end).hVoxels,...
    'FaceColor',[0 0 0],...
    'FaceAlpha',0,...
    'EdgeAlpha',0.1)
elseif nargin >= 2 && isnumeric(varargin{1}) && isnumeric(varargin{2})
    if numel(varargin{1}) ~= numel(obj.misc.panes(end).hVoxels)
        error('Size mismatch.')
    end
    
    obj.overlay.rawData = varargin{1};
    obj.overlay.clim = varargin{2};
    %Laci
    mask=0;
    if numel(varargin)>2;
        obj.overlay.mask=varargin{3}; 
        mask=1;
        if numel(varargin)>3;
            threshold=varargin{4};
        else
            threshold=0.5;
        end
    end
    
    obj.overlay.rgb = interpColorMap(obj.overlay.rawData,obj.overlay.clim(1),obj.overlay.clim(2));
       
    for idx=1:numel(obj.misc.panes(end).hVoxels)
        if ((mask == 1) && (obj.overlay.mask(idx)<threshold)) || (isnan(obj.overlay.rgb(idx,1))) %Laci
            % TRANSPARENT
            set(obj.misc.panes(end).hVoxels(idx),...
                'FaceColor',[0 0 0],...
                'FaceAlpha',0,...
                'EdgeAlpha',0.1)
        else
            % NORMAL COLOURED VOXEL
            set(obj.misc.panes(end).hVoxels(idx),...
                'FaceColor',obj.overlay.rgb(idx,:),...
                'FaceAlpha',0.2,...
                'EdgeAlpha',0.1)
        end
    end
else
    error('setOverlay must be called with ''off'' or a data set and colour limit pair.')
end
end

function [retval] = interpColorMap(value,cMin,cMax)
% Convert numbers into appropriate RGB values.

retval = zeros(numel(value),3);
jetMap = jet(256);

for idx=1:numel(value)
    tmp = ceil(256 * (value(idx) - cMin) / (cMax - cMin));

    if tmp<1
        tmp=1;
    end

    if tmp>256
        tmp=256;
    end
    
    if isnan(tmp)
        retval(idx,:) = NaN(1,3);
    else
        retval(idx,:) = jetMap(tmp,:);
    end
end

end
