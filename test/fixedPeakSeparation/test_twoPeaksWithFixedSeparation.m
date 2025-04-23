%% Demo of OXSA for two peaks with constrained relative chemical shift
run('../../startup')

clear params data spec
imagingFrequency_MHz = 120.3; % 31P at 7T in MHz

params.N=1024;
params.fs_Hz=2000;
params.f0_Hz=0; % Central frequency, relative to 0ppm.
params.t0=0;

params.amplitude=[10 6]; % can be complex to give phase
params.T2star=[1/40 1/40];
params.v0_Hz=[4.7 4.7-0.9]*imagingFrequency_MHz; % 0 and 0.9 ppm
params.noise_sigma=0.2;

data=synthesizeData(params);

clear spec
spec.imagingFrequency=imagingFrequency_MHz;
spec.signals={data.fid.'};
spec.dwellTime=1/data.fs_Hz;
spec.samples=data.N;
spec.freqAxis=(((0:data.N-1)-floor(data.N/2))*data.fs_Hz/data.N).';
spec.ppmAxis = spec.freqAxis / spec.imagingFrequency;
spec.timeAxis=((0:data.N-1)*spec.dwellTime).';

% plot simulated spectrum
figure(1);clf;plot(spec.ppmAxis, real(specFft(spec.signals{1})));set(gca,'xdir','rev');ylabel('Re signal');xlabel('\delta / ppm')

instanceNum=1;
voxelNum=1;
beginTime=data.t0;
expOffset=params.v0_Hz(1)/imagingFrequency_MHz;
% pk=AMARES.priorKnowledge.PK_SinglePeak;
pk=PK_twoPeaksWithFixedSeparation;
showPlot=true;

% CTR. TODO. I don't understand why fixOffset is needed here. But it's a
% quick hack to make the test run reasonably.
% The offset logic could do with some unit tests and clearer documentation.
results=AMARES.amares(spec, instanceNum ,voxelNum, beginTime, expOffset, pk,showPlot, 'fixOffset', 0)

function data=synthesizeData(params)
    % params is a struct with the following fields
    %   (1) these parameters can be arrays, if they are not of the same length, anything longer than the smallest length will be dropped
    %   amplitude, magnetization at t=0 (COMPLEX)
    %   T2star, in seconds
    %   v0, Larmor frequency, in Hz
    %   
    %   (2) these parameters must not be arrays
    %   noise_sigma, the noise follows N(0, sigma^2)
    % 
    %   (3) these parameters are also present in the returned struct
    %   N, number of sampling points
    %   fs, sampling rate, in Hz
    %   f0, excitation frequency, in Hz
    %   t0, also known as beginTime, the time interval between when FID acquisition starts and when excitation finishes, in seconds
    % 
    % data is a struct with the following fields
    %   fid, shape (1,N)
    %   N, same as above
    %   fs, same as above
    %   f0, same as above
    %   t0, same as above
    
    if ~isequal(size(params.amplitude),size(params.T2star))
        error('amplitude and T2star size mismatch.')
    end
    if ~isequal(size(params.amplitude),size(params.v0_Hz))
        error('amplitude and v0_Hz size mismatch.')
    end
   
    N=params.N;
    fid_array=zeros(numel(params.amplitude),N);
    t=(0:N-1)/params.fs_Hz+params.t0;
    for i=1:numel(params.amplitude)
        w0=2*pi*(params.v0_Hz(i)-params.f0_Hz);
        fid_array(i,:)=params.amplitude(i)...
            *exp(-t/params.T2star(i) + 1i*w0*t);
    end
    noise=(randn(1,N)+randn(1,N)*1i)*params.noise_sigma;
    data.fid=sum(fid_array,1)+noise;
    data.N=N;
    data.fs_Hz=params.fs_Hz;
    data.f0_Hz=params.f0_Hz;
    data.t0=params.t0;
    
    Tacq=N/params.fs_Hz;
    if Tacq<3*max(params.T2star(1:numel(params.amplitude)))
        disp("Warning: truncation artifact, total acquisition time is shorter than 3 times maximum T2*")
    end
    
    if params.fs_Hz<2*max(abs(params.v0_Hz(1:numel(params.amplitude))-params.f0_Hz))
        disp("Warning: undersampling, sampling rate is smaller than twice (the fastest Larmor frequency minus excitation frequency)")
    end
end

