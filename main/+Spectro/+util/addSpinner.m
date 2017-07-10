function [jhSpinner, jhSpinnerComponent] = addSpinner(hFig, start, min, max, pos, callback, tooltip,varargin)
% Add a Java spinner control

% License to use and modify this code is granted freely to all interested, as long as the original author is
% referenced and attributed as such. The original author maintains the right to be solely associated with this work.

% Programmed and Copyright by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.0 $  $Date: 2010/03/16 15:57:23 $

options = processVarargin(varargin{:});

% Fetch handle object for figure global variables
stored = guidata(hFig);

error(javachk('swing',mfilename)) % ensure that Swing components are available

% Create the demo figure
color = get(hFig,'Color');
colorStr = mat2cell(color,1,[1,1,1]);
jColor = java.awt.Color(colorStr{:});

if isfield(options,'step')
    slicesModel = javax.swing.SpinnerNumberModel(start,min,max,options.step);
else
    slicesModel = javax.swing.SpinnerNumberModel(start,min,max,1);
end


[jhSpinner, jhSpinnerComponent] = addLabeledSpinner('', slicesModel, pos, callback, tooltip);
jEditor = javaObject('javax.swing.JSpinner$NumberEditor',jhSpinner, '#');
jhSpinner.setEditor(jEditor);

jhSpinner.setFocusable(true);

if nargout,  hFigOut = hFig;  end

% Add a label attached to a spinner
    function [jhSpinner, jhSpinnerComponent] = addLabeledSpinner(label,model,pos,callbackFunc, tooltip)
        % Set the spinner control
        jSpinner = com.mathworks.mwswing.MJSpinner(model);
        [jhSpinner, jhSpinnerComponent] = javacomponent(jSpinner,pos,hFig);
        jhSpinner.setToolTipText(tooltip)
        set(jhSpinner,'StateChangedCallback',callbackFunc);
        
        % Set the attached label
        if ~isempty(label)
            jLabel = com.mathworks.mwswing.MJLabel(label);
            jLabel.setLabelFor(jhSpinner);
            jLabel.setBackground(jColor);
            if jLabel.getDisplayedMnemonic > 0
                hotkey = char(jLabel.getDisplayedMnemonic);
                jLabel.setToolTipText(['<html>Press <b><font color="blue">Alt-' hotkey '</font></b> to focus on<br/>adjacent spinner control']);
            end
            pos = [20,pos(2),pos(1)-20,pos(4)];
            jhLabel = javacomponent(jLabel,pos,hFig);
        end
    end  % addLabeledSpinner
end