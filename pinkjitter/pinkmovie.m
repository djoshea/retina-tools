Nx = 500; % size of stimulus
Ny = 500;
Nt = 1000; % number of stimulus frames

beta = -1; % type of noise (0 for white, -1 for pink, -2 for brown)
maxfreq = 20;

alpha = 1; % exponential smoothing factor (0 means no smoothing, 1 means constant)

isi = 50; % inter saccade interval
saccadesteps = 5; % saccade interval
saccadelengthvariance = 300; % variance of saccade vector length RV

colormap gray;
figure(1), clf;
set(gcf, 'Color', 'white');
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

x = [(0:floor(Nx/2)) -(ceil(Nx/2)-1:-1:1)]'/Nx;
y = [(0:floor(Ny/2)) -(ceil(Ny/2)-1:-1:1)]'/Ny;
[X Y] = meshgrid(x, y);

freqmask = zeros(Nx,Ny);

magsmooth = zeros(Nx,Ny);
phsmooth = zeros(Nx,Ny);

offset = [ 0 0 ];
saccadevec = [0 0];

for i = 1:Nt
    if(alpha < 1 || i == 1)
        mag = abs(randn(Nx,Ny) .* real((X.^2+Y.^2)).^(beta/4));
        mag(mag == Inf) = 0;
        ph = 2*pi*rand(Nx,Ny);

        if(i == 1)
            % set as first frame directly (to avoid smoothing with 0s)
            magsmooth = mag;
            phsmooth = ph;
        else
            % exponential smoothing update
            magsmooth = magsmooth*alpha + mag*(1-alpha);
            phsmooth = phsmooth*alpha + phsmooth*(1-alpha);
        end

        freq = mult*magsmooth.*(cos(phsmooth)+1j*sin(phsmooth));
        I = real(ifft2(freq));
    end
    
    % Change offset to translate image
    if(mod(i,isi) == 0)
        % beginning of saccade
        saccadevec = randn(1,2)*saccadelengthvariance;
        disp('Saccade!')
    end
    
    if(i >= saccadesteps && mod(i,isi) >= 0 && mod(i,isi) < saccadesteps)
        % beginning or in the middle of saccade
        offset = offset + round(saccadevec / saccadesteps);
    else
        % not in a saccade, random walk jitter
        offset = offset + floor(rand(1,2)*3)-1;
    end
    
    Ishift = circshift(I, offset);
    
%     imagesc(imresize(Ishift,[5*Nx 5*Ny],'bilinear'));
    imagesc(Ishift');
    axis off;
    drawnow
end