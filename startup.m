function startup

disp('Wiping the Matlab path...')
restoredefaultpath

format long g
format compact


addpath(genpath(fileparts(mfilename('fullpath'))))


disp('Completed startup.m')