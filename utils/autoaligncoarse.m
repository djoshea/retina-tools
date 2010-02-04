function [newoffsets] = autoaligncoarse(rfs, offsets)
% register cells in a series of receptive field maps
% by looking successively at pairs of maps

nrf = length(rfs);
if(~exist('offsets', 'var'))
    offsets = zeros(nrf, 2);
end

newoffsets = zeros(nrf,2);

for i = 1:nrf-1
   rfa = rfs{i}; % anchor
   rfm = rfs{i+1}; % moving
   initoffset = offsets(i+1,:) - offsets(i,:); % vector from moving to anchor
   
   newoffsets(i+1,:) = calcrfoffset(rfa, rfm,initoffset) + newoffsets(i,:);
end

end