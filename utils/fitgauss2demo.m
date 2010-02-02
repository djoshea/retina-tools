% Demonstration of fitting a 2D Gaussian function and plotting contours

%% Create surface to fit

A = 10*rand(1);
c = 2*rand(1);
mu = 0.3*rand(2,1);
var = 0.5*rand(2,1) + 0.5;
rho = 2*rand(1)-1;
sigma = [ var(1)^2 rho*var(1)*var(2); rho*var(1)*var(2) var(2)^2 ];
       
pts = -2:0.1:2;
P = meshflat(pts, pts);
[X Y] = meshgrid(pts, pts);

fXY = @(X,Y) fgauss2(X,Y,A,mu,sigma);
I = fgauss2(X,Y,A,mu,sigma) + c;

clim = [min(I(:)) max(I(:))];
zlims = [0 max(I(:))];

clf
subplot(1,2,1);

h = surf(X,Y,I);
set(h,'EdgeColor','none');
view([0 -90]);
% colormap gray
xlim([min(pts) max(pts)]);
ylim([min(pts) max(pts)]);
caxis(clim);
zlim(zlims);
title('Generating Function');
axis square
hold on

%% fit the data to a 2D Gaussian
[p] = fitgauss2(X,Y,I);
fXYfit = @(X,Y) fgauss2(X, Y, p.A, p.mu, p.sigma);
Ifit = fXYfit(X,Y) + p.c;

% plot surface for fitted params
subplot(1,2,2);
h = surf(X,Y,Ifit);
set(h,'EdgeColor','none');
view([0 -90]);
zlim(zlims);
caxis(clim);
xlim([min(pts) max(pts)]);
ylim([min(pts) max(pts)]);
title('Fitted Fn, Analytic Contour');

axis square
hold on

% plot 1 sigma contours and semiaxes
[xpts ypts] = gausscontour(p.mu, p.sigma, [0 0 0], 1);

