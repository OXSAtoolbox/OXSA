function quickFit_Callback(obj,hObject,eventdata)

% Call the worker function with no parameters so all options will receive
% GUI prompts.


    obj.misc.fittingResults = AMARES.amaresDriver(obj,'type','voxel');
    
    displayQuickFitResults(obj);
    

