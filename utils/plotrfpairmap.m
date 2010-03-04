function [handles projcentlength] = plotrfpairmap(rfdat, varargin)
% plot sync rfs for a whole map (or for specified edges)
pairMapParams = rfdat.pairMapParams;
twind = rfdat.pairMapWindTimes;

def.fignum = 0; % figure to plot into, 0 means new figure
def.cmap = rfdat.pairMapWindCmap; % colormap used for the sync rfs
def.offset = [0, 0]; % offset used to plot the map
def.edges = 'all'; % alternatively, could be Nx2 list of edges (cell ids)
def.plotbidir = 0; % plot rfs computed for spikes taken from both cells
def.widthmax = 10; % used to filter rfs that are too big
def.plotprojcent = 1; % instead of the ellipse, project the center onto the vector connecting the cells
def.cellvalid = ones(size(rfdat.Parameters,1),1); % list of cells to consider (indicator list)
def.useleadingspike = 1; % use the rf computed for the cell whose spike leads in the window (choose cell based on the sign of the twind's mean)
assignargs(def,varargin);

ncells = size(pairMapParams,1);

if(ischar(edges) && strcmp(edges, 'all'))
    edges = zeros(ncells^2,2);
    edges(:,1) = imresize((1:ncells)',[ncells^2 1],'box');
    edges(:,2) = repmat((1:ncells)',ncells,1);
end

nedges = size(edges,1);
nwind = size(pairMapParams,3);
handles = cell(nedges,nwind,2);

if(fignum)
    figure(fignum);
else
    figure();
end
hold on

% the normalized distance of the rf for pair i in window j projected
% along the connecting vector (0 = cell A to 1 = cell B)
projcentlength = cell(nedges,nwind); 

% display time window colorbar
colormap(cmap);
h = colorbar;
set(h,'YTick', 1.5:1:nwind+0.5);
labelfn = @(i) sprintf('%d - %d ms',1000*twind(i,1),1000*twind(i,2));
set(h,'YTickLabel', arrayfun(labelfn, 1:nwind, 'UniformOutput', 0));
% set(h,'TickLength', [0 0]);

for ei = 1:nedges % loop over cell pairs to plot
    ca = edges(ei,1);
    cb = edges(ei,2);
    
    if(~cellvalid(ca) || ~cellvalid(cb))
        % skip this pair if either cell is invalid
        continue;
    end
    
    % get centers of RFs
    camu = rfdat.Parameters(ca,[3 5]) + offset;
    cbmu = rfdat.Parameters(cb,[3 5]) + offset;
    
    for w = 1:nwind % loop over time window
        for di = 1:2 % plot both directions (should be =2)
            
            % skip the spikes from the other cell if:
                % we're not plotting both cell's spikes' rfs
                % and we're not plotting leading spikes
            if(di == 2 && ~plotbidir && ~useleadingspike)
                continue;
            end
            
            if(useleadingspike && di==2 && mean(twind(w,:)) < 0)
                % the first cell (di == 1) leads if the window is negative
                % so skip this one
                continue;
            end
            
            if(useleadingspike && di==1 && mean(twind(w,:)) >= 0)
                % the second cell (di == 2) leads if the window is positive
                % so skip this one
                continue;
            end
            
            params = pairMapParams{ca,cb,w,di};
            z0 = params(1);
            A = params(2);
            x0 = params(3) + offset(1);
            xwidth = params(4);
            y0 = params(5) + offset(2);
            ywidth = params(6);
            cor = params(7);
            
            if(abs(xwidth) > widthmax || abs(ywidth) > widthmax)
                % skip the cell if its rf is too big - bad fit likely
                continue;
            end

            mu = [x0; y0];
            sigma = [xwidth^2, cor*xwidth*ywidth; ...
                     cor*xwidth*ywidth, ywidth^2];
            color = cmap(w,:);
            
            if(di == 2 && ~useleadingspike) % plot other direction spikes the other way
                linespec = '--';
                facecolor = 'none';
            else
                linespec = '-';
                facecolor = color;
            end
            
            if(plotprojcent)
                % plot the projection of the rf center along the connecting
                % vector
                pt = camu + dot(mu'-camu,cbmu-camu) / norm(cbmu-camu)^2 * (cbmu-camu);
                
                % calculate normalized distance along line
                projcentlength{ei,w} = dot(mu'-camu,cbmu-camu) / norm(cbmu-camu)^2;
                
                plot(pt(1),pt(2),'o','MarkerEdgeColor',color,'MarkerSize',5,'MarkerFaceColor',facecolor);
            else
                % plot the ellipses of each sync rf, not just the center
                % dot
                try
                    [ ~, ~, h ] = gausscontour(mu,sigma,color,linespec);
                    handles{ei,w,di} = h;
                catch
                    handles{ei,w,di} = NaN;
                    disp('error!')
                end
            end
        end
    end
    
%     fprintf('Display cell pair %d vs. %d...\n',ca,cb)
%     drawnow   
    
end
    