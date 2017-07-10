classdef sliderEx < handle
% GUI slider that handles the situation where MAX = MIN gracefully.
%
% N.B. There is a memory leak with this code: the destructor is not called
% when the object is cleared UNTIL the UI control has been destroyed.

% Copyright Chris Rodgers, University of Oxford, 2011.
% $Id: sliderEx.m 5536 2012-06-22 09:54:39Z crodgers $
       
    properties
        value;
        min;
        max;
        sliderStep;
        
        callback;
        timeout;
        
        debug = false;
    end
    
    properties (SetAccess='private', GetAccess='public')
        hSlider = [];
    end

    properties (SetAccess='private', GetAccess='private')
        settingsValid_;
        timer_;
    end
    
    methods
    function [h] = sliderEx(value,min,max,sliderStep,callback,varargin)
        % Create a GUI slider that handles the situation where MAX =
        % MIN gracefully.
        %
        % E.g.
        % figure; x = sliderEx(2,0,5,1)
        
        h.value = value;
        h.min = min;
        h.max = max;
        h.sliderStep = sliderStep;
        
        h.hSlider=uicontrol('Style','slider','Callback',@h.ValueCallback,varargin{:},'DeleteFcn',@(varargin) delete(h),'Interruptible','off');
        h.setValueMinMaxSliderStep();
        
        if nargin < 5
            callback = [];
        end
        
        h.callback = callback;
        
        h.timer_ = timer('BusyMode','drop','ExecutionMode','singleShot',...
            'Name','sliderEx_Timer','TimerFcn',@h.ValueCallback_Main);
    end
    
    function ValueCallback(h,varargin)
        if h.debug
            fprintf('Value changed!\n')
        end
        
        if h.timeout
            if ~strcmp(h.timer_.Running,'off')
                stop(h.timer_);
            end
            h.timer_.StartDelay = h.timeout;
            start(h.timer_);
        else
            h.ValueCallback_Main(varargin{:});
        end
    end
    
    function ValueCallback_Main(h,varargin)
        if h.debug
            fprintf('Setting value.\n')
        end

        % No timeout - execute immediately.
        h.value = get(h.hSlider,'Value');
            
        if isa(h.callback,'function_handle')
            h.callback(h);
        end
    end
    
    function delete(h)
        if h.debug
            fprintf('Deleting sliderEx\n');
        end
        delete(h.hSlider);
    end
    
    function setValueMinMaxSliderStep(h)
        if isempty(h.hSlider) || ~ishandle(h.hSlider)
            % Cannot set properties if the slider is not yet created.
            return
        end
        
        h.settingsValid_ = true;
        
        if h.max <= h.min
            if h.debug
                warning('Max <= Min.')
            end
            
            h.settingsValid_ = false;
        else
            theSliderStep = [h.sliderStep h.sliderStep]/(h.max - h.min);
        end
        
        if h.value < h.min || h.value > h.max
            if h.debug
                warning('Value is out of range.');
            end
            
            h.settingsValid_ = false;
        end
        
        if h.settingsValid_
            set(h.hSlider,'Value',h.value,'Min',h.min,'Max',h.max,'SliderStep',theSliderStep,'Enable','on');
        else
            set(h.hSlider,'Value',1,'Min',1,'Max',2,'SliderStep',[1 1],'Enable','off');
        end
    end
    
    function set.value(h, new)
        h.value = new;
        
        h.setValueMinMaxSliderStep();
    end
    
    function set.sliderStep(h, new)
        h.sliderStep = new;
        
        h.setValueMinMaxSliderStep();
    end
    
    function set.max(h, new)
        h.max = new;
        
        h.setValueMinMaxSliderStep();
    end
    
    function set.min(h, new)
        h.min = new;
        
        h.setValueMinMaxSliderStep();
    end
    
    % For debugging, override "whos" to dump the size of the class members
    function whos(h)
        origWarn = warning();
        warning off 'MATLAB:structOnObject'
        try
            s = builtin('struct', h); % use 'builtin' in case struct() is overridden
            vsize(s);
        catch
        end
        warning(origWarn);
    end
    end
end