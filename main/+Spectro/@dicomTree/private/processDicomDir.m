function [dicomData] = processDicomDir(strDir, strWildcard, bIgnoreCache, bDisplayProgress, bDetailedHdrInfo)
% Scan all files in a directory, find the DICOM files and sort them.
%
% Optionally, restrict the search to files matching a wildcard.

% TODO: Make sorting this tree optional.
% TODO: Allow choice of fields to be extracted.
% TODO: Deal with hash collisions in the cache.
% TODO: Deal with cache files that have different fields.
% TODO: Allow override of the cache filenames.

% $Id: processDicomDir.m 11972 2018-04-26 13:21:49Z will $
% Copyright Chris Rodgers, University of Oxford, 2010-11.

% File format counter: increment to force refresh of cache files.
version = 5;

if ~exist('strWildcard','var')
    strWildcard = '';
end

if ~exist('bIgnoreCache','var')
    bIgnoreCache = false;
end

if ~exist('bDisplayProgress','var')
    bDisplayProgress = true;
end

if ~exist('bDetailedHdrInfo','var')
    bDetailedHdrInfo = false;
end

%% Canonicalise the directory case (for windows)
if ispc()
    strDirNew = GetLongPathName(strDir);
    if numel(strDirNew)>0
        strDir = strDirNew;
    else
        warning('RodgersSpectroTools:GetLongPathName','Failed to find canonical long pathname for "%s".',strDir)
    end
end

%% Check folder exists
if ~exist(strDir,'dir')
    error('RodgersSpectroTools:DirectoryNotFound','Directory not found ("%s").',strDir);
end

%% Check for cache file
cacheFile = fullfile(tempdir(),['processDicomDir_CACHE_' dicomDirHash(strDir, strWildcard) '.mat']);
if ~bIgnoreCache
    try
        cacheData = load(cacheFile);
        
        if cacheData.version == version
            dicomData = cacheData.dicomData;
            return
        else
            clear cacheData
        end
    catch ME
        if ~strcmp(ME.identifier,'MATLAB:load:couldNotReadFile')
            rethrow(ME);
        end
    end
end

%% No matching cache file was found, so we must actually scan directory.
% Initialise dcm4che2 toolkit
dcm4che2_init

% Scan for DICOM files
if nargin >= 2 && ~isempty(strWildcard)
    % Append wildcard if it was supplied
    strDirWithWildcard = fullfile(strDir,strWildcard);
    files = dir(strDirWithWildcard);
elseif exist(fullfile(strDir, 'DICOMDIR'),'file') == 2
    % This directory is a DICOMDIR tree. E.g. CD/DVD.
    % For now, extract all the filenames from the DICOMDIR and then analyse
    % each one in turn below.
    %
    % TODO: For speed, extract the desired parameters directly from the
    %       DICOMDIR.
    
    theDicomdirFile = dir(fullfile(strDir, 'DICOMDIR'));
    theDicomdir = dicominfo(fullfile(strDir, 'DICOMDIR'));
    
    fn = fieldnames(theDicomdir.DirectoryRecordSequence);
    files = [];
    for idx=1:numel(fn)
        if isfield(theDicomdir.DirectoryRecordSequence.(fn{idx}),'ReferencedFileID')
            % The regexp fixes path separators in the DICOMDIR
            files(end+1).name = regexprep(theDicomdir.DirectoryRecordSequence.(fn{idx}).ReferencedFileID, '[\\/]', regexptranslate('escape',filesep()));
            files(end).isdir = 0;
            files(end).bytes = theDicomdirFile.bytes;
            files(end).datenum = theDicomdirFile.datenum;
        end
    end
else
    files = dir(strDir);
end

dicomData.path = strDir;
dicomData.wildcard = strWildcard;

%% Now run through the list of files extracting necessary information
dicomData.study = struct('StudyInstanceUID',{},'StudyID',{},'StudyDescription',{},'series',{});

% Check for cache file with individual instances.
fileCache = containers.Map();
fileHashes = fileNameSizeDateHash(strDir,files);

fileCacheFilename = fullfile(tempdir(),['processDicomDir_CACHE_FILES_' hash(strDir,'md5') '.mat']);
fileCacheOld = [];
if ~bIgnoreCache
    try
        fileCacheOld = load(fileCacheFilename);
        
        if fileCacheOld.version ~= version
            fileCacheOld = [];
        else
            fileCacheOld = fileCacheOld.fileCache;
        end
    catch ME
        if ~strcmp(ME.identifier,'MATLAB:load:couldNotReadFile')
            rethrow(ME);
        end
    end
end

if bDisplayProgress
    progressbar(0);
    % Force progress bar to close when this function returns if it hasn't already
    pbCleanup = onCleanup(@() progressbar(1));
end

for idx = 1:numel(files)
    if bDisplayProgress, progressbar(idx / numel(files)); end
    
    if ~files(idx).isdir
        % Process this DICOM file
        if bDetailedHdrInfo
            [ headersString,headersInt ] = detailedHdrInfo();
            
        else % WTC this is the original information that was read out of the headers.
            headersString = {
                'StudyInstanceUID'  ,'Study';
                'StudyID'           ,'Study';
                'StudyDescription'  ,'Study';
                'SeriesInstanceUID' ,'Series';
                'SeriesDescription' ,'Series';
                'SeriesDate'        ,'Series';
                'SeriesTime'        ,'Series';
                'SOPInstanceUID'    ,'Instance';
                'ImageComments'     ,'Instance';
                };
            
            headersInt = {
                'SeriesNumber'      ,'Series';
                'InstanceNumber'    ,'Instance';
                };
        end
        if ~isempty(fileCacheOld) && fileCacheOld.isKey(fileHashes{idx})
            % Load the cached results for this particular DICOM file.
            d = fileCacheOld(fileHashes{idx});
            
            % Skip files known not to be DICOM files.
            if isfield(d,'notDicom') && d.notDicom
                continue;
            end
        elseif ~bIgnoreCache && exist(fullfile(strDir,[files(idx).name '.mat']),'file')
            % Load .mat file saved by CTR v3 storescp.exe if it exists
            % fprintf('~'); % For debugging. See how many MAT files used.
            d = load(fullfile(strDir,[files(idx).name '.mat']));
            d.Filename = fullfile(strDir,files(idx).name);
        else
            % Read this DICOM file and extract key data.
            d = [];
            d.Filename = fullfile(strDir,files(idx).name);
            
            % Catch a Java error if it is not a DICOM file.
            % Profiling confirms that the try..catch block is faster than
            % calling dicomCheckMagic(...)
            try
                dcm = dcm4che2_readDicomFile(d.Filename);
            catch ME
                % Catch errors that are due to this not being a DICOM file, but
                % report other errors e.g. out of memory.
                %
                % org.dcm4che2.io.DicomCodingException: Not a DICOM Stream
                
                if strcmp(ME.identifier,'MATLAB:Java:GenericException')
                    msg = regexp(ME.message,'^[^\n\r]*[\n\r]([^\n\r]*)','once','tokens');
                    
                    if strcmp(msg{1},'org.dcm4che2.io.DicomCodingException: Not a DICOM Stream') ...
                            || strcmp(msg{1},'java.io.EOFException')
                        d.notDicom = true;
                        % Cache these results for future re-use
                        fileCache(fileHashes{idx}) = d;
                        continue;
                    end
                    
                    % Ignore errors from non-DICOM files.
                    % This check is slower for most files than that above.
                    if ~dicomCheckMagic(d.Filename)
                        d.notDicom = true;
                        % Cache these results for future re-use
                        fileCache(fileHashes{idx}) = d;
                        continue;
                    end
                end
                
                if bDisplayProgress
                    % Force progress bar to close if it hasn't already
                    progressbar(1);
                end
                
                % Any other error should be rethrown
                ME_new = MException('Spectro:dicomTree:Error','Error while processing file "%s":\n',d.Filename);
                ME_new = addCause(ME_new,ME);
                throw(ME_new);
            end
            
            % Read required fields from the DICOM headers
            % Option to read out more detailed information and store in the
            % dicomTree struct.
            if bDetailedHdrInfo
                [ headersString,headersInt ] = detailedHdrInfo();
                
            else % WTC this is the original information that was read out of the headers.
                headersString = {
                    'StudyInstanceUID'  ,'Study';
                    'StudyID'           ,'Study';
                    'StudyDescription'  ,'Study';
                    'SeriesInstanceUID' ,'Series';
                    'SeriesDescription' ,'Series';
                    'SeriesDate'        ,'Series';
                    'SeriesTime'        ,'Series';
                    'SOPInstanceUID'    ,'Instance';
                    'ImageComments'     ,'Instance';
                    };
                
                headersInt = {
                    'SeriesNumber'      ,'Series';
                    'InstanceNumber'    ,'Instance';
                    };
            end
            
            for headerDx = 1:size(headersString,1)
                d.(headersString{headerDx,1}) = char(dcm.getStrings(org.dcm4che2.data.Tag.(headersString{headerDx,1})));
                if size(d.(headersString{headerDx,1}),1) >1
                    d.(headersString{headerDx,1}) = cell(dcm.getStrings(org.dcm4che2.data.Tag.(headersString{headerDx,1})));
                end
            end
            for headerDx = 1:size(headersInt,1)
                d.(headersInt{headerDx,1}) = dcm.getInt(org.dcm4che2.data.Tag.(headersInt{headerDx,1}));
            end
        end
        
        % Cache these results for future re-use
        fileCache(fileHashes{idx}) = d;
        
        %% Build index
        % Build index of studies
        myStudyDx = find(strcmp({dicomData.study.StudyInstanceUID},d.StudyInstanceUID));
        if isempty(myStudyDx)
            myStudyDx = numel(dicomData.study) + 1;
            
            studyFields = headersString(strcmp(headersString(:,2),'Study'));
            studyFields = [studyFields ; headersInt(strcmp(headersInt(:,2),'Study'))];
            
            seriesFields = headersString(strcmp(headersString(:,2),'Series'));
            seriesFields = [seriesFields ; headersInt(strcmp(headersInt(:,2),'Series'))];
            
            instanceFields = headersString(strcmp(headersString(:,2),'Instance'));
            instanceFields = [instanceFields ; headersInt(strcmp(headersInt(:,2),'Instance'))];
            
            dicomData.study(myStudyDx).series = struct('SeriesInstanceUID',{},'SeriesNumber',{},'SeriesDescription',{},'instance',{});
        end
        
        for iDx = 1:numel(studyFields)
            dicomData.study(myStudyDx).(studyFields{iDx}) = d.(studyFields{iDx});
        end
        
        
        % Build index of series
        mySeriesInstanceUID = d.SeriesInstanceUID;
        mySeriesDx = find(strcmp({dicomData.study(myStudyDx).series.SeriesInstanceUID},mySeriesInstanceUID));
        if isempty(mySeriesDx)
            mySeriesDx = numel(dicomData.study(myStudyDx).series) + 1;
            dicomData.study(myStudyDx).series(mySeriesDx).instance = struct('SOPInstanceUID',{},'InstanceNumber',{});
        end
        
        for iDx = 1:numel(seriesFields)
            dicomData.study(myStudyDx).series(mySeriesDx).(seriesFields{iDx}) = d.(seriesFields{iDx});
        end
        
        
        % Build index of instances
        % All files present are loaded, which includes duplicates.
        myInstanceDx = numel(dicomData.study(myStudyDx).series(mySeriesDx).instance) + 1;
        
        for iDx = 1:numel(instanceFields)
            dicomData.study(myStudyDx).series(mySeriesDx).instance(myInstanceDx).(instanceFields{iDx}) = d.(instanceFields{iDx});
        end
        dicomData.study(myStudyDx).series(mySeriesDx).instance(myInstanceDx).Filename = d.Filename;
        
    end
end

% Sort the data before returning because we'll almost always want this
for StudyDx=1:numel(dicomData.study)
    for SeriesDx=1:numel(dicomData.study(StudyDx).series)
        [tmp, sortDx] = sort([dicomData.study(StudyDx).series(SeriesDx).instance.InstanceNumber]);
        dicomData.study(StudyDx).series(SeriesDx).instance = dicomData.study(StudyDx).series(SeriesDx).instance(sortDx);
    end
    [tmp, sortDx] = sort([dicomData.study(StudyDx).series.SeriesNumber]);
    dicomData.study(StudyDx).series = dicomData.study(StudyDx).series(sortDx);
end
[tmp, sortDx] = sort({dicomData.study.StudyID}); % These are strings - hence different sort syntax.
dicomData.study = dicomData.study(sortDx);

% fprintf('\n'); % For debugging. See how many MAT files used.

% Save in cache file.
try
    save(cacheFile,'dicomData','version');
catch
    warning('Cannot save cache file: "%s".', cacheFile);
end

try
    save(fileCacheFilename,'fileCache','version');
catch
    warning('Cannot save cache file: "%s".', fileCacheFilename);
end
end
        
function [dcm] = dcm4che2_readDicomFile(strFile)
% Load DICOM file with the dcm4che2 toolkit

% Uncomment these tic/toc lines to profile DICOM file scanning.
% tic
din = org.dcm4che2.io.DicomInputStream(java.io.File(strFile));

% Skip over large private tags when reading
% Based on http://sourceforge.net/p/dcm4che/mailman/dcm4che-commits/thread/E1Sf9yy-0005p2-9q@sfp-svn-4.v30.ch3.sourceforge.com/
ih1 = org.dcm4che2.io.StopTagInputHandler(org.dcm4che2.data.Tag.PixelData);
ih2 = org.dcm4che2.imageioimpl.plugins.dcm.SizeSkipInputHandler(ih1);
% If desired the setPrivateSkipSize and setPublicSkipSize methods can be
% called on ih2 to control what data gets loaded.
din.setHandler(ih2);

% Now read DICOM
dcm = din.readDicomObject();

% Close the input stream so the DICOM file doesn't remain locked
din.close();

% fprintf('%g ms for\t''%s''\n',toc(),strFile);

end

function dcm4che2_init()
% Check first that the Java path is set properly
% Then add the java libraries to your path
checkjava = which('org.dcm4che2.io.DicomInputStream');
if isempty(checkjava)
    % Matlab compiler script include:
    %#include ../../../dcm4che/dcm4che-2.0.28-bin/dcm4che-2.0.28/lib/*.jar
    libpath = fullfile(fileparts(mfilename('fullpath')),'..','..','..','dcm4che','dcm4che-2.0.28-bin','dcm4che-2.0.28','lib');
    javaaddpath(fullfile(libpath,'dcm4che-core-2.0.28.jar'));
    javaaddpath(fullfile(libpath,'dcm4che-image-2.0.28.jar'));
    javaaddpath(fullfile(libpath,'dcm4che-imageio-2.0.28.jar'));
    javaaddpath(fullfile(libpath,'dcm4che-iod-2.0.28.jar'));
    javaaddpath(fullfile(libpath,'slf4j-api-1.6.1.jar'));
    javaaddpath(fullfile(libpath,'slf4j-log4j12-1.6.1.jar'));
    javaaddpath(fullfile(libpath,'log4j-1.2.16.jar'));
    
    import org.dcm5che2.*
    
    checkjava = which('org.dcm4che2.io.DicomInputStream');
    
    if isempty(checkjava)
        error('Cannot load dcm4che2 v2.0.28 toolkit.')
    end
end
end
