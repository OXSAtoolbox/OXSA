function priorList = listAllPkFiles()
% Little helper function that can be easily called in the deployed code
% which returns a list of the prior knowledge file names.

priorDir = fullfile(fileparts(mfilename('fullpath')),'+priorKnowledge');

priorList = dir(fullfile(priorDir,'pk*.m'));