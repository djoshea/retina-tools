function [ out ] = igorread( fname )
% IGORREAD reads multi-block floating point Igor Pro data
% out = igorread(fname)
% reads fname expecting blocks with a text header line and a table of data
% assigns values into out struct as a matrix (for a single label) or
% individual vectors (for multiple labels in the header line)
%
% Within Igor, export as General Text, select variables, and check include
% wave names and column names

names = {};
fid = fopen(fname);
if(fid == -1)
    error('Could not open file "%s"', fname);
end
out = [];

while(1)
    % get the variable or column names in the names field
    nameline = fgetl(fid);
    if(~ischar(nameline))
        break;
    end
    C = textscan(nameline, '%s');
    namelist = C{1};
    
    % read in data table
    dat = [];
    while(1)
        line = fgetl(fid);
        if(line == -1) % watch for EOF
            break;
        end
        if(strcmp(strtrim(line),'')) % skip blank lines
            continue;
        end
            
        line = strrep(line, 'NAN', 'NaN'); % igor outputs NAN
        [vals count] = sscanf(line, '%f');
        
        if(count == 0) % hit label of next block
            fseek(fid, -length(line)-1, 0); % rewind one line
            break;
        end
        
        dat(size(dat,1)+1, :) = vals;
    end
    
    if(isempty(dat))
        continue; % skip empty waves
    end
    
    % decide whether to assign as one data table or individual named vectors  
    if(length(namelist) > 1)
        for j = 1:length(namelist)
            out.(namelist{j}) = dat(:,j);
        end
    else
        out.(namelist{1}) = dat;
    end
    
end

fclose(fid);

