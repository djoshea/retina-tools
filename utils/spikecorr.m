function [xc binedges bininds pairinds] = spikecorr(ca, cb, fignum, binedges, crosstype, colors)
% [xc binedges bininds] = spikecorr(ca, cb, fignum, binedges, colors)
% spike train crosscorrelation and adjacent spike correlation
% 
% ca, cb are spike times [ if isequal(ca,cb), ignores central t=0 bin for autocorr
% fignum is figure to plot to (optional, 0 means don't plot)
% binedges are the bins, see histc (optional)
% cross type is either 'all' (default) or 'nearest' for adjacent spike
% pairs only
% colors is length(binedges) x 3 colors for each bin (optional)
%
% xc is the count in each bin, to make distribution should be divided by (binwidth*length(ca)*length(cb))
% binedges are the bins
% bininds 
%   for crosstype=='all' is length(ca) x length(cb): assignment of each pair 
%      of spikes into each bin in binedges
%   for crosstype=='nearest' is npairs x 1: assignment of each pair (in
%       pairInds) into each bin in binedges
% pairinds: for crosstype=='nearest' only, is a npairs x 2 set of indices
%      into ca, cb for each pair counted in the histogram

if(~exist('fignum', 'var'))
    fignum = 0;
end

if(~exist('binedges', 'var') || isempty(binedges))
    binwidth = 0.001;
    halfwidth = 0.1;
    binedges = -halfwidth:binwidth:halfwidth;
    nbins = length(binedges) - 1;
else
    binwidth = binedges(2) - binedges(1);
    nbins = length(binedges) - 1;
end

if(~exist('colors', 'var'))
    colors = zeros(nbins, 3); % default to all black
end

if(~exist('crosstype', 'var'))
    crosstype = 'all';
    pairinds = [];
end

if(size(ca,1) < size(ca,2))
    ca = ca';
end
if(size(cb,1) < size(cb,2))
    cb = cb';
end

if(isequal(ca, cb)) 
    autocorr = 1;
else
    autocorr = 0;
end

% xlims
mindelta = min(binedges);
maxdelta = max(binedges);

if(strcmp(crosstype, 'all'))
    CA = repmat(ca, 1, length(cb));
    CB = repmat(cb', length(ca), 1);
    df = CA - CB;
    
    % histfn = @(center, search) histc(center-search, binedges);
    
    [xc inds] = histc(df(:), binedges);
    % xc = xc / (binwidth) / numel(df); % normalize to firing rate
    bininds = reshape(inds, size(df));
else % nearest neighbor spikes only
    
    % sort all spikes by time, maintain idx in second col, src (1 or 2) in third
    splist = sortrows([ca, (1:length(ca))',   ones(size(ca)); ...
                       cb, (1:length(cb))', 2*ones(size(cb))], 1);
    df = diff(splist(:,3)); % find changes in src (A then B or B then A)
    
                 % spike ind from A      , spike ind from B
    if(autocorr)
        % copy the B then A spikes twice but invert the sign in first half
        pairinds = [splist(find(df==-1)+1,2), splist(     df==-1   ,2)];
        tdelta = ca(pairinds(:,1)) - cb(pairinds(:,2));
        pairinds = [pairinds; pairinds];
        tdelta = [-tdelta; tdelta];
    else
        pairinds = [ splist(     df== 1   ,2), splist(find(df== 1)+1,2); ... % A then B
                     splist(find(df==-1)+1,2), splist(     df==-1   ,2)];    % B then A
        tdelta = ca(pairinds(:,1)) - cb(pairinds(:,2));
    end
        [xc bininds] = histc(tdelta, binedges);
end

if(isequal(ca, cb)) % same cell against itself --> autocorrelation
   [~, zerobin] = histc(0, binedges); % find zerobin
   xc(zerobin) = 0;
   bininds(bininds == zerobin) = 0;
   autocorr = 1;
else
   autocorr = 0;
end

if(fignum)
    figure(fignum), clf
    % manually draw bar plot to set the colors easily
    for b = 1:length(xc)-1
        xp = [binedges(b) binedges(b+1) binedges(b+1) binedges(b)];
        yp = [0 0 xc(b) xc(b)];
        patch(xp, yp, colors(b,:), 'EdgeColor', 'none');
    end
    
    xlim([mindelta maxdelta]);
    xlabel('Time Offset (ms) [ Cell A - Cell B ]');
    ylabel('Distribution');

    if(autocorr)
        ttl = 'Auto Correlation';
    else
        ttl = 'Cross Correlation';
    end
    
    if(~strcmp('crosstype','all'))
        ttl = [ttl ' (adjacent spikes)'];
    end
    title(ttl);
end