function type = identifyDICOMType(dcmInfo)

% Identify whther this dicom file is Siemens or Philips
% This function simpl looks at whether the headers of a dicom file have a
% CSA header with a group ID of 0029, or the first of the philips private
% groups. Philips Imaging DD 001 with group ID = 2001.

% Input is a dicom info struct from the amtlab function dicominfo.
% Output is either the string 'Siemens' or 'Philips'. If unknown it is an
% empty sting.

% WTC 01/02/2018

tagIDSiemens = getDicomPrivateTag(dcmInfo,'0029','SIEMENS CSA HEADER');
tagIDPhilips = getDicomPrivateTag(dcmInfo,'2001','Philips Imaging DD 001');

if ~isempty(tagIDSiemens)
    type = 'Siemens';
elseif ~isempty(tagIDPhilips)
    type = 'Philips';
else
    type = '';
end