function [obj] = ProcessLong31pSpectra(theDicomPathOrTree, spectraUid, refUid, varargin)
% Load 31P CSI dataset and process it to correct for saturation and
% blood contamination as best as we can.
%
% spectraUid may either be a string containing the DICOM series UID to be
% loaded, or a cell array of individual DICOM instances to be loaded.
%
% Supported options (all passed through to subroutines):
%
% simulateVoltage. Override voltage from protocol. See loadSequenceParams__UTE_CSI.m
%

% TODO - This should be a subclass of Spectro.PlotCsi.
% TODO - And in the longer term, the useful methods should be merged into
%        the main code.

% Copyright Chris Rodgers, University of Oxford, 2010-11.
% $Id: ProcessLong31pSpectra.m 8264 2015-03-27 17:59:39Z lucian $

%% Merge extra options if provides
optNew = processVarargin(varargin{:});

%% Load the DICOM data
optNew.keepFids = 1;
optNew.debug = 1;
if nargin >= 3 && ~(isnumeric(refUid) && isempty(refUid)) % [] will make refUid be ignored.
    optNew.refUid = refUid;
end

%% Set options
warning('off','Spectro:PlotCsi:calcPlaneIntersect')

%% Plot the data
obj = Spectro.PlotCsi(theDicomPathOrTree, spectraUid, optNew);

