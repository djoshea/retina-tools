% Demonstration of fitting a 2D Gaussian function and plotting contours

%% Create surface to fit

A = 10*rand(1);
mu = 0.3*rand(2,1);
var = 0.5*rand(2,1) + 0.5;
rho = 2*rand(1)-1;
sigma = [ var(1)^2 rho*var(1)*var(2); rho*var(1)*var(2) var(2)^2 ];
       
pts = -2:0.1:2;
P = meshflat(pts, pts);
[X Y] = meshgrid(pts, pts);

fXY = @(X,Y) fgauss2(X,Y,A,mu,sigma);
I = fgauss2(X,Y,A,mu,sigma);

clf
subplot(1,2,1);

h = pcolor(X,Y,I);
set(h,'EdgeColor','none');
% colormap gray
xlim([min(pts) max(pts)]);
ylim([min(pts) max(pts)]);
clim = caxis();
title('Generating Function');
axis square
hold on

%% fit the data to a 2D Gaussian
[Afit mufit sigmafit] = fitgauss2(X,Y,I);
fXYfit = @(X,Y) fgauss2(X, Y, Afit, mufit, sigmafit);
Ifit = fXYfit(X,Y);

% plot surface for fitted params
subplot(1,2,2);
h = pcolor(X,Y,Ifit);
set(h,'EdgeColor','none');
xlim([min(pts) max(pts)]);
ylim([min(pts) max(pts)]);
title('Fitted Fn, Analytic Contour');
caxis(clim);
axis square
hold on

% plot 1 sigma contours and semiaxes
[xpts ypts] = gausscontour(mufit, sigmafit, 1, 1);

