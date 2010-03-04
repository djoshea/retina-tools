% Figures for lab meeting

load rf5sync
set(0,'DefaultFigureColor',[1 1 1]);

%% Plot RF Map
plotrfmap(rf,'fignum',1,'showaxes',1,'showlabels',1);
axis equal
set(gca,'XTick',16:2:34)
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

generateSyncTimesPair(rf.c1,rf.c2,11,twind,cwind,'nearest');
print(11,'-depsc2','fig_spikecorr1v2');

generateSyncTimesPair(rf.c9,rf.c14,11,twind,cwind,'nearest');
print(11,'-depsc2','fig_spikecorr9v14');

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

syncpairrf(rf,1,2,'justcells',0,'fignum',3,'plotprojcent',0,'useleadingspike',1)
print(3,'-depsc2','fig_syncpairrf1v2')

syncpairrf(rf,2,33,'justcells',0,'fignum',3,'plotprojcent',0,'useleadingspike',1)
print(3,'-depsc2','fig_syncpairrf2v33')

syncpairrf(rf,19,20,'justcells',0,'fignum',3,'plotprojcent',0,'useleadingspike',1)
print(3,'-depsc2','fig_syncpairrf19v20')

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

 




