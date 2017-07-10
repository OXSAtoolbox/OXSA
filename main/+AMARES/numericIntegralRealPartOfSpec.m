function spec = numericIntegralRealPartOfSpec(damping,g,v)
spec = integral(@(t) exp(-damping*(1-g+g*t).*t).*cos(2*pi*v*t),0,inf);