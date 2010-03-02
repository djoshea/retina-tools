function syncpairrf( rfdat, ca, cb, varargin)

def.fignum = 0;
def.justcells = 0;
def.plotbidir = 0;
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

plotrfmap(rfdat, 'cellvalid', cellvalid, 'fignum', fignum);
if(~justcells)
    plotrfpairmap(rfdat,'edges',[ca cb],'fignum',fignum,'plotbidir',plotbidir);
end
title(sprintf('Cell %d vs. %d\n',ca,cb));

end

