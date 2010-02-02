function alignrfmap(rfs)
% Align receptive field maps from successive recordings with translation
% offset

nrf = length(rfs);
rfoffset = zeros(nrf,2);
colormults = linspace(1,1, nrf);
figure(1), clf, hold on;
rfhand = cell(nrf,1);

for i = 1:nrf
    % replace all shape==0 with shape=50 to be able to show/hide it
    for ci = 1:length(rfs{i}.shape)
        if(rfs{i}.shape(ci) == 0)
            rfs{i}.shape(ci) = 50;
        end
    end
    
    % then plot all the ellipses and save the handles
    rfhand{i} = plotrfmap(rfs{i}, 1, colormults(i));
end

% position the axes and add some controls
title('Receptive Field Map Manual Alignment');
set(gcf,'Toolbar','none');
figh = gcf;
axh = gca;

% positions for uicontrols will be handled by figureResizeFcn

% show maps label
uicontrol('Style', 'text', 'String', 'Show Maps:','Tag', 'lblShowMaps');
% show maps checkboxes
checkh = zeros(nrf,1); % checkbox handles for show maps
for i = 1:nrf
    checkh(i) = uicontrol('Style', 'checkbox', 'String', rfs{i}.name, ...
        'Tag', sprintf('m%d',i), 'Callback', @showMapCheckboxCallback);
    set(checkh(i), 'Value', get(checkh(i),'Max')); 
end

% show colors label
uicontrol('Style', 'text', 'String', 'Show Classes:','Tag', 'lblShowColors');
% show colors checkboxes
[~, cnames] = segevcmap();
checkcolorh = zeros(length(cnames),1); % checkbox handles for show maps
for i = 1:length(cnames)
    if(isempty(cnames{i})) % skip unused entries
        continue;
    end
    checkcolorh(i) = uicontrol('Style', 'checkbox', 'String', cnames{i}, ...
        'Tag', sprintf('c%d',i), 'Callback', @showColorCheckboxCallback);
    set(checkcolorh(i), 'Value', get(checkcolorh(i),'Max')); 
end

figureResizeFcn();
set(gcf, 'ResizeFcn', @figureResizeFcn);

% drag and drop code adapted from interactive_move by:
% J.P. Rueff, Aout 2004, modified Juin 2005
% http://www.mathworks.com/matlabcentral/fileexchange/5751-click-n-drag-plot

handles = guidata(gca);
handles.macro_active=0;
%handles.lineObj = findobj(gca, 'Type', 'line');
handles.lineObj=[findobj(gca, 'Type', 'line');findobj(gca, 'Type', 'patch')];
handles.key='';
handles.mapnum = 0;
handles.newoffset = [ 0 0 ]; % new offset refers to the delta for this down/drag/up event
handles.totaloffset = []; % the new value to update the rfoffset row with after the drag
guidata(gca,handles);
handles.currentTitle = get(get(gca, 'Title'), 'String');

handles.mapVisible = ones(nrf,1);
handles.colorVisible = ones(length(cnames),1);
handles.init_state = uisuspend(gcf);
guidata(gca,handles);

showColor(50, 0); % hide color 50: unclassified

set(gcf, 'windowbuttondownfcn', {@onclick,1});
set(gcf, 'windowbuttonmotionfcn', {@onclick,2});
set(gcf, 'windowbuttonupfcn', {@onclick,3});
axis manual;
set(gcf, 'keypressfcn', {@onclick,4});

%  uirestore(handles.init_state);
 
%% handle plot drag and drop event for aligning maps
function onclick(~,~,type)

    handles=guidata(gca);

    switch type
        case 1 %---Button down
            if(handles.macro_active)
                return;
            end
            handles.macro_active=1;
            out=get(gca,'CurrentPoint');
            set(gca,'NextPlot','replace')
            set(gcf,'Pointer','crosshair');       
            handles.xpos0=out(1,1);%--store initial position x
            handles.ypos0=out(1,2);%--store initial position y
            xl=get(gca,'XLim');yl=get(gca,'YLim');
            % within plot bounds?
            if ((handles.xpos0 > xl(1) && handles.xpos0 < xl(2)) && (handles.ypos0 > yl(1) && handles.ypos0 < yl(2)))
                % which map was selected?
                [handles.mapnum, handles.mapxData, handles.mapyData]=map_select([out(1,1) out(1,2)]);
                
                % within a drag, store the original coords in origmap?data
                % and the current coords in origmap?data
                handles.origmapxData = handles.mapxData;
                handles.origmapyData = handles.mapyData;
                
                if handles.mapnum~=0 %--if curve found
                    handles.newoffset = [0 0];
                    handles.totaloffset = handles.newoffset + rfoffset(handles.mapnum,:);
                    title(sprintf('Moving Map %s: Offset [%.2f, %.2f]',...
                        rfs{handles.mapnum}.name, rfoffset(handles.mapnum,1), rfoffset(handles.mapnum,2)));
                else
                    % moving whole plot --> change limits
                    title(handles.currentTitle);
                end
                guidata(gca,handles);
            else
                % clicked outside plot bounds, ignore
            end    
        case 2%---Button Move
            if(handles.macro_active)
                out=get(gca,'CurrentPoint');
                set(gcf,'Pointer','fullcrosshair');
                
                % calculate new offset but display total offset in title
                % bar
                handles.newoffset = [out(1,1)-handles.xpos0, out(1,2)-handles.ypos0];
                
                if handles.mapnum~=0
                    switch handles.key
                        case ''%--if no key pressed
                            
                        case 'x'%--if x pressed
                            handles.newoffset(2) = 0; % set y offset to 0
                           
                        case 'y'%--if y pressed
                            handles.newoffset(1) = 0; % set x offset to 0
                           
                    end

                    handles.totaloffset = handles.newoffset + rfoffset(handles.mapnum,:);
                    title(sprintf('Moving Map %s: Offset [%.2f, %.2f]',...
                        rfs{handles.mapnum}.name, handles.totaloffset(1),handles.totaloffset(2)));
                
                    for j = 1:length(rfhand{handles.mapnum})
                        if(~isnan(rfhand{handles.mapnum}(j)))
                            % move this trace in the plot
                            set(rfhand{handles.mapnum}(j),'XData',handles.origmapxData{j}+handles.newoffset(1));%-move x trace
                            set(rfhand{handles.mapnum}(j),'YData',handles.origmapyData{j}+handles.newoffset(2));%-move y trace
                            % and update the mapxData & mapyData
                            handles.mapxData{j} = handles.origmapxData{j}+handles.newoffset(1); %-update x data
                            handles.mapyData{j} = handles.origmapyData{j}+handles.newoffset(2); %-update y data
                        end
                    end
                              
                else % moving the whole plot
                    xl=get(gca,'XLim');yl=get(gca,'YLim');
                    set(gca, 'XLim', xl-handles.newoffset(1));
                    set(gca, 'YLim', yl-handles.newoffset(2));
                end

                guidata(gca,handles)
            end

        case 3 %----Button up (cleanup some variable)
            if(handles.macro_active)
                set(gcf,'Pointer','arrow');
                set(gca,'NextPlot','add')
                if handles.mapnum~=0
                    for j = 1:length(rfhand{handles.mapnum})
                        if(~isnan(rfhand{handles.mapnum}(j)))
                            set(rfhand{handles.mapnum}(j),'LineStyle','-');
                        end
                    end
                    % update the rfoffset array
                    totaloffset = handles.newoffset + rfoffset(handles.mapnum,:);
                    rfoffset(handles.mapnum,:) = totaloffset;
                    title(sprintf('Moved Map %s: Offset [%.2f, %.2f]',...
                        rfs{handles.mapnum}.name, totaloffset(1),totaloffset(2)));
                else
                    title(handles.currentTitle);
                end
                
                handles.key='';
                handles.macro_active=0;
                guidata(gca,handles)
            end

        case 4 %----Button press
            handles.key=get(gcf,'CurrentCharacter');
            guidata(gca,handles)
    end
end
    
%% determine closest map to cursor and dash selected rf map traces
function [mapnum, mapxData, mapyData]=map_select(pos)

    %-define searching windows
    xl=get(gca,'XLim');
    xwin=abs(xl(1)-xl(2))/100;
    yl=get(gca,'YLim');
    ywin=abs(yl(1)-yl(2))/100;

    mindist = zeros(nrf,1);
    xData = cell(nrf,1);
    yData = cell(nrf,1);
    for map = 1:nrf
        % this is caught by the inner is it visible check, 
        % but saves time by doing it once for whole map
        if(handles.mapVisible(map)) 
            hands = rfhand{map};
            %-load all datasets
            dist = zeros(length(hands),1);
            xData{map} = cell(length(hands),1);
            yData{map} = cell(length(hands),1);
            for j=1:length(hands)
                % is this a valid trace and is it visible?
                if(~isnan(hands(j)))
                    % calculate distance to each point in each line in this map
                    % even if its not visible
                    xData{map}{j}=get(hands(j), 'XData');
                    yData{map}{j}=get(hands(j), 'YData');
                    if(strcmp(get(hands(j), 'Visible'),'on'))
                        % if its visible find the distance
                        dist(j) = sqrt(min((pos(1,2)-yData{map}{j}).^2 + (pos(1,1)-xData{map}{j}).^2));
                    else
                        dist(j) = Inf;
                    end
                else
                    % ignore it
                    dist(j) = Inf;
                end
            end
            % and pick the minimum for this map
            mindist(map) = min(dist);
        else
            mindist(map) = Inf; % this map is hidden
        end
    end

    % find the closest map
    [minmapdist, mapnum] = min(mindist);

    if(minmapdist > min(xwin, ywin)) % too far away from all maps
        mapnum = 0;
        mapxData = [];
        mapyData = [];
    else
        mapxData = xData{mapnum};
        mapyData = yData{mapnum};
        for k = 1:length(rfhand{mapnum})
           if(~isnan(rfhand{mapnum}(k)))
               set(rfhand{mapnum}(k), 'LineStyle', ':');
           end
        end
    end
end

%% position all the uicontrols initially and on resize
function figureResizeFcn(~, ~, ~)
    old_units = get(figh,'Units');
    set(figh,'Units','pixels');
    old_ax_units = get(axh, 'Units');
    set(axh, 'Units', 'pixels');
    pos = get(figh,'Position');
    
    margin = 25;
    uixmargin = 10;
    uixwidth = 150;
    uiydelta = 15;
    uixstart = pos(3) - uixwidth - margin;
    uiystart = pos(4) - margin - uiydelta;
    
    set(axh, 'Position', [ margin margin pos(3)-2*margin-uixwidth-uixmargin pos(4)-2*margin]);
    pos = [uixstart uiystart uixwidth uiydelta];
    
    % show map checkbox positioning
    set(findobj('Tag', 'lblShowMaps'),'Position', pos);
    for j = 1:nrf
        pos(2) = pos(2) - uiydelta;
        set(checkh(j), 'Position', pos);
    end
    
    pos(2) = pos(2) - 2*uiydelta;
    
    % show color checkbox positioning
    set(findobj('Tag', 'lblShowColors'), 'Position', pos);
    for j = 1:length(cnames)
        if(~isempty(cnames{j}))
            pos(2) = pos(2) - uiydelta;
            set(checkcolorh(j), 'Position', pos);
        end
    end

    set(gcf, 'Units', old_units);
    set(axh, 'Units', old_ax_units);
end

%% show/hide specific maps by number
function showMapCheckboxCallback(hObject, ~, ~)
    tag = get(hObject, 'Tag');
    mapnum = str2num(tag(2:end)); % tag should be 'm#' 
    if (get(hObject,'Value') == get(hObject,'Max')) % checked?
        visible = 'on';
        handles.mapVisible(mapnum) = 1;
    else
        visible = 'off';
        handles.mapVisible(mapnum) = 0;
    end
   
    for k = 1:length(rfhand{mapnum})
        % is this a valid trace? are we hiding it or showing one that is not a currently hidden color?
       if(~isnan(rfhand{mapnum}(k)) && ...
               (~handles.mapVisible(mapnum) || handles.colorVisible(rfs{mapnum}.shape(k))))
           set(rfhand{mapnum}(k), 'Visible', visible);
       end
    end
    
    guidata(gca, handles);
end

%% show/hide specific colors (callback function for checkboxes)
function showColorCheckboxCallback(hObject, ~, ~)
    tag = get(hObject, 'Tag'); % tag should be 'c#'
    cid = str2num(tag(2:end));
    if (get(hObject,'Value') == get(hObject,'Max')) % checked?
        vis = 1;
    else
        vis = 0;
    end
    showColor(cid, vis);
end

function showColor(cid, vis)
    handles = guidata(gca);
    if(vis)
        visible = 'on';
        handles.colorVisible(cid) = 1;
        checkvalset = 'Max';
    else
        visible = 'off';
        handles.colorVisible(cid) = 0;
        checkvalset = 'Min';
    end
    
    % update the checkbox too, in case not called from callback
    hobj = findobj('Tag', sprintf('c%d', cid));
    set(hobj, 'Value', get(hobj, checkvalset));
   
    for mapi = 1:nrf
        for j = 1:length(rfhand{mapi})
            % is it a valid trace and is it the current color?
            if(~isnan(rfhand{mapi}(j)) && rfs{mapi}.shape(j) == cid)
                set(rfhand{mapi}(j), 'Visible', visible);
            end
        end
    end
    
    guidata(gca, handles);
end

end