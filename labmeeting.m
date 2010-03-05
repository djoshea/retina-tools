% Figures for lab meeting

load rf5sync
set(0,'DefaultFigureColor',[1 1 1]);

ncells = length(rf.shape);

%% Plot RF Map
cvalid = rf.shape==19;
figure(1), clf;
plotrfmap(rf,'fignum',1,'showaxes',1,'showlabels',1,'cellvalid',cellvalid);
axis equal
set(gca,'XLim',[22.5 34.5],'XTick',22:34);
set(gca,'YLim',[15.5 26.5],'YTick',16:26);
print(1,'-depsc2','fig_rf5map')

%% Plot sample spike xcorr

twind = [ -0.06 -0.04;
-0.04 -0.02;
-0.02  0.0;
0.00  0.02;
0.02  0.04;
0.04  0.06; ];
nwind = size(twind,1);
cwind = flipud(copper(nwind+1));
cwind = cwind(1:nwind,:);

pairs = [1 2; 2 33; 9 14; 4 17; 20 21; 21 27];

for i = 1:size(pairs,1)
    mvalid = zeros(ncells,1);
    mvalid(pairs(i,1)) = 1;
    mvalid(pairs(i,2)) = 1;
    figure(1), clf;
    plotrfmap(rf,'fignum',1,'showaxes',1,'showlabels',1,'cellvalid',mvalid);
    axis equal
    set(gca,'XLim',[22.5 34.5],'XTick',22:34);
    set(gca,'YLim',[15.5 26.5],'YTick',16:26);
    print(1,'-depsc2',['fig_rfmap' num2str(pairs(i,1)) 'v' num2str(pairs(i,2))]);
    
    ca = ['c' num2str(pairs(i,1))];
    cb = ['c' num2str(pairs(i,2))];
    fname = ['fig_spikecorr' num2str(pairs(i,1)) 'v' num2str(pairs(i,2))];
    generateSyncTimesPair(rf.(ca),rf.(cb),11,twind,cwind,'nearest');
    print(11,'-depsc2',fname);
end


%% Generate sync spike proportion by pairs for different windows

cellvalid = rf.shape ~= 0 & ~isnan(rf.shape);

[pairProp propInPairCell cInPair] = syncSpikeProportionMap(rf,'twind',[-0.05 0.05], 'cellvalid', cellvalid);
print(20,'-depsc2','fig_syncpairprop50ms');

[pairProp propInPairCell cInPair] = syncSpikeProportionMap(rf,'twind',[-0.02 0.02], 'cellvalid', cellvalid);
print(20,'-depsc2','fig_syncpairprop20ms');

[pairProp propInPairCell cInPair] = syncSpikeProportionMap(rf,'twind',[-0.01 0.01], 'cellvalid', cellvalid);
print(20,'-depsc2','fig_syncpairprop10ms')

[pairProp propInPairCell cInPair] = syncSpikeProportionMap(rf,'twind',[-0.005 0.005], 'cellvalid', cellvalid);
print(20,'-depsc2','fig_syncpairprop5ms')

[pairProp propInPairCell cInPair] = syncSpikeProportionMap(rf,'twind',[-0.001 0.001], 'cellvalid', cellvalid);
print(20,'-depsc2','fig_syncpairprop1ms')

%% Generate syncpairrf maps for various pairs of cells

syncpairrf(rf,1,2,'justcells',0,'fignum',3,'plotprojcent',1,'useleadingspike',1)
print(3,'-depsc2','fig_syncpairrf1v2')

syncpairrf(rf,2,33,'justcells',0,'fignum',3,'plotprojcent',1,'useleadingspike',1)
print(3,'-depsc2','fig_syncpairrf2v33')

syncpairrf(rf,19,20,'justcells',0,'fignum',3,'plotprojcent',1,'useleadingspike',1)
print(3,'-depsc2','fig_syncpairrf19v20')

syncpairrf(rf,20,21,'justcells',0,'fignum',3,'plotprojcent',1,'useleadingspike',1)
print(3,'-depsc2','fig_syncpairrf20v21')

% change 2nd and 3rd args and image filename, etc...

%% Generate red cell adjacency grid with syncrf centers projected onto
%  connecting vectors

rf.shape([28 19 30]) = 45; % set big red cells to purple (sensitizing)

projcentlength = syncadjacentrf(rf,'fignum',16,'shapevalid',19,...
    'plotbidir',0,'plotcentlengths',2,'useleadingspike',1);
title('Synchronous RFs along Delaunay Triangulation Edges');
axis equal
set(gcf,'Position',[ 36    10   962   774]);
xlim([ 22.7806   33.1041]);
ylim([ 16.3356   25.9045]);
print(16,'-depsc2','fig_adjacentpairrf');

%% Scatter plots of normalized distance projected along connecting vectors

plotprojcentlength(rf,projcentlength,'fignum',51)
print(51,'-depsc2','fig_projcentscatter');
print(52,'-depsc2','fig_projcentsorted');

 




