% Symbollically integrated lineshape function.
%
% Computed by Linewidth_and_damping.nb in Mathematica 8.

function spec = lineshapeSymb(v,damping,g)
import AMARES.erfz;

spec = (1/2).*exp((1/4).*damping.^(-1).*g.^(-1).*(damping.*((-1)+g)+(sqrt(-1)*2).*pi.*v).^2).*sqrt(pi).*((damping.*g).^(-1/2)+(damping.*((-1)+g)+(sqrt(-1)*2).*pi.*v).^(-1).*sqrt(damping.^(-1).*g.^(-1).*(damping.*((-1)+g)+(sqrt(-1)*2).*pi.*v).^2) .* ...
erfz((1/2).*sqrt(damping.^(-1).*g.^(-1).*(damping.*((-1)+g)+(sqrt(-1)*2).*pi.*v).^2)));


s = sym('(1/2)*exp((1/4)*damping^(-1)*g^(-1)*(damping*((-1)+g)+(sqrt(-1)*2)*pi*v)^2)*sqrt(pi)*((damping*g)^(-1/2)+(damping*((-1)+g)+(sqrt(-1)*2)*pi*v)^(-1)*sqrt(damping^(-1)*g^(-1)*(damping*((-1)+g)+(sqrt(-1)*2)*pi*v)^2) * erf((1/2)*sqrt(damping^(-1)*g^(-1)*(damping*((-1)+g)+(sqrt(-1)*2)*pi*v)^2)))');

