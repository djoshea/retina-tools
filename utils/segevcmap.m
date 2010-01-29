function [ c ] = segevcmap( ind )
%SEGEVCMAP segev color coded ganglion cell types
% cmap = segevcmap() returns entire colormap
% c = segevcmap(i) returns color for i

N = 19;
cmap = zeros(N,3);

cmap(16,:) = [0.5 0 0.5];
cmap(17,:) = [0 0.7 0];
cmap(19,:) = [0.7 0 0];

if(nargin == 0)
    c = cmap;
elseif(isnan(ind))
    c = [0.4 0.4 0.4];
else
    c = cmap(ind,:);
end

end

