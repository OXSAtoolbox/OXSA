function quickFit_Callback(obj,hObject,eventdata)

% Call the worker function with no parameters so all options will receive
% GUI prompts.

if exist('jmruiExportBackend.m', 'file') == 2
    % If jMRUI code is included in the projectSpecific file, allow a choice.
    
    choice = javaQuestdlg('Choose fitting program', ...
        'Fitting Choice', ...
        {'Matlab AMARES','JMRUI'});
    % Handle response
    switch choice
        case 2
            jmruiExportBackend(obj);
            
        case 1
            obj.misc.fittingResults = AMARES.amaresDriver(obj,'type','voxel');
            
            displayQuickFitResults(obj);
            
    end
    
else
    % Main OXSA code. 
    
    obj.misc.fittingResults = AMARES.amaresDriver(obj,'type','voxel');
    
    displayQuickFitResults(obj);
end