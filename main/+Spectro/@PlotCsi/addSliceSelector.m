function [jhSpinner, jhSpinnerComponent] = addSliceSelector(hFig, startSlice, minSlice, maxSlice, pos, callback, tooltip)
% Add a Java spinner control for the slice selection
%
% 
% CODE SAMPLES:
% =============
%
% %% The callback function should have this syntax:
% function sliceChangedCallback(jSpinner,jEventData)
%
% % Access the current value:
% fprintf('Slice changed callback executing: Slice = %d\n',jSpinner.getValue())
%
% % Using a persistent variable simulates a mutex for this code
% persistent inCallback
% try
%     if ~isempty(inCallback),  return;  end
%     inCallback = 1;  %#ok used
%     newMonthStr = jhSpinnerM.getValue;
%     newMonthIdx = find(strcmpi(months,newMonthStr));
%     newYear = jhSpinnerY.getValue;
%     calendar.set(newYear,newMonthIdx-1,1,12,0);
%     jhSpinnerD.setValue(calendar.getTime);
% catch
%     a=1; % never mind...
% end
% inCallback = [];

% License to use and modify this code is granted freely to all interested, as long as the original author is
% referenced and attributed as such. The original author maintains the right to be solely associated with this work.

% Programmed and Copyright by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.0 $  $Date: 2010/03/16 15:57:23 $

error(javachk('swing',mfilename)) % ensure that Swing components are available

% Create the demo figure
color = get(hFig,'Color');
colorStr = mat2cell(color,1,[1,1,1]);
jColor = java.awt.Color(colorStr{:});

slicesModel = javax.swing.SpinnerNumberModel(startSlice,minSlice,maxSlice,1);
% jhSpinnerY = addLabeledSpinner('&Year', slicesModel, [70,80,40,100], @sliceChangedCallback);
[jhSpinner, jhSpinnerComponent] = addLabeledSpinner('', slicesModel, pos, callback);
jEditor = javaObject('javax.swing.JSpinner$NumberEditor',jhSpinner, '#');
jhSpinner.setEditor(jEditor);

if nargout,  hFigOut = hFig;  end

% Add a label attached to a spinner
    function [jhSpinner, jhSpinnerComponent] = addLabeledSpinner(label,model,pos,callbackFunc)
        % Set the spinner control
        jSpinner = com.mathworks.mwswing.MJSpinner(model);
        %jTextField = jSpinner.getEditor.getTextField;
        %jTextField.setHorizontalAlignment(jTextField.RIGHT);  % unneeded
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