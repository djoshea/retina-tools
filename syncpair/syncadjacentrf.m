function projcentlength = syncadjacentrf( rfdat, varargin)
% plot syncRFs between adjacent cells (limited by cellvalid indicator list)

def.fignum = 0;
def.justcells = 0; % just plot the cell's rfs for debugging
def.plotbidir = 0; % plot spikes for each cell in the pair
def.shapevalid = unique(rfdat.shape); % filter out unwanted shapes
def.cellvalid = ones(size(rfdat.Parameters,1),1); % filter out unwanted cells
def.plotcentlengths = 0; % 0 or figure to plot normalized rf pos along connecting vector
assignargs(def,varargin);

if(~fignum)
    fignum = figure;
else
    figure(fignum);
end
clf;
hold on;

% filter by valid shapes (in addition to by cellvalid indicator list)
cellvalid = cellvalid & ismember(rfdat.shape,shapevalid);

[list listSimul] = adjacencySimultaneity(rfdat.Parameters,'cellvalid',...
    cellvalid,'grouptype','pair','axh',gca,'recordedEdgeColor',[0.4 0.4 0.4]);
pairlist = list(listSimul==1,:);

plotrfmap(rfdat, 'cellvalid', cellvalid, 'fignum', fignum);
if(~justcells)
    [handles projcentlength] = plotrfpairmap(rfdat, 'cellvalid',cellvalid,...
        'edges',pairlist,'fignum',fignum,'plotbidir',plotbidir);
end


end

