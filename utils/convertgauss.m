function [ mu sigma ] = convertgauss( prow )
% Converts from the Igor 2d gauss parameters to mu / sigma representation

mu = [prow(3); prow(5)];
cor = prow(7);
xw = prow(4);
yw = prow(6);
sigma = [xw^2, cor*xw*yw; cor*xw*yw, yw^2];

end

