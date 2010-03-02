function I = pinkframe(Nx, Ny, seed,fignum,resizefactor)
% I = pinkframe(Nx, Ny, seed,fignum,resizefactor)
%    generates a pink noise image
%    thanks to Jon Yearsley [ j.yearsley@macaulay.ac.uk ] for writing the 
%    spatialPattern.m script which helped to clarify the algorithm

if(~exist('seed','var'))
    seed = 0; % random number generator seed
end

if(~exist('fignum','var'))
    fignum = 0;
end

if(~exist('resizefactor','var'))
    resizefactor = 1;
else
    Nx = Nx/resizefactor;
    Ny = Ny/resizefactor;
end

beta = -1; % type of noise (0 for white, -1 for pink, -2 for brown)
maxfreq = 80; % frequency cutoff?

% build up stimulus in frequency domain
x = [(0:floor(Nx/2)) -(ceil(Nx/2)-1:-1:1)]'/Nx;
y = [(0:floor(Ny/2)) -(ceil(Ny/2)-1:-1:1)]'/Ny;
[X Y] = meshgrid(x, y);

% mask out frequencies above maximum
freqmask = (abs(X) <= maxfreq/Nx & abs(Y) <= maxfreq/Ny);

% seed random number generator
rand('state',seed);

% build up image in frequency domain
mag = abs(randn(Ny,Nx) .* real((X.^2+Y.^2)).^(beta/4)); % magnitude
mag(mag == Inf) = 0;
mag(~freqmask) = 0; % apply mask
ph = 2*pi*rand(Ny,Nx); % phases

% create complex frequency domain
freq = mag.*(cos(ph)+1j*sin(ph));
I = real(ifft2(freq));

% upsample image?
if(resizefactor ~= 1)
    I = imresize(I,resizefactor);
end

% scale to [0, 1] range
I = (I - min(I(:))) / (max(I(:)) - min(I(:)));

% threshold image?
% thresh = 0.5;
if(exist('thresh','var'))
    I = I >= thresh;
end

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
    pos(3) = Nx*resizefactor;
    pos(4) = Ny*resizefactor;
    set(gcf,'Position', pos);
    axis off;
end