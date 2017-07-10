function startup()
% Add RodgersSpectroTools version 2.1 toolbox to the Matlab search path

% Copyright Chris Rodgers, University of Oxford, 2008-13.
% $Id: startup.m 11600 2017-07-10 14:19:07Z lucian $
disp('Wiping the Matlab path...')
restoredefaultpath


addpath(fileparts(mfilename('fullpath')))

disp('Loaded OXSA version 1 Matlab toolbox')
