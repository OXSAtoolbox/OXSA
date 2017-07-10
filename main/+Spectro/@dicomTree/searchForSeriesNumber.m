function [out] = searchForSeriesNumber(dicomTree, seriesNumber, varargin)
% Search the study structure for a SeriesNumber.
%
% The structure returned will contain as many of the
% fields studyDx, seriesDx, instanceDx as appropriate.
%
% If there is no match, an empty array [] is returned.

% Copyright Chris Rodgers, University of Oxford, 2011-12.
% $Id: searchForUid.m 4019 2011-03-20 16:02:22Z crodgers $

out = dicomTree.search('target','series','return','index','query',@(ser,stu) any(ser.SeriesNumber == seriesNumber),varargin{:});
