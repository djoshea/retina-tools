function [pairProp propInPairCell cInPair] = syncSpikeProportionMap(rf,varargin)
% compute proportion of spikes that were part of a synchronous pair between all
% valid pairs within the rf map

% pairProp is ncells x ncells: proportion of total spikes for each pair that fell into
%   their synchronous spike window
% propInPairCell is ncells x 1: proportion of cell i's spikes in a
%   synchronous pair with any other valid (the mean of each element of
%   cInPair)
% cInPair is ncells x 1: indicator of which spikes from cell i were in a
%   pair with at least one  other cell



ncells = size(rf.Parameters,1);

def.twind = [-0.06 0.06];
def.cellvalid = ones(ncells,1);
assignargs(def,varargin);

pairProp = zeros(ncells,ncells);
cInPair = cell(ncells,1);

for ci = 1:ncells
    cInPair{ci} = 0*rf.(['c' num2str(ci)]);
end

for ci = 1:ncells
    if(~cellvalid(ci))
        continue;
    end
    for cj = 1:ncells
        if(ci == cj || ~cellvalid(cj))
            continue;
        end
        fprintf('Processing c%02d x c%02d:\t',ci,cj);
        [ciInPair cjInPair] = syncSpikeProportion(rf.(['c' num2str(ci)]), ...
            rf.(['c' num2str(cj)]), 'fignum',0,'twind',twind);
        
        % count proportion of total spikes for both cells counted in the
        % pair
        pairProp(ci,cj) = mean([ciInPair; cjInPair]);
        fprintf('pairprop = %5.2f\n',pairProp(ci,cj));
        
        % check off spikes in this pair that now fall in a pair
        cInPair{ci} = cInPair{ci} | ciInPair > 0;
        cInPair{cj} = cInPair{cj} | cjInPair > 0;
    end
end

propInPairCell = cellfun(@mean,cInPair);


%% Plot each pair on a scatter plot (prop connected vs. distance)
figure(20), clf;
hold on

for ci = 1:ncells
    for cj = ci+1:ncells
         if(~cellvalid(ci) || ~cellvalid(cj))
             continue;
         end
         
         mui = rf.Parameters(ci,[3 5]);
         muj = rf.Parameters(cj,[3 5]);
         dist = sqrt(norm(mui-muj,2));
         
         if(rf.shape(ci) == rf.shape(cj))
            plot(dist,pairProp(ci,cj),'x', 'MarkerSize',10,...
                'LineWidth', 1,'MarkerEdgeColor', segevcmap(rf.shape(ci)));
         else
            plot(dist,pairProp(ci,cj),'o','MarkerSize',5,'LineWidth',1.5,...
                'MarkerEdgeColor',segevcmap(rf.shape(ci)),...
                'MarkerFaceColor',segevcmap(rf.shape(cj)));
         end
                
    end
end

xlabel('Distance (x 100 um)');
ylabel('Proportion of Syncronous Spikes');
title('Proportion of Synchronous Spikes in Pair');

ylim([0 0.45]);

%% Histogram of spikes proportion of each cell included in a pair with some
% other cell

% figure(21), clf
% edges = 0:0.1:1;
% n = histc(propInPairCell,edges);
% bar(edges,n,'histc');
% xlim([0 1]);
%     



