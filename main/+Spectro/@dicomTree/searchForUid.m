function [out] = searchForUid(dicomTree, strUid, bReturnIndex, varargin)
% Search the study structure for a UID.
%
% [out] = searchForUid(dicomTree, strUid, bReturnIndex)
%
% If bReturnIndex is true, or not specified then the structure returned
% will contain as many of the fields studyDx, seriesDx, instanceDx as
% appropriate.
%
% If bReturnIndex is false, an array of structs is returned.
%
% If there is no match, an empty array is returned.

% Copyright Chris Rodgers, University of Oxford, 2011-12.
% $Id: searchForUid.m 6047 2013-01-15 19:04:00Z crodgers $

if nargin < 3
    bReturnIndex = true;
end

% Try searching Study UIDs
if bReturnIndex
    strReturn = 'index';
else
    strReturn = 'study';
end
out = dicomTree.search('target','study','return',strReturn,'query',{'StudyInstanceUID',strUid}, varargin{:});
if ~isempty(out), return, end

% Try searching Series UIDs
if bReturnIndex
    strReturn = 'index';
else
    strReturn = 'series';
end
out = dicomTree.search('target','series','return',strReturn,'query',{'SeriesInstanceUID',strUid});
if ~isempty(out), return, end

% Try searching Instance UIDs
if bReturnIndex
    strReturn = 'index';
else
    strReturn = 'instance';
end
out = dicomTree.search('target','instance','return',strReturn,'query',{'SOPInstanceUID',strUid});
