% Script to setup paths for the deployExe script
clear variables
close all
clc
%% Paths
baseExportPath = fullfile(fileparts(mfilename('fullpath')),'..');
 
restoredefaultpath

addpath(fullfile(baseExportPath,'main'))
addpath(fullfile(baseExportPath,'utils'))
addpath(genpath(fullfile(baseExportPath, 'deploy')))
addpath(baseExportPath)

%% Now run deployExe script

deployExe
