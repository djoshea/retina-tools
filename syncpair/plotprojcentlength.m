function plotprojcentlength( rf, projcentlength, varargin )

def.fignum = 10;
assignargs(def,varargin);

% where to plot each twind along x axis
xposwinds = mean(rf.pairMapWindTimes,2);
xposeval = linspace(min(rf.pairMapWindTimes(:)), max(rf.pairMapWindTimes(:)), 100);

nedges = size(projcentlength,1);
nwind = size(projcentlength,2);

% rainbow colormap by pair
colors = cell(nedges,nwind);
cmap = jet(nedges);
for ei = 1:nedges
    for w = 1:nwind
        colors{ei,w} = rf.pairMapWindCmap(w,:);
    end
end

%% Figure out how to sort the edges list
Npoly = 1; % polyfit degree
% polysterm = z
linfits = zeros(nedges,Npoly+1);
rsqvals = zeros(nedges,1);
validw = zeros(nedges,nwind);

for ei = 1:nedges
    for w =  1:nwind
        if(~isempty(projcentlength{ei,w}) && projcentlength{ei,w} > -0.3 && projcentlength{ei,w} < 1.3)
            validw(ei,w) = 1;
        end
    end
    
    fitvalidw = validw(ei,:);
    fitvalidw(1) = 0;
    fitvalidw(end) = 0;
    fitvalidw = logical(fitvalidw);
    
    % do linear regression on the plot
%     [b,~,~,~,stats] = regress([projcentlength{ei,fitvalidw}]',...
%          [xposwinds(fitvalidw) ones(sum(fitvalidw),1)]);
    [linfits(ei,:) polysterm(ei)] = polyfit(xposwinds(fitvalidw), [projcentlength{ei,fitvalidw}]',Npoly);
%     linfits(ei,:) = b';
%     rsqvals(ei) = stats(1);
    
end

validw = logical(validw);
% [~, sortorder] = sort(linfits(:,1));

minmaxdiff = zeros(nedges,1);
for ei = 1:nedges
    vals = [projcentlength{ei,:}];
    minmaxdiff(ei) = max(vals) - min(vals);
end
[~, sortorder] = sort(minmaxdiff);

%% Plot time vs. normalized distance, connect each pair with gray lines
% Also compute linear fit and r^2 value for later sorting

figure(fignum); clf;
hold on;
for ei = 1:nedges
    for w =  1:nwind
        if(validw(ei,w))
            plot(xposwinds(w), projcentlength{ei,w},'o','MarkerSize',4,...
                'MarkerFaceColor',colors{ei,w}, 'MarkerEdgeColor', colors{ei,w});
        end
    end
    
    plot(xposwinds(validw(ei,:)), [projcentlength{ei,validw(ei,:)}],'-','LineWidth',1,'Color',0.4*[1 1 1]);
   
    y = polyval(linfits(ei,:),xposeval);
%     errormag = norm(delta);
%     plot(xposeval, y,'-',...
%         'Color',rsqvals(ei)*ones(1,3),'LineWidth',1);
end

plot([-100 100],[0 0; 1 1]','--', 'LineWidth',1,'Color',[1 0 0]);

xlim([min(xposeval), max(xposeval)]);
ylim([-.2 1.2]);
xlabel('Mean of Relative Timing Window');
ylabel('Normalized Connecting Line Distance');
title('Normalized Connecting Line Distances');



%% Plot each edge as a row unsorted

figure(fignum+1); clf;
hold on;
for esi = 1:nedges
    ei = sortorder(esi);
    for w =  1:nwind
        if(validw(ei,w))
            plot(esi,projcentlength{ei,w},'o','MarkerSize',4,...
                'MarkerFaceColor',colors{ei,w}, 'MarkerEdgeColor', colors{ei,w});
        end
    end
end
plot([-100 100],[0 0; 1 1]','--', 'LineWidth',1,'Color',[1 0 0]);

title('Normalized Connecting Line Distances (sorted by span)');
ylim([-0.2 1.2]);
xlim([-0.1 nedges+0.1]);

end

