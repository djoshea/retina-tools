function [ list listSimul hands ] = adjacencySimultaneity( rfunique, foundinmap, grouptype, axh)
% edge is Nx2 list of nearest neighbors, edgeSimul is how many times that
% pair was recorded simultaneously
% tri is Nx3 list of nearest triplets (Delaunay triangulation simplices),
% triSimul is how many times that 

if(~exist('axh', 'var'))
    axh = 0;
end
if(~exist('grouptype', 'var'))
    grouptype = 'pair';
end

x0 = rfunique(:,3);
y0 = rfunique(:,5);

dt = DelaunayTri(x0,y0);
edge = edges(dt);
tri = dt.Triangulation;

% calculate 2-way and 3-way simultaneity lookup matrices
nrf = size(foundinmap,2);
nunique = size(foundinmap,1);
pairinmap = zeros(nunique,nunique,nrf); % both i,j in map k?
triinmap = zeros(nunique,nunique,nunique,nrf); % i,j,k in map l?
for mi = 1:nrf
    pwise = foundinmap(:,mi) * foundinmap(:,mi)';
    pairinmap(:,:,mi) = pwise;
    triinmap(:,:,:,mi) = reshape(pwise(:) * foundinmap(:,mi)', ...
        nunique, nunique, nunique);
end
pairwise = sum(pairinmap,3);
triwise = sum(triinmap,4);

% calculate which edges touch cells that were simultaneously recorded
edgeSimul = zeros(size(edge,1),1);
for ei = 1:size(edge,1)
    edgeSimul(ei) = pairwise(edge(ei,1), edge(ei,2));
end

% filter edges by distance maximum
distmax = 3;
edgedists = sqrt( (x0(edge(:,1))-x0(edge(:,2))).^2 + ...
                  (y0(edge(:,1))-y0(edge(:,2))).^2 );
edgeValid = edgedists <= distmax;

% calculate which triangles touch cells that were all simultaneously
% recorded

triSimul = zeros(size(tri, 1), 1);
for ti = 1:size(tri, 1)
     triSimul(ti) = triwise(tri(ti,1), tri(ti,2), tri(ti,3));
end

hands = [];
if(axh)
    if(strcmp(grouptype, 'pair'))
        for ei = 1:size(edge,1)
            if(~edgeValid(ei))
                continue
            end
            if(edgeSimul(ei) > 0)
                col = [ 0 0 0 ];
                spec = '-';
            else
                col = [ 0.4 0.4 0.4 ];
                spec = '--';
            end
            hands(end+1) = plot(axh, [ x0(edge(ei,1)) x0(edge(ei,2)) ], ...
                                     [ y0(edge(ei,1)) y0(edge(ei,2)) ], ...
                                spec, 'Color', col, 'LineWidth', 2);
        end
    end
end

% filter before returning
list = edge(edgeValid,:);
listSimul = edgeSimul(edgeValid);

end

