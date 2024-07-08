function startup

disp('Wiping the Matlab path...')
restoredefaultpath

format long g
format compact


addpath(genpath(fileparts(mfilename('fullpath'))))


disp('OXSA version 2.1: completed startup.m')
