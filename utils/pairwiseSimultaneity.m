function [ pairwise ] = pairwiseSimultaneity(shapeunique, foundinmap, cellinds, fignum )
% based on a series of recordings, figures out which unique cells were
% recorded simultaneously in at least one recording
% shapeunique: the color/class of unique cell i
% foundinmap: an indicator matrix nunique x nrf whether cell i was in map j
% pairwise: square matrix, cell i and cell j both recorded in how many maps?
% cell inds indicates what index to label each cell with

if(~exist('fignum', 'var'))
    fignum = 0;
end
if(~exist('cellinds', 'var'))
    cellinds = 1:length(shapeunique);
end

nrf = size(foundinmap,2);
nunique = length(shapeunique);

pairinmap = zeros(nunique,nunique,nrf); % both i,j in map k?

for mi = 1:nrf
    pairinmap(:,:,mi) = foundinmap(:,mi) * foundinmap(:,mi)';
end

pairwise = sum(pairinmap,3);
    
%% plot matrix aesthetically

if(fignum)
   figure(fignum), clf;
   set(fignum, 'Name', 'Pairwise Simultaneity Matrix');
   set(fignum, 'NumberTitle', 'off');
   set(fignum, 'Color', [1 1 1]);
   box off
   
   mc = max(pairwise(:));
   imagesc(pairwise,[0 mc]); 
   cmap = hsv(mc+1);
   cmap(1,:) = [ 0 0 0];
   colormap(cmap);
   axis ij;
   
   labels = arrayfun(@num2str, cellinds, 'UniformOutput', 0);
   set(gcf, 'Pointer', 'fullcrosshair');
   set(gca, 'TickDir', 'out');
   set(gca, 'TickLength', [0.005 0]);
   set(gca, 'XTick', 1:size(pairwise,1));
   set(gca, 'XTickLabel', labels);
   set(gca, 'XAxisLocation', 'top');
   set(gca, 'YTick', 1:size(pairwise,1));
   set(gca, 'YTickLabel', labels);

   % color tick marks by shape() segev color map
   tick2text(gca, 'xformat', @(i) labels{i}, 'yformat', @(i) labels{i}, ...
       'ytickoffset', 0.02, 'xtickoffset', 0.02);
   hx = getappdata(gca, 'XTickText');
   hy = getappdata(gca, 'YTickText');
   for ci = 1:length(hx)
       set(hx(ci), 'Color', segevcmap(shapeunique(ci)));
       set(hy(ci), 'Color', segevcmap(shapeunique(ci)));
   end
   
   % draw colorbar to indicate how many times each pair was recorded
   h = colorbar;
   step = mc/ (mc+1);
   set(h,'YTick', step/2:step:mc);
   set(h,'YTickLabel', arrayfun(@num2str, 0:mc, 'UniformOutput', 0));
   set(h,'TickLength', [0 0]);
  
   title(sprintf('%d / %d (%.2f %%) Simultaneous Pairs Recorded', ...
       nnz(pairwise>0), numel(pairwise), mean(pairwise(:)>0)*100));
end


end

