function [ rfunique shapeunique assign foundinmap Nassigned ] = mergemaps( rfs, offset )
% using the alignment offset(s), create a list of unique cells that points
% back to cells in the original RF maps
% rfunique is a matrix in the format of the Parameters array, one row for
%   each cell, each column a parameter (z A x0 xw y0 yw cor)
% assign is a cell array, one array for each map, in which each value
%   indicates which row in rfunique each cell in that map is equivalent to
%   e.g. assign{m}(j) == c indicates that map m cell j is the same as cell c

nrf = length(rfs);
assign = cell(nrf,1);
rfunique = []; % average RF params for each unique cell
shapeunique = []; % shape of each unique cell
foundinmap = []; % counts number of cells from map j assigned as unique cell i

[~, cnames] = segevcmap(); 

for si = 1:length(cnames) % do one color at a time for grouping purposes
    if(isempty(cnames{si}))
        continue;
    end
    
    for mi = 1:nrf % loop over 
        for ci = 1:length(rfs{mi}.Parameters)
            if(rfs{mi}.shape(ci) ~= si) % only the current color/shape id
                continue;
            end
            
            % shift Parameters x0 and y0 by offset for this map
            prow = rfs{mi}.Parameters(ci,:);
            prow(3) = prow(3) + offset(mi,1);
            prow(5) = prow(5) + offset(mi,2);
            
            match = cellmatch(prow, rfs{mi}.shape(ci), rfunique, shapeunique);
            if(match)
                % assign this cell to rfunique row match
                assign{mi}(ci) = match;
                % and update the average RF params in rfunique(match,:)
                %            rfunique(match,:) = (rfunique(match,:)*Nassigned(match) ...
                %                + prow)/(Nassigned(match)+1);
                % increment the counter
                foundinmap(match,mi) = foundinmap(match,mi) + 1;
            else
                % add as new cell to rfunique
                rfunique(end+1,:) = prow;
                shapeunique(end+1,:) = rfs{mi}.shape(ci);
                assign{mi}(ci) = size(rfunique,1);
                foundinmap(end+1,:) = zeros(1,nrf);
                foundinmap(end,mi) = 1;
            end
        end
    end
end

function match = cellmatch(p, shape, plist, shapelist)
    % determines best match for cell with params p and shape against
    % cells with params plist and shape list shapelist
    if(size(plist,1) == 0)
        match = 0;
        return;
    end
    % return boolean value indicating whether cells are equivalent
    shapematch = shapelist == shape;
    mudist = sqrt((p(3) - plist(:,3)).^2 + (p(5) - plist(:,5)).^2);
    xwdelta = abs(p(4) - plist(:,4));
    ywdelta = abs(p(6) - plist(:,6));
    cordelta = abs(p(7) - plist(:,7));
    
    % consider assignments that satisfy these thresholds
    distthresh = 0.5;
    deltathresh = 0.4;
    corthresh = 0.2;
    valid = (shapematch & mudist < distthresh & xwdelta < deltathresh & ...
             ywdelta < deltathresh & cordelta < corthresh);
         
    if(nnz(valid))
        % return closest match
        [~, match] = min(mudist.^2 + xwdelta.^2 + ywdelta.^2 +cordelta.^2);
    else
        % or none at all
        match = 0;
    end
end

end

