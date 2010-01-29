function [ P ] = meshflat( xrange, yrange )
%MESHFLAT generates a flattened (2xN) version of a 2D meshgrid

[X Y] = meshgrid(xrange, yrange);
P = [reshape(X,1,[]);reshape(Y,1,[])];

end

