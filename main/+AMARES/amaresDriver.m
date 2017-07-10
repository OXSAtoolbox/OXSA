function res = amaresDriver(obj,varargin)
% Runs AMARES.amares on the contents of a Spectro.PlotCsi or Spectro.Spec object,
% prompting the user for parameters if they have not been specified.
% 
% Function to choose and load Prior Knowledge, create tempory save file,
% select or read in a begin time (excitation to ADC), run the matlab-AMARES
% fitting algorithm.
%
% Parameters:
%
% obj: Spectro.Spec or Spectro.PlotCsi object containing the data to be
%      fitted.
%
% Any of the following parameters in a struct or as name/value pairs.
%
% "type"
% "coils"
% "plot" : whether to plot the fits in each voxel
%          true = plot into the next figure
%          double = plot into the specified figure
%          false = do not plot
%          function handle = call this function for each sliceDx, voxDx.
%                            The function must return true/double/false
%                            as above.
%
% N.B. This function was mostly copied from jmruiExportBackend.m

% TODO:
% * Allow multi-coil fitting.

%% Allow either a Spectro.PlotCsi or Spectro.Spec object
if isa(obj,'Spectro.PlotCsi')
    spec = obj.data.spec;
elseif isa(obj,'Spectro.Spec')
    spec = obj;
    obj = [];
else
    error('Supplied object must be a Spectro.PlotCsi or Spectro.Spec object, or an array of Spectro.Spec objects.')
end

options = processVarargin(varargin{:});


% Check options OK
possibleTypes = {'voxel','range','slice','all'};
if isfield(options,'type')
    if ~any(strcmp(options.type, possibleTypes))
        error('Unknown selection type "%s" requested.',options.type)
    end
else
    if isempty(obj)
        % Spectro.Spec objects are exported in total by default.
        options.type = 'all';
    else
        % For GUI (Spectro.PlotCsi objects) prompt the user.
        options.type = possibleTypes{javaQuestdlg('What to export?','Matlab AMARES Export',possibleTypes)};
    end
end



%% Coils
if ~isfield(options,'coils')
    if spec(1).coils == 1
        options.coils = 1;
    else
        % Display dialog box to select coils to export.
        [options.coils,coilsOk] = listdlg('ListString',spec(1).coilStrings,'SelectionMode','single','ListSize',[350 400],'PromptString','Select coils to export...','InitialValue',spec(end).coils); % Single selection presently as multiple coil fitting has not been implemented for matlab AMARES.
        drawnow;
        if ~coilsOk
            error('Aborted by user.')
        end
        clear coilsOk
    end
end

% Combine coil names for output
coilStringsFull = joinrow2str(spec(1).coilStrings(options.coils),'%s','+');
if numel(options.coils) == 1
    coilStringsShort = sprintf('Coil=%s',spec(1).coilStrings{options.coils});
else
    coilMd5 = hash(joinrow2str(spec(1).coilStrings(options.coils),'%s',char(0)),'md5');
    coilStringsShort = sprintf('%dcoils-%s',numel(options.coils),coilMd5(1:8));
end

% CSI shift
csiShiftStr = regexprep(num2str(obj.csiShift),'\s*','_');

%% Generate a suitable directory name
if isfield(spec(1).info{1}.PatientName,'GivenName')
    givenName = spec(1).info{1}.PatientName.GivenName;
else
    givenName = '';
end

if isfield(spec(1).info{1}.PatientName,'FamilyName')
    familyName = spec(1).info{1}.PatientName.FamilyName;
else
    familyName = '';
end

if numel(givenName) > 0 || numel(familyName) > 0
    directory = sprintf('%s_%s',...
    regexprep(givenName,'[^A-Za-z0-9 \(\)-]','~'),...
    regexprep(familyName,'[^A-Za-z0-9 \(\)-]','~'));
else
    directory = regexprep(spec(1).info{1}.PatientID,'[^A-Za-z0-9 \(\)-]','~');
end

% Append the study UID
directory = [directory '_' regexprep(spec(1).info{1}.StudyInstanceUID,'[^A-Za-z0-9 \(\)-]','~')];

% Folder to cache results
if ~isdeployed()
    directoryFullPath = fullfile(RodgersSpectroToolsRoot,'Fitting_work',directory);
else
    rootFolder = getenv('31P_CACHE')
    if isempty(rootFolder)
        rootFolder = tempdir()
    end
    directoryFullPath = fullfile(rootFolder,directory);
end

% Make directory (and ignore error if it already exists)
[tmp1,tmp2,tmp3]=mkdir(directoryFullPath); %#ok<NASGU,ASGLU>
clear tmp1 tmp2 tmp3

if ~isfield(spec(1),'csiInterpolated')
    interp = 'asInDicom';
else
    if spec(1).csiInterpolated
        interp = 'interp';
    else
        interp = 'deInterp';
    end
end

if isfield(options,'extraFilenameText')
    extraFilenameText = ['_' options.extraFilenameText];
else
    extraFilenameText = '';
end

%% Generate filename and voxel list for each batch of data.
if strcmp(options.type, 'all')
    options.slices = 1:spec(1).slices;
end

if strcmp(options.type, 'slice') && ~isfield(options,'slices')
    if isempty(obj)
        error('options.slice must be specified for a Spectro.Spec object export.')
    else
        options.slices = obj.csiSlice;
    end
end

if strcmp(options.type, 'voxel') && ~isfield(options,'voxels')
    if isempty(obj)
        error('options.voxels must be specified for a Spectro.Spec object export.')
    else
        options.voxels = {obj.voxel};
        options.slices = 0;
    end
end

if strcmp(options.type, 'slice') || strcmp(options.type, 'all')
    for idx = 1:numel(options.slices)
        nVoxelMin = spec(1).idxInSliceAndSliceToVoxel(1,options.slices(idx));
        nVoxelMax = spec(1).idxInSliceAndSliceToVoxel(spec(1).rows*spec(1).columns,options.slices(idx));

        options.voxels{idx} = nVoxelMin:nVoxelMax;
        
        options.filename{idx} = sprintf(['%s%cS%d_%s_%s_Slice%0.2d_CSIShift%s_%s.txt'],...
            directoryFullPath,...
            filesep(),...
            spec(1).info{1}.SeriesNumber,...
            regexprep(coilStringsShort,'[^A-Za-z0-9 \(\)-]','~'),...
            interp,...
            options.slices(idx),...
            csiShiftStr,...
            extraFilenameText);
    end
end

voxStrings = cellfun(@(v) regexprep(vec2str(v),{'([\ | \])';':';' ';','},{'','-','','+'}),options.voxels,'UniformOutput',false);
% Shorten voxel string to make reasonable filename
for idx = 1:numel(options.voxels)
       if numel(voxStrings{idx})>30
        voxStrings{1} = voxStrings{1}(1:30);
    end
end

if strcmp(options.type, 'voxel')
    for idx = 1:numel(options.voxels)
        options.filename{idx} = sprintf(['%s%cS%d_%s_%s_Vox%s_CSIShift%s%s.txt'],...
            directoryFullPath,...
            filesep(),...
            spec(1).info{1}.SeriesNumber,...
            regexprep(coilStringsShort,'[^A-Za-z0-9 \(\)-]','~'),...
            interp,...
            voxStrings{idx},...
            csiShiftStr,...
            extraFilenameText);
    end
end

%% Run AMARES fitting.
% Check whether AMARES result files exist and offer chance to bail out.
for sdx = 1:numel(options.slices)
    amaresOutputFilenameTxt{sdx} = [options.filename{sdx}(1:end-4) '_AMARES_RESULTS.txt']; %#ok<AGROW>
    amaresOutputFilenameMat{sdx} = [options.filename{sdx}(1:end-4) '_AMARES_RESULTS.mat']; %#ok<AGROW>
    screenShotFilename{sdx} = [options.filename{sdx}(1:end-4) '_FITTED_PLOT.png']; %#ok<AGROW>
    amaresPriorKnowledgeFilename{sdx} = [options.filename{sdx}(1:end-4) '_PK.mat']; %#ok<AGROW>
    
    % Get the md5 checksum for the fids to checkt hat we are running on the
    % same data 
    [~, fids_md5{sdx}] = gatherFids(spec,options,sdx);

end



if all(cellfun(@(x) exist(x,'file'),amaresOutputFilenameMat)) ...
        && all(cellfun(@(x) exist(x,'file'),amaresPriorKnowledgeFilename)) ...
        ... % Allow override to always process...        
        && ~(isfield(options,'forceFitAgain') && options.forceFitAgain)
   % Files do exist
   if isfield(options,'forceFitAgain') && options.forceFitAgain == true
       forceRerun = true;
   else 
        forceRerun = false;
   end
   wdx = 1;
   while wdx <= numel(options.voxels) && ~forceRerun
       % Read the saved text file
       pastResTxt = fileread(amaresOutputFilenameTxt{wdx});
       previousFIDsHash = regexp(pastResTxt,'(?<=FIDs hash: ).*(?=\n)','match');


       if isempty(previousFIDsHash) || strcmp(previousFIDsHash,'')
           warning('No FIDs hash saved in past data, forcing rerun')  
           forceRerun = true;
       elseif ~strcmp(previousFIDsHash{1},fids_md5{wdx})
           warning('Matlab AMARES cache file ("%s") already exists, but with the wrong content.',amaresOutputFilenameTxt{1})
           forceRerun = true; 
       end   

       % Check that the CSI shift vector is the same   
       savedCSIShift = regexp(pastResTxt,'(?<=CSI Shift vector: ).*?(?=\n)','match');
       if isempty(savedCSIShift) || strcmp(savedCSIShift,'')
           warning('No CSIshift saved in past data, forcing rerun!')
           forceRerun = true;
       elseif ~all(str2num(savedCSIShift{1}) == obj.csiShift)
             warning('The CSI shift does not match the saved data! Fitting again...')  
             forceRerun = true;
       end
       
       wdx = wdx + 1;
   end
   
   if forceRerun
        theChoice = 1;
        
   else   
       % Prompt what to do unless already specified in the options...
       if isfield(options,'forceFitAgain') && options.forceFitAgain == false
           theChoice = 2;             
       else
           theChoice = javaQuestdlg('Launch AMARES ?','AMARES',{'Launch AMARES','Keep previous results','Stop'});
       end

   end
   % Now do it
   switch theChoice
       case 2
            for tmpdx = 1:numel(amaresOutputFilenameMat)
                tmpLoad = load(amaresOutputFilenameMat{tmpdx});
                res{tmpdx} = tmpLoad.results;
                
                % Patch up filenames in case data was copied from another
                % computer.
                % TODO: Check this is OK in case of multiple voxel sets.
                res{tmpdx}.options.amaresOutputFilenameTxt = amaresOutputFilenameTxt;
                res{tmpdx}.options.amaresOutputFilenameMat = amaresOutputFilenameMat;
                res{tmpdx}.options.screenShotFilename = screenShotFilename;
                res{tmpdx}.options.amaresPriorKnowledgeFilename = amaresPriorKnowledgeFilename;
            end
           return
       case 3
           return
   end
 end

 %% Choose and load relavent prior knowledge.
if ~isfield(options,'prior') || ~isfield(options.prior,'dir')
    options.prior.dir = fullfile(fileparts(mfilename('fullpath')),'+priorKnowledge');
end

if ~isfield(options.prior,'pk')
    % Prior not supplied - so prompt user for a .m file to run or a
    % .mat file to load.
    priorFiles = dir(fullfile(options.prior.dir,'pk*.m'));
    priorFunctionNames = arrayfun(@(x) regexprep(x.name,'\.m',''),priorFiles,'uniformoutput',false);
    if ~isfield(options.prior,'default')
              
            if abs(7.0 - spec(1).info{1}.csa.MagneticFieldStrength) < 0.2
                % 7T data
                options.prior.default = 'PK_7T_Cardiac';
            elseif abs(3.0 - spec(1).info{1}.csa.MagneticFieldStrength) < 0.2
                % 3T data
                options.prior.default = 'PK_3T_Cardiac';
            else
                warning('No default prior for this field strength.');
            end
     
    end
    priorInitial = find(strcmp(options.prior.default,priorFunctionNames));
    
    if isempty(priorFunctionNames)
        error('No prior knowledge files found in "%s".',options.prior.dir);
    end
    
    [priorDx,priorOk] = listdlg('ListString',priorFunctionNames,'SelectionMode','single','ListSize',[350 400],'PromptString','Select prior knowledge to use...','InitialValue',priorInitial,'CancelString','Load saved data');
    drawnow
    
    if ~priorOk
        [pkFileName,pkPathName,~] = uigetfile(fullfile(mfilename('fullpath'),'..','+priorKnowledge','Saved Prior Knowledge'));
        
        if pkFileName == 0
            error('Aborted by user.')
        end
        options.prior.filename = [pkPathName pkFileName];
        pk = load(options.prior.filename);
    else
        options.prior.functionName = ['AMARES.priorKnowledge.' priorFunctionNames{priorDx}];
        pk = feval(options.prior.functionName);
    end
    
    clear priorFiles priorFilenames priorInitial priorDx priorOk
elseif isstruct(options.prior.pk)
    % pk struct has been supplied
    options.prior.functionName = 'Custom PK';
    pk = options.prior.pk;

elseif isa(options.prior.pk,'function_handle') 
    options.prior.functionName = func2str(options.prior.pk);
    pk = feval(options.prior.pk);
end

% Store the prior knoweldge for posterity
save(amaresPriorKnowledgeFilename{1},'-struct','pk');


if isfield(options,'BATP_SNRCheck')
    checkBATP_SNR = true;
    BATP_SNRLimit = options.BATP_SNRCheck{1};
    pkConstrained = pk;
    pkConstrained.bounds(1).linewidth = options.BATP_SNRCheck{2}; 
    peakHeight = @(c,a) c*(1/(a/2)) ; % Assuming a Cauchy/Lorentzian peak shape http://en.wikipedia.org/wiki/Cauchy_distribution c is amplitude a is linewidth 

else
    checkBATP_SNR = false;
    
end

%%

% Expected offset in ppm
if isfield(options,'expectedOffset')
    expectedOffset = options.expectedOffset;
elseif isprop(obj,'misc') && isfield(obj.misc,'sequenceParams') && isfield(obj.misc.sequenceParams,'expectedoffset')
    expectedOffset = obj.misc.sequenceParams.expectedoffset;
else
    prompt = {'Enter expected offset (ppm):'};
    dlg_title = 'Input for expected offset';
    num_lines = 1;
    def = {'0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    drawnow
    expectedOffset = str2double(answer{1}); % Expected offset in ppm
end

% Calculate begintime
if isfield(options,'beginTime')
    beginTime = options.beginTime;
else
    prompt = {'Enter begin time (ms):'};
    dlg_title = 'Input for begin time';
    num_lines = 1;
    def = {'0.32'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    drawnow
    beginTime = str2double(answer{1})/1000; % Begin time in s
end  

%% Should we plot?
if isfield(options,'plot')
    plotFlag = options.plot;
else
    plotFlag = 8008;
end

%% Matlab AMARES automated analysis of the data picked out above
% Store filenames for output
options.amaresOutputFilenameMat = amaresOutputFilenameMat;
options.amaresOutputFilenameTxt = amaresOutputFilenameTxt;
options.amaresPriorKnowledgeFilename = amaresPriorKnowledgeFilename;

if isa(plotFlag,'function_handle') || plotFlag
    options.screenShotFilename = screenShotFilename;
end

%% Call Amares worker function do complete fit.
startTime = clock();
results = [];
BATP_counter = 0;
for sdx = 1:numel(options.slices)
    for vdx = 1:numel(options.voxels{sdx})
        fprintf('sdx = %d/%d.\tvdx = %d/%d.\tTime = %.1fs\n',sdx,numel(options.slices),vdx,numel(options.voxels{sdx}),etime(clock(),startTime));
        
        voxelNum = options.voxels{sdx}(vdx);
        
        % Check if we should plot for this voxel
        if ~isa(plotFlag,'function_handle')
            plotFlagThisVoxel = plotFlag;
        else
            plotFlagThisVoxel = feval(plotFlag,voxelNum,sdx,vdx)
        end
   
        % TODO. Multiple coil fits
        if numel(options.coils) ~= 1
            error('Multi-coil fitting has not yet been implemented for MATLAB AMARES.')
        end
        rawFit = AMARES.amares(spec, options.coils, voxelNum, beginTime, expectedOffset, pk, plotFlagThisVoxel, options);

        if checkBATP_SNR
            % Do a quick SNR check on just the B ATP peak. It doesn't
            % include the filtering step but is going for speed.
            BATP_SNR = peakHeight(rawFit.Amplitudes(2), rawFit.Linewidths(2))/std(specApodize(spec.timeAxis,specFft(rawFit.fitStatus.residual),abs(rawFit.Linewidths(2)*pi)));
            if voxelNum == 1929
                disp('here')
            end
            if BATP_SNR <= BATP_SNRLimit || rawFit.Linewidths(2) > 150; 
                BATP_counter = BATP_counter + 1;
                disp('Rerunning with BATP linewidth constraints!')
%                 disp(BATP_counter);
               rawFit = AMARES.amares(spec, options.coils, voxelNum, beginTime, expectedOffset, pkConstrained, plotFlagThisVoxel, options);
            end
        end
        
        %% Save figure
        if (~isfield(options,'saveFigure') || options.saveFigure) && ~isempty(rawFit.resFigureHandle) % Default to save if possible.
            set(rawFit.resFigureHandle,'PaperUnits','centimeters ','PaperPosition',[0 0 20 20])
            print(rawFit.resFigureHandle,'-dpng','-r400',screenShotFilename{sdx})
        end
        
        %% Sort AMARES output into expected format.
        results = AMARES.sortFitData(results,rawFit,obj.data.spec,pk,rawFit.fitStatus.exptParams.beginTime,'fitOptions',options,'voxel',vdx);
        
        %% Check that fitted parameters did not hit bound limits.
        % This is to check that the fit was not limited unduly by the prior
        % knowledge. The flag results in the fitted parameters being
        % displayed in red in the eventual excel/pdf record.
        peakCounter = 0;
        for peakdx=1:size(pk.bounds,2)
            if isempty(pk.priorKnowledge(1,peakdx).multiplet)
                loop = 1;
            else
                loop = numel(pk.priorKnowledge(1,peakdx).multiplet);
            end
            
            for iDx = 1:loop
                peakCounter = peakCounter + 1;
                if isempty(pk.bounds(1,peakdx).amplitude)
                    expandedBounds(peakCounter).Amplitudes = [-inf inf];
                else
                    expandedBounds(peakCounter).Amplitudes = pk.bounds(1,peakdx).amplitude .* [1.05 0.95];
                end
                
                if isempty(pk.bounds(1,peakdx).linewidth)
                    expandedBounds(peakCounter).Linewidths = [-inf inf];
                else
                    expandedBounds(peakCounter).Linewidths = pk.bounds(1,peakdx).linewidth .* [1.05 0.95];
                end
                
                if isempty(pk.bounds(1,peakdx).chemShift)
                	expandedBounds(peakCounter).Frequencies = [-inf inf];
                else
                    expandedBounds(peakCounter).Frequencies = ((pk.bounds(1,peakdx).chemShift*spec(1).imagingFrequency) + rawFit.offsetHz) .* [1.05 0.95];% TODO: I'm not sure this handles -ve bounds properly...
                end
                
                if isempty(pk.bounds(1,peakdx).phase)
                	expandedBounds(peakCounter).Phases = [-inf inf];
                else
                    expandedBounds(peakCounter).Phases = pk.bounds(1,peakdx).phase .* [1.05 0.95];% TODO: I'm not sure this handles -ve bounds properly...
                end
                
            end
        end
        
        for peakdx=1:numel(results.peakNames)
            if (results.dataByPeak.( results.peakNames{peakdx} ).Amplitudes(vdx,1) > expandedBounds(peakdx).Amplitudes(2))
                results.boundFlag.( results.peakNames{peakdx} ).Amplitudes(vdx,1) = 1;
            else
                results.boundFlag.( results.peakNames{peakdx} ).Amplitudes(vdx,1) = 0;
            end
            if (results.dataByPeak.( results.peakNames{peakdx} ).Linewidths(vdx,1) < expandedBounds(peakdx).Linewidths(1))...
                    || (results.dataByPeak.( results.peakNames{peakdx} ).Linewidths(vdx,1) > expandedBounds(peakdx).Linewidths(2))
                results.boundFlag.( results.peakNames{peakdx} ).Linewidths(vdx,1) = 1;
                results.boundFlag.( results.peakNames{peakdx} ).Dampings(vdx,1) = 1;
            else
                results.boundFlag.( results.peakNames{peakdx} ).Linewidths(vdx,1) = 0;
                results.boundFlag.( results.peakNames{peakdx} ).Dampings(vdx,1) = 0;
            end
            if (results.dataByPeak.( results.peakNames{peakdx} ).FrequenciesHz(vdx,1) < expandedBounds(peakdx).Frequencies(1))...
                    || (results.dataByPeak.( results.peakNames{peakdx} ).FrequenciesHz(vdx,1) > expandedBounds(peakdx).Frequencies(2))
                results.boundFlag.( results.peakNames{peakdx} ).FrequenciesHz(vdx,1) = 1;
            else
                results.boundFlag.( results.peakNames{peakdx} ).FrequenciesHz(vdx,1) = 0;
            end
            
            if (results.dataByPeak.( results.peakNames{peakdx} ).Phases(vdx,1) < expandedBounds(peakdx).Phases(1))...
                    || (results.dataByPeak.( results.peakNames{peakdx} ).Phases(vdx,1) > expandedBounds(peakdx).Phases(2))
                results.boundFlag.( results.peakNames{peakdx} ).Phases(vdx,1) = 1;
            else
                results.boundFlag.( results.peakNames{peakdx} ).Phases(vdx,1) = 0;
            end
        end
       
    end % of vdx loop. I.e. this slice is complete.

    %% Store this slice's results into the overall multi-slice "res" results cell array.
    res{sdx} = results;
    
    %% Save results to mat file
    save(options.amaresOutputFilenameMat{sdx},'results');
    
    %% Save results to Text file
    fileID = fopen(options.amaresOutputFilenameTxt{sdx},'w');
    fprintf(fileID,'Fitting Results Textfile \n\n');
    fprintf(fileID,'Filename: %s \n\n',options.amaresOutputFilenameTxt{sdx});
    fprintf(fileID,'Name of Patient:%s %s\nDate of Experiment: %s\nSpectrometer: %iT\nAdditional Information: \n\n',givenName,familyName,spec.info{1}.StudyDate,round(spec.info{1}.csa.MagneticFieldStrength));
    fprintf(fileID,'Points\tSamp.Int.\tZeroOrder\tBeginTime\tTra.Freq.\tMagn.F.\tNucleus\n');
    fprintf(fileID,'%i\t%d\t%d\t%d\t%d\t%d\t31P\n\n',spec.samples,spec.dwellTime,rawFit.Phases(1),rawFit.fitStatus.exptParams.beginTime,spec.imagingFrequency,spec.info{1}.csa.MagneticFieldStrength);
    fprintf(fileID,'Name of Algorithm: AMARES\n\n');
    fprintf(fileID,'%s\t', results.peakNames{1:end-1});
    fprintf(fileID,'%s\n\n', results.peakNames{end});
    
    
    for iDx = 1:1:numel(results.fitFields)
        %Print title
        A = [];
        for peakdx=1:numel( results.peakNames)
            A = [A results.dataByPeak.(  results.peakNames{peakdx} ).(results.fitFields{iDx})];
        end
        
        fprintf(fileID,'%s\n',results.fitFields{iDx});
        for ii = 1:size(A,1)
            fprintf(fileID,'%d\t',A(ii,:));
            fprintf(fileID,'\n');
        end
    end
    
    tmpNoiseVec = cellfun( @(x) x.noise_var, results.fitStatus );
    fprintf(fileID,'Noise : ');
    for iDx = 1:numel(tmpNoiseVec)
        fprintf(fileID,'%d \n',results.fitStatus{iDx}.noise_var);
    end
    
    currentCsiShift = obj.csiShift;
    fprintf(fileID,'CSI Shift vector: %0.2f %0.2f %0.2f\n',currentCsiShift(1),currentCsiShift(2),currentCsiShift(3));
    
    fprintf(fileID,'FIDs hash: %s\n',fids_md5{sdx});
    
    fprintf(fileID,'End of file.');
    fclose(fileID);
    
end



function [fids, fids_md5] = gatherFids(spec,options,sdx)
% Inputs:
% spec - Spectro.Spec object.
% options - Input options struct.
% sdx - Slice index.

%% N.B. Spectra were FT'd using this code (in PlotCsi.preLoadData)
%     tmp = size(signals{coildx},1)/2;
%     dwelltime = info{coildx}.csa.RealDwellTime*1e-9;
%     imagingfreq = info{coildx}.csa.ImagingFrequency;
%
%     % In Hz
%     freqaxis{coildx} = ((-tmp):(tmp-1))/(dwelltime*tmp*2);
%
%     % In ppm
%     ppmaxis{coildx} = freqaxis{coildx} / imagingfreq;
%
%     % Fourier transform (no phasing or other processing yet)
%     spectra{coildx} = fftshift(fft(signals{coildx},[],1),1) / size(signals{coildx},1);

spectraTogether = zeros(spec(1).samples, numel(options.voxels{sdx}), numel(options.coils), numel(spec));
for specDx = 1:numel(spec)
    for coilDx = 1:numel(options.coils)
        spectraTogether(:,:,coilDx,specDx) = spec(specDx).spectra{options.coils(coilDx)}(:,options.voxels{sdx});
    end
end

fids = ifft(fftshift(spectraTogether * spec(1).samples,1),[],1);

% Checksum of data.
fids_md5 = hash(fids,'sha1');





