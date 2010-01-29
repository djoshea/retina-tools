function [ A mu sigma ] = fitgauss2(X,Y,I)
%FITGAUSS fit 2D data to a 2D Gaussian
% [A mu sigma] = fitgauss2(X,Y,I)
% X and Y as in meshgrid coordinates, I is the data to fit

% reshape image into row vectors
Xf = reshape(X,1,[]);
Yf = reshape(Y,1,[]);
If = reshape(I,1,[]);

If = (If >= 0) .* If;

% fit the mean to the center of mass
mu = [sum(If.*Xf); sum(If.*Yf)] / sum(If);

% compute the covariance matrix
XYminusMu = repmat(sqrt(If),2,1).*([Xf;Yf]-repmat(mu,1,size(Xf,2)));
sigma = 2*(XYminusMu)*(XYminusMu') / sum(I(:));

% find the ratio between computed and actual values to find A
vals = arrayfun(@(x,y) fgauss2(x,y,1,mu,sigma), X, Y);
A = sum(vals(:).*I(:)) / sum(vals(:).^2);

