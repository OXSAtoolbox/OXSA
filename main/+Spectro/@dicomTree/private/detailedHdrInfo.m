function [ headersString,headersInt ] = detailedHdrInfo()
% Function simply returns the structures headersInt and headersString which
% list the DICOM headers that should be read and stored by ProcessDicomDir

% I broke this out into a separate function so that there weren't continued
% modifications made to a core piece of code.

% WTC 02/2018
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
                'ProtocolName'      ,'Series';
                'SequenceName'      ,'Series';
                'ImageType'         ,'Instance';
                 };

headersInt = {
                'SeriesNumber'      ,'Series';
                'InstanceNumber'    ,'Instance';
                };

end

