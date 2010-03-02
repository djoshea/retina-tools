% generate the list of times for synchronous interactions between each pair
% of cells, within a set of relative timing windows
% also, if computedParams exists, load in the fitted RF params for each

rf = rfs{3};
ncells = size(rf.Parameters,1);

twind = [ -0.06 -0.04;
          -0.04 -0.02;
          -0.02  0.0;
           0.00  0.02;
           0.02  0.04;
           0.04  0.06; ];
nwind = size(twind,1);
cwind = flipud(copper(nwind+1));
cwind = cwind(1:nwind,:);
      
count = 0;
totalcount = ncells*(ncells+1) * nwind; % total number of cell pairs * 2 * nwindows

outstruct = struct();

pairMapTimes = cell(ncells, ncells, nwind, 2);
pairMapParams = cell(ncells, ncells, nwind, 2);
pairMapTWind = twind;

waitstr = @(cai, cbi, cnt) sprintf('%6.1f %%%% Complete: Pair %2d v %2d\t', 100*cnt/totalcount, cai, cbi);
% hwait = waitbar(0,'...','CreateCancelBtn','setappdata(gcbf,''canceling'',1); delete(gcbf);');
    
for cai = 1:ncells
    ca = rf.(['c' num2str(cai)]);
    for cbi = cai:ncells
        cb = rf.(['c' num2str(cbi)]);
        str = waitstr(cai,cbi,count);
        fprintf(str);
        %         waitbar(count/totalcount, hwait, waitstr(cai,cbi,count));
        % Check for Cancel button press
%         if getappdata(hwait,'canceling')
%             return;
%         end
        
        times = generateSyncTimesPair(ca, cb, 0, twind, cwind, 'nearest');
        
        spcount = 0;
        for w = 1:nwind
            count = count+1;
            spcount = spcount + length(times{w,1});
            pairMapTimes{cai, cbi, w, 1} = times{w,1};
            pairMapCindex{cai,cbi, w, 1} = count;
            outstruct.(['c' num2str(count)]) = times{w,1};
            
            if(exist('computedParams','var'))
                pairMapParams{cai, cbi, w, 1} = computedParams(count,:);
            end
            
            count = count+1;
            pairMapTimes{cai, cbi, w, 2} = times{w,2};
            pairMapCindex{cai,cbi, w, 2} = count;
            outstruct.(['c' num2str(count)]) = times{w,2};
            
            if(exist('computedParams','var'))
                pairMapParams{cai, cbi, w, 2} = computedParams(count,:);
            end
        end
        
        fprintf('%4d spikes\n', spcount);
    end
end

rf.pairMapParams = pairMapParams;
rf.pairMapWindTimes = twind;
rf.pairMapWindCmap = cwind;

% delete(hwait);