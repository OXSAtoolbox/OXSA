% testAMARES.m

run('../startup')

params.M0=12;
params.T2star=1/40;
params.v0=0;
params.phi=pi;
params.noise_sigma=0.002;

params.N=400;
params.fs=1000;
params.f0=0;
params.t0=0;

data=synthesizeData(params);

spec.signals={data.fid.'};
spec.dwellTime=1/data.fs;
spec.samples=data.N;
spec.ppmAxis=((0:data.N-1)-floor(data.N/2))*data.fs/data.N;
spec.timeAxis=(0:data.N-1)*spec.dwellTime;
spec.imagingFrequency=data.f0;

instanceNum=1;
voxelNum=1;
beginTime=data.t0;
expOffset=params.v0;
pk=AMARES.priorKnowledge.PK_SinglePeak;
showPlot=false;

results=AMARES.amares(spec, instanceNum ,voxelNum, beginTime, expOffset, pk,showPlot)

function data=synthesizeData(params)
    % params is a struct with the following fields
    %   (1) these parameters can be arrays, if they are not of the same length, anything longer than the smallest length will be dropped
    %   M0, magnetization at t=0
    %   T2star, in seconds
    %   v0, Larmor frequency, in Hz
    %   
    %   (2) these parameters must not be arrays
    %   phi, initial phase, in rad, within [-pi, pi]
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
    
    len=min([
        numel(params.M0)
        numel(params.T2star)
        numel(params.v0)
        ]);
    N=params.N;
    fs=params.fs;
    fid_array=zeros(len,N);
    t=(0:N-1)/fs+params.t0;
    for i=1:len
        M0=params.M0(i);
        T2star=params.T2star(i);
        w0=2*pi*(params.v0(i)-params.f0);
        fid_array(i,:)=M0*exp(-t/T2star).*exp(1i*(w0*t+params.phi));
    end
    noise=(randn(1,N)+randn(1,N)*1i)*params.noise_sigma;
    data.fid=sum(fid_array,1)+noise;
    data.N=N;
    data.fs=fs;
    data.f0=params.f0;
    data.t0=params.t0;
    
    Tacq=N/fs;
    if Tacq<3*max(params.T2star(1:len))
        disp("Warning: truncation artifact, total acquisition time is shorter than 3 times maximum T2*")
    end
    
    if fs<2*max(abs(params.v0(1:len)-params.f0))
        disp("Warning: undersampling, sampling rate is smaller than twice (the fastest Larmor frequency minus excitation frequency)")
    end
end
