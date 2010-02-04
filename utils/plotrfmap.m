function [handles] = plotrfmap(rfdat, fignum, colormult, offset)
% plot receptive field map

if(~exist('colormult', 'var'))
    colormult = 1;
end

if(~exist('fignum', 'var'))
    figure;
else
    figure(fignum);
end

if(~exist('offset', 'var'))
    offset = [ 0 0 ];
end

N = size(rfdat.Parameters, 1);
handles = zeros(N,1);

for cell = 1:N
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
    
    if(~isnan(rfdat.shape(cell)))
        color = segevcmap(rfdat.shape(cell)) .* colormult;
        [ ~, ~, h ] = gausscontour(mu,sigma,color,'-');
        handles(cell) = h;
    else
        handles(cell) = NaN;
    end
    
    
end
    