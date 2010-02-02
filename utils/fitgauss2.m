function [ p ] = fitgauss2(X,Y,I)
%FITGAUSS fit 2D data to a 2D Gaussian function with offset
% [A mu sigma] = fitgauss2(X,Y,I)
% X and Y as in meshgrid coordinates, I is the data to fit

% reshape image into row vectors
Xf = reshape(X,1,[]);
Yf = reshape(Y,1,[]);
If = reshape(I,1,[]);

% using curve fitting toolbox
% ft = fittype( 'c+A*exp(-1/(2*(1-corr^2)) *(((x-x0)/xwidth)^2 +  ((y-y0)/ywidth)^2 -  2*corr*(x-x0)*(y-y0)/(xwidth*ywidth)))', 'indep', {'x', 'y'}, 'depend', 'z' );
% opts = fitoptions( ft );
% opts.Display = 'Off';
% opts.Lower = [0 0 -1 -Inf 0 -Inf 0];
% opts.StartPoint = [1 max(If) 0 0 1 0 1];
% opts.Upper = [Inf Inf 1 Inf Inf Inf Inf];
% opts.Weights = zeros(1,0);
% [fr, gof] = fit( [Xf, Yf], If, ft, opts );
% 
% p.fit = fr;
% p.gof = gof;
% 
% p.A = fr.A;
% p.mu = [fr.x0; fr.y0];
% p.x0 = fr.x0;
% p.y0 = fr.y0;
% 
% p.sigma = 2*[ fr.xwidth^2 fr.corr*fr.xwidth*fr.ywidth; ...
%             fr.corr*fr.xwidth*fr.ywidth fr.ywidth^2 ];
% p.corr = fr.corr;
% p.xwidth = fr.xwidth;
% p.ywidth = fr.ywidth;
% p.c = fr.c; % constant offset

%% older closed form solution with no offset

% fit the mean to the center of mass
mu = [sum(If.*Xf); sum(If.*Yf)] / sum(If);

% compute the covariance matrix
XYminusMu = repmat(sqrt(If),2,1).*([Xf;Yf]-repmat(mu,1,size(Xf,2)));
sigma = 2*(XYminusMu)*(XYminusMu') / sum(I(:));

% find the ratio between computed and actual values to find A
vals = arrayfun(@(x,y) fgauss2(x,y,1,mu,sigma), X, Y);
A = sum(vals(:).*I(:)) / sum(vals(:).^2);

p.mu = mu;
p.sigma = sigma;
p.A = A;

