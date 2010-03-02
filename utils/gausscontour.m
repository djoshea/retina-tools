function [ xepts yepts h ] = gausscontour( mu, sigma, drawcolor, linespec, vectors, label)
% GAUSSCONTOUR draws the 1-sigma contour of a 2D gaussian function
% [ xepts yepts ] = gausscontour( mu, sigma, drawcolor, vectors)

if(~exist('drawcolor','var'))
    draw = 0;
else
    draw = 1;
end

if(~exist('linespec', 'var'))
    linespec = '-';
end
if(~exist('vectors','var'))
    vectors = 0;
end

[V D] = eigs(sigma,2);
d1 = sqrt(D(1,1)); % semimajor axis
d2 = sqrt(D(2,2)); % semiminor axis

% see http://en.wikipedia.org/wiki/Ellipse#General_parametric_form

phi = atan2(V(2,1), V(1,1));
xe = @(t) mu(1) + d1*cos(t)*cos(phi) - d2*sin(t)*sin(phi);
ye = @(t) mu(2) + d1*cos(t)*sin(phi) + d2*sin(t)*cos(phi);
tvals = linspace(0,2*pi,100);

xepts = arrayfun(xe,tvals);
yepts = arrayfun(ye,tvals);

if(draw == 1)
    h = plot(xepts, yepts, linespec,'Color', drawcolor, 'LineWidth', 2);
end
if(vectors == 1)
    quiver(mu(1), mu(2), d1*V(1,1), d1*V(2,1), 0,'Color',[0.5 0.5 0.5],'LineWidth',1);
    quiver(mu(1), mu(2), d2*V(1,2), d2*V(2,2), 0,'Color',[0.5 0.5 0.5],'LineWidth',1);
end

if(exist('label','var'))
    text(mu(1),mu(2),label);
end

xlabel('x 100 um');
ylabel('x 100 um');

