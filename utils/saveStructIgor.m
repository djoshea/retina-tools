function  h = saveStructIgor( fname, s )
% SAVESTRUCTIGOR(fname, s) Saves fields of s into file fname
% File fname can be loaded into Igor using the command "LoadWave/G/D/W/N/O"

flds = fieldnames(s);
width = 20;
fprintf('Writing to %s: [%s]', fname, repmat(' ', 1, width));

h = fopen(fname,'w+');
for i = 1:length(flds)
    % progress bar update
    nw = floor(i/length(flds)*width);
    if(nw  > floor((i-1)/length(flds) * width))
        fprintf([ repmat('\b',1,width+1) ...
                  repmat('=',1,nw) ...
                  repmat(' ',1,width-nw) ']']);
    end
    
    % write name to file
    
    fprintf(h,'%s\n', flds{i});
    % write values to file
    v = s.(flds{i});
    fmatstr = [repmat('%f',1,size(v,2)) '\n'];
    for r = 1:size(v,1);
        fprintf(h,fmatstr, v(r,:));
    end
    fprintf(h,'\n');
           
end

fclose(h);
fprintf('\n');
