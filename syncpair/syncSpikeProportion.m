function [caInPair cbInPair] = syncSpikeProportion(ca,cb,varargin)

def.twind = [-0.06 0.06];
def.fignum = 0;
assignargs(def,varargin);

% want to compute relative proportion of spikes of each realtive 

nwind = size(twind,1);
cwind = flipud(copper(nwind+1));
cwind = cwind(1:nwind,:);

times = generateSyncTimesPair(ca, cb, fignum, twind, cwind, 'nearest');

% how many spikes from ca are in a pair

caInPair = zeros(length(ca),1); % check list for whether each spike was in a pair
cbInPair = zeros(length(cb),1);

for wi = 1:nwind
    for si = 1:length(times{wi,1})
        caInPair(find(ca == times{wi,1}(si))) = 1;
    end
    for si = 1:length(times{wi,2})
        cbInPair(find(cb == times{wi,2}(si))) = 1;
    end
end

% caPropInPair = sum(caInPair)/length(ca);
% cbPropInPair = sum(cbInPair)/length(cb);