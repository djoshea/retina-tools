function [times] = generateSyncTimesPair(ca, cb, fignum, twind, cwind, crosstype)
% ca, cb are firing times for the pair
% twind is a W x 2 set of lower, upper bounds on relative firing times
% cwind is W x 3 color associated with each window for the plot (optional)
% crosstype is either 'all' or 'nearest' (consider only adjacent pairs)
% times: W x 2 cell array of times falling in the corresponding twindow
%     (one set of times for each cell)

if(~exist('twind', 'var'))
    twind = [ -0.05 0.05 ]; % default to +/- 50 ms window
end
if(~exist('cwind', 'var'))
    cwind = [ 0.8 0.2 0.2 ];
end

if(~exist('fignum', 'var'))
    fignum = 0;
end
if(~exist('crosstype', 'var'))
    crosstype = 'all';
end

minedge = min(twind(:,1));
maxedge = max(twind(:,2));
binwidth = 1e-3;
binedge = minedge-10*binwidth:binwidth:maxedge+10*binwidth;
W = size(twind,1);

colors = zeros(length(binedge),3);
for w = 1:W
    inds = binedge >= twind(w,1) & binedge <= twind(w,2);
    colors(inds,:) = repmat(cwind(w,:), nnz(inds), 1);
end

if(strcmp(crosstype, 'all'))
    [~, ~, bininds] = spikecorr(ca, cb, fignum, binedge, 'all', colors);
else
    % nearest neighbor
    [~, ~, bininds, pairinds] = spikecorr(ca, cb, fignum, binedge, 'nearest', colors);
end

% find times from each cell that were assigned into each window
times = cell(W,2);
for w = 1:W
     % bins that fall into this window
    inds = find(binedge >= twind(w,1) & binedge < twind(w,2));
    % spike pairs that fall into these bins
    if(strcmp(crosstype, 'all'))
        [i j] = find(bininds >= min(inds) & bininds <= max(inds));
        % and index from these pairs back into the original times
        times{w,1} = ca(unique(i));
        times{w,2} = cb(unique(j));
    else
       % nearest neighbor spikes
       rows = find(bininds >= min(inds) & bininds <= max(inds));
       times{w,1} = ca(unique(pairinds(rows,1)));
       times{w,2} = cb(unique(pairinds(rows,2)));
    end
end

