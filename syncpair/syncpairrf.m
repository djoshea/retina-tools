function [projcentlength] = syncpairrf( rfdat, ca, cb, varargin)
% plots a pair of cells rfs and all of their sync pairs as either
% gaussian ellipses or dots projected onto the connecting vector

def.fignum = 0; % figure to plot into, 0 means new figure()
def.justcells = 0; % just plot the cells rfs for debugging
def.plotbidir = 0; % show rfs from spike times from both cells (should use useleadingspike instead)
def.plotprojcent = 0; % show as dots projected onto the connecting vector?
def.showlabels = 1; % show text labels by each cell
def.showaxes = 1; % show major minor axes of each cell
def.useleadingspike = 1; % use rfs from the cell whose spike time leads
assignargs(def,varargin);

if(~fignum)
    fignum = figure;
else
    figure(fignum);
end
clf;
hold on;

cellvalid = zeros(size(rfdat.Parameters,1),1);
cellvalid(ca) = 1;
cellvalid(cb) = 1;

plotrfmap(rfdat, 'cellvalid', cellvalid, 'fignum', fignum, ...
    'showaxes',showaxes,'showlabels',showlabels);
if(~justcells)
    [handles projcentlength] = plotrfpairmap(rfdat,'edges',[ca cb],'fignum',fignum,...
        'plotbidir',plotbidir,'plotprojcent', plotprojcent,'useleadingspike',useleadingspike);
end
title(sprintf('Cell %d vs. %d\n',ca,cb));

end

