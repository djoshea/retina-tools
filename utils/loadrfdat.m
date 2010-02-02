sens = zeros(50,50);

RF1 = 46;
RF2 = 61;
RFt = 50;

[X Y] = meshgrid(1:RF2, 1:RF1);

clf;
xlim([1 RF1]);
ylim([1 RF2]);

figure(1), clf;
figure(2), clf;

cell = 1;
while(1)
rf_fldname = sprintf('c%d_rf', cell);
pos_fldname = sprintf('c%d_pos', cell);
ker_fldname = sprintf('c%d_ker',cell);
if(~isfield(rfdat, rf_fldname))
    break;
end

if(isnan(rfdat.shape(cell)))
    cell = cell + 1;
    continue;
end

fprintf('Processing cell %3d...\n', cell);  

rf = reshape(shiftdim(rfdat.(rf_fldname),1), RF1, RF2, RFt);
pos = rfdat.(pos_fldname);
ker = rfdat.(ker_fldname);
color = segevcmap(rfdat.shape(cell));

%     clf;
%     for i = 1:50
%         pcolor(rf(:,:,i));
%         caxis([min(rf(:)) max(rf(:))]);
%         pause(1/10);
%     end

% do PCA on temporal data to get temporal kernel (1st PC)
thresh = 2*std(rf(:)) + mean(rf(:));
rfthresh = rf .* (rf >= thresh);
[coeff score] = princomp(reshape(rfthresh, RF1*RF2, RFt));
kerPCA = flipud(coeff(:,1));
kerPCA = kerPCA * -sign(mean(kerPCA(1:10)));
figure(1)
plot(1:length(kerPCA), kerPCA, '-', 'Color', rand(1,3), 'LineWidth', 2);
hold on

% project the temporal data onto the kernel to get spatial map
mapPCA = reshape(score(:,1), RF1, RF2);
[val ind] = max(abs(mapPCA(:)));
mapPCA = mapPCA * sign(mapPCA(ind)); % make positive
threshMap = mapPCA .* (mapPCA > mean(mapPCA(:)) + 4*std(mapPCA(:)));

mapRMS = sqrt(sum(rf.^2, 3));

figure(3), clf;
surf(X,Y,threshMap);
title(cell);
drawnow

% fit a 2D gaussian to the spatial map and draw 1-sigma contour
% first find local nhood around peak
%     [val ind] = max(mapRMS(:));
%     [I J] = ind2sub(size(mapRMS), ind);
%     delta = 5;
%     nhood = mapRMS(I-delta:I+delta, J-delta:J+delta);
%     mapRMS = 0*mapRMS;
%     mapRMS(I-delta:I+delta, J-delta:J+delta) = nhood;

%     h = pcolor(X,Y,mapRMS);
%     hold on
%     set(h, 'EdgeColor', 'none');

% p = fitgauss2(X,Y,threshMap);
figure(2);

pl = rfdat.Parameters(cell,:);
z = pl(1);
A = pl(2);
x0 = pl(3);

gausscontour(p.mu, p.sigma, color);
hold on;
drawnow;

cell = cell+1;
end


