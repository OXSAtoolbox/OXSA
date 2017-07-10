function [damping] = linewidthToDamping(linewidth,g)
% Convert linewidth --> damping in the AMARES model function.
%
% Linewidth is defined as FWHH for the real part of the lineshape function.
%
% Input:
% linewidth : FWHH in Hz
% g : lineshape parameter
%
% Output:
% damping / s^-1 : FID decay rate constant
%
% Limiting cases with g=0 (Lorentzian) or g=1 (Gaussian) are treated
% analytically. Others require a numerical solution.
%
% Reference:
% 
% Linewidth_and_damping.nb Mathematica notebook

if g == 0
    damping = linewidth * pi;
elseif g == 1
    damping = (linewidth*pi)^2 / (4*log(2));
else
    vHalf = abs(linewidth)/2;
    damping = fzero(@(damping) helper(damping,g,vHalf), 0);
end
end

function spec = helper(damping,g,vHalf)
% Discourage evaluation of -ve damping by making it equal to a damping
% 1/Inf. In other words, the spectral line is a delta function. So for any
% vHalf > 0, the lineshape will evaluate to 0.
if damping <= 0
    spec = (0 / 1) - 0.5;
else
    spec = AMARES.numericIntegralRealPartOfSpec(damping,g,vHalf) / AMARES.numericIntegralRealPartOfSpec(damping,g,0) - 0.5;
end
end