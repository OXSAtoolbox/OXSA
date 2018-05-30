function [params, numParams, endStr, plainStr] = getCanonicalOrdering()
%Gives parameters in canonical ordering for any function that combines
%them into a matrix
%Lucian A. B. Purvis 2017

params = {'chemShift','linewidth','amplitude','phase','sigma'};
numParams = numel(params);

%These strings are used by the symbolic toolbox
endStr = {'_cs','_lw','_am','_ph','_sg'};
plainStr = {'cs','lw','am','ph','sg'};
