function [ c name ] = segevcmap( ind )
%SEGEVCMAP Segev et al. J. Neurophys 2006 color coded ganglion cell types
% except 50 is used for unclassified
% cmap = segevcmap() returns entire colormap
% [cmap names] = segevcmap() returns entire colormap and list of names
% c = segevcmap(i) returns color for i
% [c name] = segevcmap(i) returns color and string name for i

N = 43;
greylevel = 0.4;
cmap = ones(N,3) * greylevel; % 0 or anything not listed below: grey (unclassified)
names = cell(43,1);

% 0 or anything not listed below: grey (unclassified)
cmap(1,:) = [0.8 0.8 0.98]; % light blue (fast ON)
    names{1} = 'Light Blue: Fast ON';
cmap(8,:) = [0 0 0]; % black (reverse adapting cells/biphasic OFF)
    names{8} = 'Black: Reverse Adapting/Biphasic OFF';
cmap(16,:) = [1 0.8 1]; % pink (slow OFF)
    names{16} = 'Pink: Slow OFF';
cmap(17,:) = [0 0.7 0]; % green (medium OFF)
    names{17} = 'Green: Medium OFF';
cmap(19,:) = [0.7 0 0]; % red (standard adapting/biphasic OFF)
    names{19} = 'Red: Adapting/Biphasic OFF';
cmap(29,:) = [0.9 0.9 0.2]; % yellow (monophasic OFF)
    names{29} = 'Yellow: Monophasic OFF';
cmap(43,:) = [0 0 0.7]; % blue (slow ON)
    names{43} = 'Blue: Slow ON';
cmap(45,:) = [0.8 0.48 0.96]; % purple
    names{45} = 'Purple: Sensitizing?';
cmap(50,:) = greylevel*ones(1,3);
    names{50} = 'Unclassified';

if(nargin == 0) % return entire map and names
    c = cmap;
    name = names;
elseif(isnan(ind) || ind == 0)
    c = greylevel*ones(1,3); % 0 or anything not listed below: grey (unclassified)
    name = '';
else
    c = cmap(ind,:);
    name = names{ind};
end

end

