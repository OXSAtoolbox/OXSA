function [out] = search(dicomTree, varargin)
% Search the dicomTree.
%
% The following options must be provided as name/value pairs or a struct.
%
% target: 'study','series','instance'
% return: 'index','study','series','instance'
% query: Function handle or 2x1 cell array of strings or numbers to match
%        against. The function handle form of query is passed up to three
%        arguments i.e. (instance, series, study).
%
% Options include:
% first: if true, only return the first match.
% increment: after matching, advance by this many of the "target" type
%            (i.e. studies/series/instances).
%            This is particularly useful for working around Siemens DICOM
%            studies, where series 99 is a reserved number, so the
%            numbering runs 97,98,100,101.
%            May be a negative number (for a decrement).
%            Error if no such item is found.
%
% If there is no match, an empty array is returned.
%
% EXAMPLES:
%
% First create a dicomTree object:
% dt = Spectro.dicomTree('dir','D:\Users\crodgers\Documents\TrioData\2012-06\20120608_F7T_2012_PH_039 - GK in vivo');
%
% Find all series:
% ret = dt.search('target','series','query',@(varargin) true)
%
% Find instance with a specific UID:
% ret = dt.search('target','instance','query',@(inst,ser,stu) strcmp(inst.SOPInstanceUID,'1.3.12.2.1107.5.2.34.18928.2012060814052482404995281'))
%
% Also find instance with that UID:
% ret = dt.search('target','instance','query',{'SOPInstanceUID','1.3.12.2.1107.5.2.34.18928.2012060814052482404995281'})

% Copyright Chris Rodgers, University of Oxford, 2011.
% $Id: searchForUid.m 5540 2012-06-22 11:08:10Z crodgers $

options = processVarargin(varargin{:});

if ~isfield(options,'target')
    error('target must be specified.');
end

if ~isfield(options,'return')
    options.return = options.target;
end

if ~isfield(options,'query')
    error('query must be specified.');
else
    if iscell(options.query) && numel(options.query) == 2
        % isequal will do string comparison or numeric comparison
        options.query = @(x, varargin) isequal(x.(options.query{1}),options.query{2});
    end
end
    
if ~isfield(options,'first')
    options.first = false;
end

if ~isfield(options,'increment')
    options.increment = 0;
end

% Blank result
switch options.return
    case 'index'
        out = [];
    case 'study'
        
        fn = fieldnames(dicomTree.study)';
        for iDx = 1:numel(fn)
            fn{2,iDx} = {};
        end
        out = struct(fn{:});
        
%         WTC: original code. Made this procedural so that this list can be
%         expanded in the processDicomDir function.        
%         out = struct('StudyInstanceUID', {}, ...
%                      'StudyID', {}, ...
%                      'StudyDescription', {}, ...
%                      'series', {});
    case 'series'
        
        fn = fieldnames(dicomTree.study(1).series)';
        fn{end+1} = 'study';% CTR: Adding link to parent info too.
        for iDx = 1:numel(fn)
            fn{2,iDx} = {};
        end
        out = struct(fn{:});
        
%         WTC: original code. Made this procedural so that this list can be
%         expanded in the processDicomDir function.
%        out = struct('SeriesInstanceUID', {}, ...
%                      'SeriesNumber', {}, ...
%                      'SeriesDescription', {}, ...
%                      'instance', {}, ...
%                      'SeriesDate', {}, ...
%                      'SeriesTime', {}, ...
%                      'study', {}); % CTR: Adding link to parent info too.
    case 'instance'
        
        fn = fieldnames(dicomTree.study(1).series(1).instance)';
        fn{end+1} = 'series';% CTR: Adding link to parent info too.
        for iDx = 1:numel(fn)
            fn{2,iDx} = {};
        end
        out = struct(fn{:});
        
%         WTC: original code. Made this procedural so that this list can be
%         expanded in the processDicomDir function.
%         out = struct('SOPInstanceUID', {}, ...
%                      'InstanceNumber', {}, ...
%                      'Filename', {}, ...
%                      'ImageComment', {}, ...
%                      'series', {}); % CTR: Adding link to parent info too.
    otherwise
        error('Unknown return type.')
end

switch options.target
    case 'instance'
        for studyDx = 1:numel(dicomTree.study)
            thisStudy = dicomTree.study(studyDx);
            
            for seriesDx = 1:numel(thisStudy.series)
                thisSeries = thisStudy.series(seriesDx);
                thisSeries.study = rmfield(thisStudy,'series');
               
                for instanceDx = 1:numel(thisSeries.instance)
                    thisInstance = thisSeries.instance(instanceDx);
                    thisInstance.series = rmfield(thisSeries,'instance');
                    
                    if options.query(thisInstance, thisSeries, thisStudy)
                        outDx = numel(out) + 1;
                        
                        if options.increment == 0
                            returnInstanceDx = instanceDx;
                            returnInstance = thisInstance;
                        else
                            returnInstanceDx = instanceDx + options.increment;
                            if returnInstanceDx >= 1 && returnInstanceDx <= numel(thisSeries.instance)
                                returnInstance = thisSeries.instance(returnInstanceDx);
                                returnInstance.series = rmfield(thisSeries,'instance');
                            else
                                error('It is impossible to apply the requested increment to a matched instance.')
                            end
                        end
                        
                        switch options.return
                            case 'index'
                                out(outDx).studyDx = studyDx;
                                out(outDx).seriesDx = seriesDx;
                                out(outDx).instanceDx = returnInstanceDx;
                            case 'instance'
                                out(outDx) = returnInstance;
                            case 'series'
                                out(outDx) = thisSeries;
                            case 'study'
                                out(outDx) = thisStudy;
                            otherwise
                                error('Incompatible return type specified.')
                        end
                        
                        if options.first
                            return
                        end
                    end
                end
            end
        end
       
    case 'series'
        for studyDx = 1:numel(dicomTree.study)
            thisStudy = dicomTree.study(studyDx);
            
            for seriesDx = 1:numel(thisStudy.series)
                thisSeries = thisStudy.series(seriesDx);
                thisSeries.study = rmfield(thisStudy,'series');
               
                if options.query(thisSeries, thisStudy)
                    outDx = numel(out) + 1;
                    
                    if options.increment == 0
                        returnSeriesDx = seriesDx;
                        returnSeries = thisSeries;
                    else
                        returnSeriesDx = seriesDx + options.increment;
                        if returnSeriesDx >= 1 && returnSeriesDx <= numel(thisStudy.series)
                            returnSeries = thisStudy.series(returnSeriesDx);
                            returnSeries.study = rmfield(thisStudy,'series');
                        else
                            error('It is impossible to apply the requested increment to a matched series.')
                        end
                    end
                    
                    switch options.return
                        case 'index'
                            out(outDx).studyDx = studyDx;
                            out(outDx).seriesDx = returnSeriesDx;
                        case 'series'
                            out(outDx) = returnSeries;
                        case 'study'
                            out(outDx) = thisStudy;
                        otherwise
                            error('Incompatible return type specified.')
                    end
                    
                    if options.first
                        return
                    end
                end
            end
        end
        
    case 'study'
        for studyDx = 1:numel(dicomTree.study)
            thisStudy = dicomTree.study(studyDx);
            
            if options.query(thisStudy)
                outDx = numel(out) + 1;
                
                if options.increment == 0
                    returnStudyDx = studyDx;
                    returnStudy = thisStudy;
                else
                    returnStudyDx = studyDx + options.increment;
                    if returnStudyDx >= 1 && returnStudyDx <= numel(dicomTree.study)
                        returnStudy = dicomTree.study(returnStudyDx);
                    else
                        error('It is impossible to apply the requested increment to a matched study.')
                    end
                end
                
                switch options.return
                    case 'index'
                        out(outDx).studyDx = returnStudyDx;
                    case 'study'
                        out(outDx) = returnStudy;
                    otherwise
                        error('Incompatible return type specified.')
                end
                
                if options.first
                    return
                end
            end
        end
               
    otherwise
        error('Unknown target ("%s").',options.target) 
end
