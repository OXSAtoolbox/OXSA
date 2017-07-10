classdef dicomTree < handle
% Scan a directory for DICOM files using a disk-based cache to provide
% information regarding previously scanned files with high performance.
%
% REPLACES processDicomDir.m and related functions.

% Copyright Chris Rodgers, University of Oxford, 2010-12.
% $Id: PlotCsi.m 4072 2011-04-08 13:30:59Z crodgers $

% Public properties
properties
    debug = false; % Debug output is printed to the Command Window when debug is true.
end

properties(SetAccess=protected)
    path;
    study;
    wildcard;
    recursive;
end

methods
    function dt = dicomTree(varargin)
        % Scan the specified folder(s) for DICOM files, returning a Spectro.dicomTree object.
        %
        % Input is a struct or name/value pairs for the following options:
        %
        % dir: (REQUIRED) the folder to scan.
        % wildcard: restrict the search to files matching this wildcard.
        % recursive: also scan subfolders if true.
        %
        % OR:
        %
        % Input can be a STRUCT containing the information from a
        % dicomTree search.
        
        % Construct from a pre-prepared struct
        if nargin == 1 && isstruct(varargin{1}) && isfield(varargin{1},'study')
            % TODO: This may need some version tagging.
            % TODO: Make this the basis for save / load of the dicomTree object.
            % TODO: When loading, give a warning if the DICOM path has
            %       moved / gone away.

            dt.study = varargin{1}.study;
            
            if isfield(varargin{1},'path')
                dt.path = varargin{1}.path;
            end
            
            if isfield(varargin{1},'wildcard')
                dt.wildcard = varargin{1}.wildcard;
            end
            
            return
        end
                
        % Construct by scanning disk
        options = processVarargin(varargin{:});
        
        if ~isfield(options,'dir')
            error('Directory to scan must be specified.')
        end
        
        if ~isfield(options,'wildcard')
            options.wildcard = '';
        end
        
        if ~isfield(options,'recursive')
            options.recursive = false;
        end
        
        if ~isfield(options,'ignoreCache')
            options.ignoreCache = false;
        end
        
        if options.recursive
            tmp = processDicomDirRecursive(options.dir, false, options.wildcard, options.ignoreCache);
        else
            tmp = processDicomDir(options.dir, options.wildcard, options.ignoreCache);
        end
        
        dt.path = tmp.path;
        dt.wildcard = tmp.wildcard;
        dt.study = tmp.study;
        dt.recursive = options.recursive;
    end
    
    function mergeInto(dt,dtOther)
        % Merge the contents of another Spectro.dicomTree object into this one.
        error('Not yet implemented.')
    end
    
    function rescan(dt)
        % Scan the folder for new/updated files. These will be appended to
        % the study/series/instance structure. Existing files WILL NOT
        % change their index.
        
        % TODO: Decide how to mark deleted files.
        % TODO: Store options for use with this.
        error('Not yet implemented.')
    end
    
    % Other methods
    [out] = search(dicomTree, varargin);
    
    % Placeholders for obsolete methods
    [out] = searchForSeriesInstanceNumber(dicomTree, seriesNumber, instanceNumber, varargin)
    [out] = searchForSeriesNumber(dicomTree, seriesNumber, varargin)
    [out] = searchForUid(dicomTree, strUid, bReturnIndex, varargin)
    
    prettyPrint(dicomTree, bShowInWindow)
    
    % TODO: Add a method for iterating through the tree.
end
end