function [handles] = plotrfmap(rfdat, varargin)
% plot receptive field map
% structargs: fignum, colormult, offset,cmap, cellvalid

def.fignum = 0;
def.colormult = 1;
def.offset = [0 0];
def.cmap = segevcmap();
def.cellvalid = ones(size(rfdat.Parameters,1),1);
def.showlabels = 0; % show text labels by each cell
def.showaxes = 0; % show major minor axes of each cell
assignargs(def,varargin);

if(fignum)
    figure(fignum)
else
    figure;
end
hold on

if(~exist('offset', 'var'))
    offset = [ 0 0 ];
end

if(~exist('cmap','var'))
    cmap = segevcmap();
end

N = size(rfdat.Parameters, 1);
handles = zeros(N,1);

for cell = 1:N
    if(~cellvalid(cell))
        continue;
    end
    params = rfdat.Parameters(cell,:);
    z0 = params(1);
    A = params(2);
    x0 = params(3) + offset(1);
    xwidth = params(4);
    y0 = params(5) + offset(2);
    ywidth = params(6);
    cor = params(7);
    
    mu = [x0; y0];
    sigma = [xwidth^2, cor*xwidth*ywidth; ...
             cor*xwidth*ywidth, ywidth^2];
    
    if(~isnan(rfdat.shape(cell)) && rfdat.shape(cell) > 0)
        color = cmap(rfdat.shape(cell),:);
        try
            if(showlabels)
                label = num2str(cell);
            else
                label = '';
            end
            [ ~, ~, h ] = gausscontour(mu,sigma,color,'-',showaxes,label);
            handles(cell) = h;
        catch
            handles(cell) = NaN;
            disp('error!')
        end
        
    else
        handles(cell) = NaN;
    end
    
    if(mod(cell,100)==0)
        fprintf('Display cell %d / %d...\n',cell,N)
        drawnow
    end
    
end
    