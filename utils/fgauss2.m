function [ I ] = fgauss2( X, Y, A, mu, sigma )
P = [reshape(X,1,[]); reshape(Y,1,[])];
I = reshape(fgauss(P,A,mu,sigma),size(X));
end

