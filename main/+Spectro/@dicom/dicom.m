classdef dicom < handle
    % Base class encapsulating a generic Siemens MR DICOM file.
    
    % Copyright Chris Rodgers, University of Oxford, 2012.
    % $Id: PlotCsi.m 4072 2011-04-08 13:30:59Z crodgers $
    
    % Public properties
    properties
        debug = false;
        quiet = false; % Property which is set on construction to reduce command window output in this and many child classes. WTC 01/02/2018
    end
    
    properties(SetAccess=protected)
        options;
        info;
    end
    
    methods
        function obj = dicom(whatToLoad, varargin)
            % Allow loading:
            %
            % Cell array of DICOM filenames
            % Cell array of structs returned from SiemensCsaParse()
            % Struct/array of structs:
            %   dicominfo with .csa struct already decoded
            %   dicominfo from a Siemens spectroscopy file
            %   a Spectro.dicomTree series struct
            %   an (array) of Spectro.dicomTree instance structs from the
            %     same series
            
            if nargin < 1
                error('DICOM files to load must be specified.')
            end
            
            obj.options = processVarargin(varargin{:});
            
            % Set verbosity
            if isfield(obj.options,'quiet') && quiet
                obj.quiet = true;
            end
            
            % Requested to load data from DICOM files directly
            if iscellstr(whatToLoad)
                strFiles = whatToLoad;
                
                for filedx=1:numel(whatToLoad)
                    % Attempt to start handling dicom files which come from
                    % different manufacturers. This is only from an imaging
                    % pov, and not using enhanced DICOM format. WTC 02/01/2018
                    
                    dcmInfo = dicominfo(strFiles{filedx});
                    type = identifyDICOMType(dcmInfo);
                    switch type
                        case 'Siemens'
                            obj.info{filedx} = SiemensCsaParse(dcmInfo);
                            fprintf('Loaded file %d --> protocol (%s (%s)), coil "%s"\n',...
                                filedx,obj.info{filedx}.SeriesDescription,obj.info{filedx}.ProtocolName,...
                                obj.info{filedx}.csa.ImaCoilString);
                            
                        case 'Philips'
                            if exist('PhilipsParse.m','file') == 2
                            obj.info{filedx} = PhilipsParse(dcmInfo);
                            fprintf('Loaded file %d --> protocol (%s (%s)), coil "%s"\n',...
                                filedx,obj.info{filedx}.SeriesDescription,obj.info{filedx}.ProtocolName,...
                                '(Unknown philips coil encoding)');
                            else
                             error('Philips DICOM reading is not currently included in the OXSA release');
                            end
                        otherwise
                            error('Unrecognised DICOM source');
                    end
                    
                    
                end
            elseif iscell(whatToLoad)
                obj.info = whatToLoad;
            elseif isstruct(whatToLoad)
                
                % Allow loading:
                
                % dicominfo with .csa struct already decoded
                % dicominfo from a Siemens spectroscopy file
                % a Spectro.dicomTree series struct
                % an (array) of Spectro.dicomTree instance structs from the
                %     same series
                
                if isfield(whatToLoad,'csa')
                    % dicominfo with .csa struct already decoded
                    obj.info{1} = whatToLoad;
                    return
                elseif ~isempty(getDicomPrivateTag(whatToLoad,'0029','SIEMENS CSA HEADER'))
                    % dicominfo from a Siemens spectroscopy file
                    obj.info{1} = SiemensCsaParse(whatToLoad);
                elseif numel(whatToLoad) == 1 ...
                        && isfield(whatToLoad,'SeriesInstanceUID') ...
                        && isfield(whatToLoad,'instance') ...
                        && isfield(whatToLoad.instance(1),'SOPInstanceUID') ...
                        && isfield(whatToLoad.instance(1),'Filename')
                    % a Spectro.dicomTree series struct
                    tmpInfo = cell(size(whatToLoad.instance));
                    for tmpDx = 1:numel(whatToLoad.instance)
                        tmpInfo{tmpDx} = SiemensCsaParse(whatToLoad.instance(tmpDx).Filename);
                    end
                    
                    obj.info = tmpInfo;
                    clear tmpInfo tmpDx
                elseif isfield(whatToLoad,'SOPInstanceUID') ...
                        && isfield(whatToLoad,'Filename')
                    % an (array) of Spectro.dicomTree instance structs from the
                    %     same series
                    
                    tmpInfo = cell(size(whatToLoad));
                    for tmpDx = 1:numel(whatToLoad)
                        tmpInfo{tmpDx} = SiemensCsaParse(whatToLoad(tmpDx).Filename);
                    end
                    
                    obj.info = tmpInfo;
                    clear tmpInfo tmpDx
                else
                    error('Unsupported input type!')
                end
            else
                error('Unsupported input type!')
            end
            
            if ~isfield(obj.info{1},'csa') || ~isstruct(obj.info{1}.csa)
                error('info{...}.csa should be a structure calculated by SiemensCsaParse')
            end
        end
        
        function strNamesOut = getTxSpecPulseNames(obj,strFlag)
            % Return a cell array containing the transmit pulse names.
            %
            % Pass '-v' as a flag to dump the voltages for each pulse.
            
            tmp = regexp(obj.info{1}.csa.MrPhoenixProtocol,...
                '^sTXSPEC\.aRFPULSE\[([0-9]+)\]\.tName\s*=\s+""(.*)""$',...
                'tokens','dotexceptnewline','lineanchors');
            
            ids = [];
            for idx=1:numel(tmp)
                ids(idx) = str2double(tmp{idx}{1});
            end
            
            strNames = cell(max(ids)+1,1);
            for idx=1:numel(tmp)
                strNames{ids(idx)+1} = tmp{idx}{2};
            end
            
            if nargin > 1 && strcmpi(strFlag,'-v')
                for idx=1:numel(tmp)
                    fprintf('Pulse #%d: "%s" --> %.3fV\n',...
                        idx-1, strNames{ids(idx)+1}, ...
                        obj.getTxSpecPulsePeakVoltage(idx))
                end
                
                if nargout > 0
                    % Only export data unsolicited without the -v flag
                    strNamesOut = strNames;
                end
            else
                strNamesOut = strNames;
            end
        end
        
        function voltage = getTxSpecPulsePeakVoltage(obj,strNameOrNumber)
            % Retrieve the peak voltage for the specified RF pulse.
            %
            % N.B. Since Matlab arrays use 1-based indexing, the index number
            % specified here matches the results from getTxSpecPulseNames() NOT
            % the number in the DICOM file headers.
            
            voltage = [];
            
            if ~isnumeric(strNameOrNumber)
                % Find numeric ID if not provided.
                tmp = regexp(obj.info{1}.csa.MrPhoenixProtocol,...
                    ['^sTXSPEC\.aRFPULSE\[([0-9]+)\]\.tName\s*=\s+""' regexptranslate('escape',strNameOrNumber) '""$'],...
                    'tokens','dotexceptnewline','lineanchors');
                if numel(tmp) == 0
                    error('Cannot find a pulse with that name.')
                elseif numel(tmp) > 1
                    error('Cannot find a unique pulse with that name. Specify the pulse index instead.')
                else
                    strNameOrNumber = str2double(tmp{1}{1});
                end
            else
                % Convert Matlab base-1 indexing to C++ base-0:
                strNameOrNumber = strNameOrNumber - 1;
            end
            
            tmp = regexp(obj.info{1}.csa.MrPhoenixProtocol,...
                ['^sTXSPEC\.aRFPULSE\[' num2str(strNameOrNumber) '\]\.flAmplitude\s*=\s+([0-9\.-]+)$'],...
                'tokens','dotexceptnewline','lineanchors');
            
            if isempty(tmp)
                % Special case.
                voltage = 0;
            else
                voltage = str2double(tmp{1}{1});
            end
        end
        
        function plugIDs = getCoilPlugIds(obj)
            % Extract and decode coil plug codes from the DICOM headers.
            
            % Check software version
            if isfield(obj.info{1},'Manufacturer')
                manufacturer = obj.info{1}.Manufacturer;
            else
                manufacturer = '';
            end;
            if isfield(obj.info{1},'ManufacturerModelName')
                manufacturerModelName = obj.info{1}.ManufacturerModelName;
            else
                manufacturerModelName = '';
            end;
            
            switch manufacturer
                case 'SIEMENS'
                    if isfield(obj.info{1},'SoftwareVersion')
                        SoftwareVersion = obj.info{1}.SoftwareVersion;
                    else
                        SoftwareVersion = '';
                    end;
                    switch SoftwareVersion
                        case {'syngo MR E11'}
                            tmp = strGrep('sCoilSelectMeas.CoilPlugs.Plug.*IdPart\[',obj.info{1}.csa.MrPhoenixProtocol);
                            % TODO - load coil ID numbers
                            
                            % FEM: tentative coil ID loading. Not sure if
                            % producing the desired output
                            for idx = 1:numel(tmp)
                                [a plugIDs{idx}] = strtok(tmp{idx}, '= ');
                                plugIDs{idx} = ['0x' lower(dec2hex(str2num(strrep(plugIDs{idx}, ' = ', ''))))];
                            end;
                            %plugIDs = {};
                        case {'syngo MR B17';'syngo MR B13 4VB13A'} % VB-series
                            tmp = strGrep('aulPlugId',obj.info{1}.csa.MrPhoenixProtocol);
                            
                            for idx=1:numel(tmp)
                                [a plugIDs{idx}] = strtok(tmp{idx},'= ');
                                plugIDs{idx} = strrep(plugIDs{idx},' = ','');
                            end;
                        otherwise
                            warning('Unsupported software version (%s).',SoftwareVersion);
                            plugIDs = {};
                    end;
                otherwise
                    warning('Cannot decode coil information for a %s %s system.',manufacturer,manufacturerModelName);
                    plugIDs = {};
            end;
        end
        
        function strProt = getMrProtocol(obj)
            % Print out a protocol suitable for use with POET.
            %
            % Example:
            %
            % clipboard('copy',obj.getMrProtocol())
            
            tmpProt = regexp(obj.info{1}.csa.MrPhoenixProtocol,...
                '\n(### ASCCONV BEGIN.*? ###\n.*\n### ASCCONV END ###)"','tokens','once');
            
            if isempty(tmpProt)
                error('Protocol not found!')
            end
            
            strProt = regexprep(tmpProt{1}, '""', '"');
        end
        
        function [res] = getMrProtocolString(obj,strToFind)
            tmp = obj.regexpMrProtocol(['^' regexptranslate('escape',strToFind) '\s*=\s+"+(.*?)"+$'],'tokens','once');
            
            if ~isempty(tmp)
                res = tmp{1};
            else
                res = '';
            end
        end
        
        function [res] = getMrProtocolNumber(obj,strToFind)
            
            tmp = obj.regexpMrProtocol(['^' regexptranslate('escape',strToFind) '\s*= (.*)$'],'tokens','once');
            
            if isempty(tmp)
                res = 0;
            else
                tmp2 = regexp(tmp{1},'^0x([0-9A-Fa-f]+)$','tokens','once');
                if ~isempty(tmp2)
                    % Hex result
                    res = hex2dec(tmp2{1});
                else
                    % Decimal result
                    res = str2double(tmp{1});
                end
            end
        end
        
        function [varargout] = regexpMrProtocol(obj, varargin)
            % Search using a regular expression over the MrPhoenixProtocol header
            
            varargout = cell(1,max(nargout,1));
            [varargout{:}] = regexp(obj.info{1}.csa.MrPhoenixProtocol,...
                varargin{1}, ...
                'dotexceptnewline','lineanchors', varargin{2:end});
        end
        
        function res = getPhysioImaging(obj)
            % Decode the sPhysioImaging.* headers in the protocol to determine
            % the type of triggering/gating in use.
            
            PhysioSignal = {
                'SIGNAL_NONE'         1
                'SIGNAL_EKG'          2
                'SIGNAL_PULSE'        4
                'SIGNAL_EXT'          8
                'SIGNAL_CARDIAC'     14 %  /* the sequence usually takes this */
                'SIGNAL_RESPIRATION' 16
                'SIGNAL_ALL'         30
                'SIGNAL_EKG_AVF'     32 };
            
            PhysioMethod = {
                'METHOD_NONE'        1
                'METHOD_TRIGGERING'  2
                'METHOD_GATING'      4
                'METHOD_RETROGATING' 8
                'METHOD_SOPE'       16
                'METHOD_ALL'        30
                };
            
            res.lSignal1 = PhysioSignal{find(cell2mat(PhysioSignal(:,2)) == obj.getMrProtocolNumber('sPhysioImaging.lSignal1')),1};
            res.lMethod1 = PhysioMethod{find(cell2mat(PhysioSignal(:,2)) == obj.getMrProtocolNumber('sPhysioImaging.lMethod1')),1};
            res.lSignal2 = PhysioSignal{find(cell2mat(PhysioSignal(:,2)) == obj.getMrProtocolNumber('sPhysioImaging.lSignal2')),1};
            res.lMethod2 = PhysioMethod{find(cell2mat(PhysioSignal(:,2)) == obj.getMrProtocolNumber('sPhysioImaging.lMethod2')),1};
        end
        
        function s = saveobj(obj)
            s.version = 1;
            s.info = obj.info;
            s.debug = obj.debug;
        end
        
        printScanSummary(obj, bHtmlHeadings);
        
        function coilInfoTemp = getCoilInfo(obj)
            % Load coil configuration by interpreting the scanner serial
            % number, series date/time and coil plug ID headers.
            
            if isfield(obj.options,'forceCoil')
                plugIDs = obj.options.forceCoil;
            else
                plugIDs = obj.getCoilPlugIds();
            end
            
            % Force a DeviceSerialNumber field (to avoid errors with anonymised DICOM files)
            % TODO: Need to allow override of the DeviceSerialNumber for proper detection of
            %       the coils employed for anonymised DICOM scans.
            if ~isfield(obj.info{1},'DeviceSerialNumber')
                obj.info{1}.DeviceSerialNumber = '';
            end
            
            
            try
                coilInfoTemp = CoilGeometryFiles.searchCoils(obj.info{1}.DeviceSerialNumber,obj.info{1}.SeriesDate,obj.info{1}.SeriesTime,plugIDs,obj.debug);
            catch
                coilInfoTemp = [];
            end
            
            if ~isempty(coilInfoTemp)
                if obj.debug
                    fprintf('Coil Identified as %s and coil data loaded.\n',coilInfoTemp.name);
                end
            else
                % TODO: Default to a default coil at this point?
                if exist('CoilGeometryFiles.searchCoils', 'file') == 2
                    warning('RodgersSpectroTools:CoilNotFound','No matching coil identified [serial=%s,date=%s,time=%s,plugs=%s]',...
                        obj.info{1}.DeviceSerialNumber,...
                        obj.info{1}.SeriesDate,...
                        obj.info{1}.SeriesTime,...
                        joinrow2str(plugIDs(~(strcmp(plugIDs,'0xff') | strcmp(plugIDs,'0xee'))),'%s',','));
                end
            end
        end
        
        
        % DEPRECATED. This function doesn't understand how the Siemens ICE code
        % SORTS the channels by Rx channel number before entering
        % ICE/TWIX/DICOM.
        function unsortedCoilNames = getUnsortedCoilString(obj)
            error('Deprecated function - use getMrProtocolCoilDetails instead.')
            %         keepLooping = true;
            %         iDx = 0;
            %         while keepLooping == true
            %             unsortedCoilNames{iDx+1} = obj.getMrProtocolString(['asCoilSelectMeas[0].asList[' num2str(iDx) '].sCoilElementID.tElement']);
            %
            %             if strcmp(unsortedCoilNames{iDx+1},'')
            %                 keepLooping = false;
            %                 unsortedCoilNames(iDx+1) =[];
            %             end
            %             iDx = iDx +1;
            %        end
        end
        
        function out = getInstanceNumbers(obj,strmode)
            % Pull out the DICOM InstanceNumber for each instance in this
            % object.
            %
            % Optionally, if strmode is 'uncombined', only do this until
            % COMBINED data is seen.
            
            if ~exist('strmode','var') || isempty(strmode)
                for idx=1:numel(obj.info)
                    out(idx) = obj.info{idx}.InstanceNumber;
                end
            elseif strcmpi(strmode,'uncombined')
                numElements = obj.getMrProtocolCoilDetails.numElements;
                for idx=1:numel(obj.info)
                    if numElements > 1 ... % Single-Rx gets special treatment in ICE. Grrr...
                            && ~isempty(regexp(obj.info{idx}.csa.ImaCoilString,'^[tC]:','once'))
                        % Found combined data - stop looping.
                        break
                    end
                    out(idx) = obj.info{idx}.InstanceNumber;
                end
            else
                error('Unknown strmode.')
            end
        end
        
        function [out] = getMrProtocolCoilDetails(obj)
            % Load details of the Rx elements used from the ASCII protocol.
            % This means that information is available for all connected Rx
            % channels from the DICOM file for any ONE channel.
            % Check software version
            if isfield(obj.info{1},'Manufacturer')
                manufacturer = obj.info{1}.Manufacturer;
            else
                manufacturer = '';
            end;
            if isfield(obj.info{1},'ManufacturerModelName')
                manufacturerModelName = obj.info{1}.ManufacturerModelName;
            else
                manufacturerModelName = '';
            end;
            
            switch manufacturer
                case 'SIEMENS'
                    if isfield(obj.info{1},'SoftwareVersion')
                        SoftwareVersion = obj.info{1}.SoftwareVersion;
                    else
                        SoftwareVersion = '';
                    end
                    switch SoftwareVersion
                        case {'syngo MR E11'}
                            for idx = 1:obj.getMrProtocolNumber('sProtConsistencyInfo.lMaximumNofRxReceiverChannels')
                                lRxChannelConnected_MrProtOrder(idx) = obj.getMrProtocolNumber(sprintf('sCoilSelectMeas.aRxCoilSelectData[0].asList[%d].lRxChannelConnected', idx - 1));
                                tElement_MrProtOrder{idx} = obj.getMrProtocolString(sprintf('sCoilSelectMeas.aRxCoilSelectData[0].asList[%d].sCoilElementID.tElement', idx - 1));
                            end;
                            
                            tElement_MrProtOrder(lRxChannelConnected_MrProtOrder == 0) = [];
                            lRxChannelConnected_MrProtOrder(lRxChannelConnected_MrProtOrder == 0) = [];
                            
                            [out.lRxChannelConnected_TwixOrder, rxChannelConnectedDx] = sort(lRxChannelConnected_MrProtOrder);
                            out.tElement_TwixOrder = tElement_MrProtOrder(rxChannelConnectedDx);
                            
                            out.numElements = numel(out.tElement_TwixOrder);
                        case {'syngo MR B17'; 'syngo MR B13 4VB13A'} % VB-series
                            % Load all channel names and sort them as per WSVD_v4 code in
                            % IceSpectroConfigurator.cpp.
                            for idx=1:obj.getMrProtocolNumber('sProtConsistencyInfo.lMaximumNofRxReceiverChannels')
                                lRxChannelConnected_MrProtOrder(idx) = obj.getMrProtocolNumber(sprintf('asCoilSelectMeas[0].asList[%d].lRxChannelConnected',idx-1));
                                tElement_MrProtOrder{idx} = obj.getMrProtocolString(sprintf('asCoilSelectMeas[0].asList[%d].sCoilElementID.tElement',idx-1));
                            end;
                            
                            tElement_MrProtOrder(lRxChannelConnected_MrProtOrder == 0) = [];
                            lRxChannelConnected_MrProtOrder(lRxChannelConnected_MrProtOrder == 0) = [];
                            
                            [out.lRxChannelConnected_TwixOrder,rxChannelConnectedDx]=sort(lRxChannelConnected_MrProtOrder);
                            out.tElement_TwixOrder = tElement_MrProtOrder(rxChannelConnectedDx);
                            
                            % Useful in other functions
                            out.numElements = numel(out.tElement_TwixOrder);
                        otherwise
                            error('Unsupported software version (%s). Cannot extract coil details from MR protocol.', SoftwareVersion)
                    end
                otherwise
                    error('Cannot extract coil details from MR protocol for a %s %s system.', manufacturer, manufacturerModelName)
            end
        end
        
        function imgType = getImageType(obj)
            imgType = strsplit_pja('\',obj.info{1}.ImageType);
        end
        
        function out = isImageType_Magnitude(obj)
            out = any(strcmp(obj.getImageType,'M'));
        end
        
        function out = isImageType_Phase(obj)
            out = any(strcmp(obj.getImageType,'P'));
        end
    end
    
    methods (Static)
        function obj = loadobj(s)
            obj = Spectro.dicom(s.info);
            obj.debug = s.debug;
        end
        
        hHumanAxis = addHumanPositionMarker(hAxes);
    end
end
