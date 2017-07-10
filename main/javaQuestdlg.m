function [chosen] = javaQuestdlg(strQuestion, strTitle, strChoices, default, mnemonic)
% Analogue of questdlg that shows more than 3 buttons and has keyboard mnemonics.
%
% Example:
% [chosen] = javaQuestdlg('What to export?','jMRUI Export',{'voxel','range','slice','all'},{'v','r','s','a'})
%
% Returns:
% chosen is the number of the button selected (i.e. an index into the strChoices cell array)
% or
% chosen = [] if the user presses ESC or closes the dialog

% Copyright Chris Rodgers, University of Oxford, 2011-13.
% $Id$

if nargin < 5
    for idx=1:numel(strChoices)
        if numel(strChoices{idx}) ...
                && double(upper(strChoices{idx}(1))) >= double('A') ...
                && double(upper(strChoices{idx}(1))) <= double('Z')
            mnemonic{idx} = upper(strChoices{idx}(1));
        end
    end
end

if nargin < 4
    default = 1;
end

% Needed to prevent Matlab crashing sometimes.
drawnow expose update

for idx=1:numel(strChoices)
    % javaObjectEDT and javaMethodEDT calls avoid GUI crashes.
    % See: http://undocumentedmatlab.com/blog/matlab-and-the-event-dispatch-thread-edt/
    % for details.
    jbtn(idx) = javaObjectEDT('javax.swing.JButton',strChoices{idx});
%     jbtn(idx).setMnemonic(java.awt.event.KeyEvent.VK_B);
    if numel(mnemonic{idx})
        jbtn(idx).setMnemonic(double(upper(mnemonic{idx})));
    end

    jbtn_h(idx) = handle(jbtn(idx), 'CallbackProperties');
    jbtn_h(idx).ActionPerformedCallback = @(varargin) javaQuestdlgCallback(idx,varargin{:});
end

chosen = [];

% Get Java object for current figure to centre dialog
currentFig = get(0,'CurrentFigure');
if isempty(currentFig)
    parentObj = [];
else
    hW = warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    parentObj = handle(currentFig).JavaFrame.getFigurePanelContainer;
    warning(hW);
end

jOP = javaObjectEDT('javax.swing.JOptionPane');
javaMethodEDT('showOptionDialog',jOP,parentObj,strQuestion,strTitle,javax.swing.JOptionPane.YES_NO_CANCEL_OPTION,javax.swing.JOptionPane.QUESTION_MESSAGE,[],jbtn,jbtn(default));

return

function javaQuestdlgCallback(chosenIdx,obj,~)
    javaMethodEDT('dispose',javaMethodEDT('getWindowAncestor','javax.swing.SwingUtilities',obj));
    chosen = chosenIdx;
end
end

