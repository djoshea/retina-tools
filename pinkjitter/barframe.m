function [I barlevels] = barframe(Nx, Ny, barthick, nlevels, rstream,fignum)
% I = barframe(Nx, Ny, seed,fignum)
%    generates a vertical bar image

if(~exist('seed','var'))
    seed = 0; % random number generator seed
end

if(~exist('fignum','var'))
    fignum = 0;
end

% seed random number generator
% rstream = RandStream.create('mrg32k3a','NumStreams',1,'Seed',seed);

levels = linspace(0,1,nlevels);
nbars = ceil(Nx/barthick);
barlevels = ceil(nlevels*rand(rstream,1,nbars));
barvalues = levels(barlevels);
I = imresize(barvalues,[Ny nbars*barthick],'box');

% display resulting image in figure window?
if(fignum)
    colormap gray;
    figure(fignum), clf;
    set(gcf, 'Color', 'white');
    imagesc(I);
    set(gcf, 'MenuBar', 'none');
    set(gca, 'Position', [0 0 1 1]);
    set(gcf, 'Name', 'Pink Noise Stimulus');
    set(gcf, 'NumberTitle', 'off');
    set(gcf, 'Units', 'pixels');
    pos = get(gcf, 'Position');
    pos(3) = Nx;
    pos(4) = Ny;
    set(gcf,'Position', pos);
    axis off;
end