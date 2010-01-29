function [ I ] = fgauss(X,A,mu,sigma)
%FGAUSS2 Evaluates N-D Gaussian
% I = fgauss2(X,A,mu,sigma)
% 
% X should be Dims x Npts, A scalar, mu 2x1, sigma 2x2

D = size(X,1); % dimensions
Xmu = X-repmat(mu,1,size(X,2)); 
I = A  * exp(-sum((Xmu' * sigma^(-1)) .* Xmu',2));

end

