function [active, inactive] = calcColours(num)

% Darken yellows
yellowcentre = 1/6;
yellowwidth = 1/5;
yellowdip = 1/10; % How much to knock off brightness.

huevals=linspace(0,2/3,num).';
luminancevals=repmat(0.5,num,1);
luminancevals(abs(huevals-yellowcentre)<yellowwidth) = ...
    0.5 - yellowdip*...
    cos(pi * (huevals(abs(huevals-yellowcentre)<yellowwidth)-yellowcentre)/yellowwidth);

inactive=hsl2rgb([huevals repmat(1.0,num,1) luminancevals-0.4]);

active=hsl2rgb([huevals repmat(1.0,num,1) luminancevals+0.0]);
