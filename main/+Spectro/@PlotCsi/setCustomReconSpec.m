function setCustomReconSpec(obj,newSpec)
% Replace the active "spec" object with one containing additional combined
% spectra from SENSE or another custom recon method.

warning('setCustomReconSpec:GenericWarning','The setCustomReconSpec method has not been tested much. Be cautious that the results are as expected.')

% Check that the new spec object matches the existing localizers...
if ~isequal(obj.data.spec.info{1}.SOPInstanceUID,newSpec.info{1}.SOPInstanceUID)
    error('New spec object must be from the same raw data!')
end

if ~isa(newSpec,'Spectro.Spec')
    error('Must supply a Spectro.Spec-derived object.')
end

obj.data.spec = newSpec;
