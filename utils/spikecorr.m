function [xc binedges] = spikecorr(ca, cb, fignum, binedges, colors)

if(~exist('fignum', 'var'))
    fignum = 0;
end

if(~exist('binedges', 'var'))
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

% xlims
mindelta = min(binedges);
maxdelta = max(binedges);

CA = repmat(ca, 1, length(cb));
CB = repmat(cb', length(ca), 1);
diff = CA - CB;

% histfn = @(center, search) histc(center-search, binedges);

xc = histc(diff(:), binedges) / (binwidth) / numel(diff); % normalize to firing rate

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
    title('Cross Correlation');
end