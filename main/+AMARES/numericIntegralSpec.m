function spec = numericIntegralSpec(damping,g,v)
spec = integral(@(t) exp(-damping*(1-g+g*t).*t).*exp(2i*pi*v*t),0,inf);