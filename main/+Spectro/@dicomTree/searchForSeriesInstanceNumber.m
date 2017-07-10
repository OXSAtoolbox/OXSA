function [out] = searchForSeriesInstanceNumber(dicomTree, seriesNumber, instanceNumber, varargin)
% Search the study structure for a SeriesNumber and InstanceNumber.
%
% The structure returned will contain as many of the
% fields studyDx, seriesDx, instanceDx as appropriate.
%
% If there is no match, an empty array [] is returned.

% Copyright Chris Rodgers, University of Oxford, 2011-12.
% $Id: searchForUid.m 4019 2011-03-20 16:02:22Z crodgers $

out = dicomTree.search('target','instance','return','instance','query',@(inst,ser,stu) ser.SeriesNumber == seriesNumber && any(inst.InstanceNumber == instanceNumber), varargin{:});
