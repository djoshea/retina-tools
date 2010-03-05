function newoffset = calcrfoffset(rfa, rfm, offset)
% calculate offset from rfm (move) to rfa (anchor)

if(~exist('offset', 'var'))
    offset = [ 0 0 ];
end

Nm = size(rfm.Parameters,1);
Na = size(rfa.Parameters,1);

%% filter down the pairwise comparisons between cells that we consider

% eliminate comparisons with NaN cells
validpair = double(~isnan(rfm.shape)) * double(~isnan(rfa.shape)');

% consider only pairs of the same class (i.e. shape or color values match)
shapematch = repmat(rfm.shape,1,Na) == repmat(rfa.shape',Nm,1);
validpair = validpair & shapematch;

mx0 = rfm.Parameters(:,3);
my0 = rfm.Parameters(:,5);
ax0 = rfa.Parameters(:,3);
ay0 = rfa.Parameters(:,5);

% vectors from move cell i to anchor cell j
Xdelta = repmat(ax0',Nm,1) - repmat(mx0,1,Na) - offset(1); 
Ydelta = repmat(ay0',Nm,1) - repmat(my0,1,Na) - offset(2);

% centroids within distmax distance
mudist = sqrt(Xdelta.^2 + Ydelta.^2);
distmax = 3;
validpair = validpair & (mudist <= distmax);

mxw = rfm.Parameters(:,4);
myw = rfm.Parameters(:,6);
mcor = rfm.Parameters(:,7);
axw = rfa.Parameters(:,4);
ayw = rfa.Parameters(:,6);
acor = rfa.Parameters(:,7);

% ellipse width, height, and angle similar
Xwdelta = repmat(axw',Nm,1) - repmat(mxw,1,Na); 
Ywdelta = repmat(ayw',Nm,1) - repmat(myw,1,Na);
cordelta = repmat(acor',Nm,1) - repmat(mcor,1,Na);

widthdeltamax = 0.5;
validpair = validpair & (abs(Xwdelta) <= widthdeltamax);
validpair = validpair & (abs(Ywdelta) <= widthdeltamax);

cordeltamax = 0.1;
validpair = validpair & (abs(cordelta) < cordeltamax);

% list of valid translation vectors to consider
xlist = Xdelta(validpair);
ylist = Ydelta(validpair);
deltasearch = 0.1;
spacing = -distmax:deltasearch:distmax;
[X Y] = meshgrid(spacing);

% smooth scatter points with a Gaussian to form heat map
sigmasmooth = 0.1;
density = zeros(size(X));
for i = 1:length(xlist)
     gfn = @(x,y) exp( -((x-xlist(i)).^2 + (y-ylist(i)).^2) / (2*sigmasmooth^2) );
     density = density + arrayfun(gfn, X, Y);
end
    
% pick the maximum off the heat map as the new offset
[~, ind] = max(density(:));
newoffset = offset + [X(ind), Y(ind)];

%% Debugging Plots

% % plot cells considered for a specific move cell
% figure(1),clf;
% mi = 11;
% [mu sigma] = convertgauss(rfm.Parameters(mi,:));
% gausscontour(mu, sigma, [0 0 0], '--');
% hold on
% for ai = 1:Na
%    if(validpair(mi,ai))
%       [mu sigma] = convertgauss(rfm.Parameters(ai,:));
%       gausscontour(mu, sigma, segevcmap(rfa.shape(ai)), '-');
%    end
% end

% % plot gaussian smoothed heat map
% figure(2), clf
% h = pcolor(X,Y,density);
% set(h,'EdgeColor','None');
% title('Smoothed Offset Heatmap');
% xlabel('x 100 um');
% ylabel('x 100 um');
% box off
% 
% 
% 
% % plot sampled points and offset vector
% figure(8), clf;
% plot(Xdelta(validpair), Ydelta(validpair), 'ro','MarkerSize',5,'MarkerFaceColor','r');
% hold on
% quiver(0, 0, X(ind), Y(ind),'-', 'LineWidth',2,'Color',[0.4 0.4 0.4]);
% pause(0.4)
% box off
% title('Candidate Offset Vectors');
% xlabel('x 100 um');
% ylabel('x 100 um');

end