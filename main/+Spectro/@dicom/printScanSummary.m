function printScanSummary(obj, bHtmlHeadings)
% Print a key set of summary information regarding a scan.
%
% bHtmlHeadings: Print <h1> etc tags if true.

% Copyright Chris Rodgers, Univ Oxford, 2013.
% $Id$

if ~exist('bHtmlHeadings','var')
    bHtmlHeadings = false;
end

if bHtmlHeadings
    fprintf('<h1>SUBJECT</h1>');
end
fprintf('Age = %s\n',obj.info{1}.PatientAge)

digInto(obj.info{1},'(PatientName|PatientID|PatientBirthDate|PatientSex|PatientSize|PatientAge|PatientWeight)')


if bHtmlHeadings
    fprintf('<h1>SERIES</h1>');
end

fprintf('Series #%d "%s"\n(UID = %s)\n%.1f minute acquisition.\n',obj.info{1}.SeriesNumber,obj.info{1}.SeriesDescription,obj.info{1}.SOPInstanceUID,obj.info{1}.csa.SliceMeasurementDuration / 60e3);obj.getTxSpecPulseNames('-v');

% N.B. The following method is now built in to the
% Spectro.Spec.getPhysioImaging() method.
strGrep('^sPhysioImaging\.l(Signal|Method)',obj.info{1}.csa.MrPhoenixProtocol)

% I think: MethodX=1 means ungated., MethodX=2 means gated.
% SignalX=4 is probably PulseOx.

fprintf('Nominal TR = %.0f ms\n',obj.info{1}.csa.RepetitionTime)
fprintf('Number of averages = %d\n',obj.info{1}.csa.NumberOfAverages)

fprintf('Interpolated resolution: ')
disp(obj.size)

fprintf('Sequence FileName = "%s"\n',obj.getMrProtocolString('tSequenceFileName'))

%% Use the loadSequenceParams__* methods if appropriate...
try
switch obj.getMrProtocolString('tSequenceFileName')
case '%CustomerSeq%\uteCsi7T_CTR_BISTRO'
    seqP = loadSequenceParams__UTE_CSI(obj);
    digInto(seqP) % Dump
    
otherwise
    % Can't process anything extra here
end
catch
end
