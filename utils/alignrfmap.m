function alignrfmap(rfs,rfoffset)
% Align receptive field maps from successive recordings with translation offset

% drag and drop code adapted from interactive_move by:
% J.P. Rueff, Aout 2004, modified Juin 2005
% http://www.mathworks.com/matlabcentral/fileexchange/5751-click-n-drag-plot

nrf = length(rfs);

if(~exist('rfoffset', 'var')) % default to 0 offset
    rfoffset = zeros(nrf,2);
end

% progresively dim the receptive fields by chaning the second arg
colormults = linspace(1,1, nrf);
% color map listing and names
[~, cnames] = segevcmap(); 

% replace all shape==0 with shape=50 to be able to show/hide it
for i = 1:nrf
    for ci = 1:length(rfs{i}.shape)
        if(rfs{i}.shape(ci) == 0)
            rfs{i}.shape(ci) = 50;
        end
    end
end

figure(99), clf, hold on;
figh = gcf;
axh = gca;
defaultTitle = 'Receptive Field Map Manual Alignment';

% initialize handles struct for callback handlers
handles = guidata(gca);
handles.macro_active=0; % currently in a drag?
handles.key=''; % current key pressed (for x or y constraining of drag)
handles.mapnum = 0; % currently dragging map id?
handles.newoffset = [ 0 0 ]; % new offset refers to the delta for this down/drag/up event
handles.totaloffset = []; % the new value to update the rfoffset row with after the drag
handles.currentTitle = defaultTitle;
handles.mapVisible = ones(nrf,1); % boolean visibility table for rfs
handles.colorVisible = ones(length(cnames),1); % color visibility table a la segevcmap
handles.init_state = uisuspend(figh);
handles.drawMode = 'allmaps'; % showing all maps (rather than merged cells)
handles.rfhand = [];
handles.rfmergehand = [];
handles.pairEdgeVisible = 0;
handles.pairEdgeHand = [];
guidata(gca,handles);
clear handles;

[checkmaph checkcolorh] = initGui();
figureResizeFcn();
drawAllMaps(0); % draw all the maps and save the handles
updateVisibility();

% globals for merged maps
rfmerge = [];
assignunique = {};
foundinmap = []; % how many of map j's cells are assigned to unique cell i
shapeunique = [];

showColor(50, 0); % hide color 50: unclassified
return;


%% initialize GUI and draw controls
function [checkmaph checkcolorh] = initGui()
    handles = guidata(axh);
    movegui(figh, 'center');
    set(figh,'Name','Receptive Field Map Alignment');
    set(figh,'NumberTitle','off');
    set(figh,'MenuBar','none');
    title(handles.currentTitle);
    % position the axes and add some controls
    set(figh,'Toolbar','none');
    figback = get(gcf,'Color');
    axis manual;

    % positions for uicontrols will be handled by figureResizeFcn

    % show maps label
    uicontrol('Style', 'text', 'String', 'Show Maps:', 'Tag', 'lblShowMaps', ...
        'BackgroundColor', figback, 'FontWeight', 'bold');
    % show maps checkboxes
    checkmaph = zeros(nrf,1); % checkbox handles for show maps
    for j = 1:nrf
        checkmaph(j) = uicontrol('Style', 'checkbox', 'String', rfs{j}.name, ...
            'Tag', sprintf('m%d',j), 'Callback', @showMapCheckboxCallback);
        set(checkmaph(j), 'Value', get(checkmaph(j),'Max')); 
    end

    % show colors label
    uicontrol('Style', 'text', 'String', 'Show Classes:','Tag', 'lblShowColors', ...
        'BackgroundColor', figback, 'FontWeight', 'bold');
    % show colors checkboxes
    checkcolorh = zeros(length(cnames),1); % checkbox handles for show maps
    for j = 1:length(cnames)
        if(isempty(cnames{j})) % skip unused entries
            continue;
        end
        checkcolorh(j) = uicontrol('Style', 'checkbox', 'String', cnames{j}, ...
            'Tag', sprintf('c%d',j), 'Callback', @showColorCheckboxCallback);
        set(checkcolorh(j), 'Value', get(checkcolorh(j),'Max')); 
    end

    % Alignment labels
    uicontrol('Style', 'text', 'String', 'Alignment:', 'Tag', 'lblAlignment', ...
        'BackgroundColor', figback, 'FontWeight', 'bold');
    uicontrol('Style', 'pushbutton', 'String', 'Auto Coarse', ...
        'Tag', 'btnAutoCoarse', 'Callback', @autoCoarseClick);
    uicontrol('Style', 'togglebutton', 'String', 'Merge Registered Cells', ...
        'Tag', 'btnMergeCells', 'Callback', @toggleMergeCells);

    % Pairwise Simultaneity
    uicontrol('Style', 'text', 'String', 'Pairwise:', 'Tag', 'lblPairwise', ...
        'BackgroundColor', figback, 'FontWeight', 'bold');
    uicontrol('Style', 'pushbutton', 'String', 'Pairwise Simultaneity',...
        'Tag', 'btnPairwise', 'Callback', @pairwiseSimul);
    uicontrol('Style', 'togglebutton', 'String', 'Adjacency Simultaneity', ...
        'Tag', 'btnAdjacency', 'Callback', @adjacentSimul);
    
    set(gcf, 'ResizeFcn', @figureResizeFcn);
    
    % Axis Mouse Events
    set(figh, 'windowbuttondownfcn', {@onAxesClick,1});
    set(figh, 'windowbuttonmotionfcn', {@onAxesClick,2});
    set(figh, 'windowbuttonupfcn', {@onAxesClick,3});
    set(figh, 'keypressfcn', {@onAxesClick,4});
end

%% handle plot drag and drop event for aligning maps
function onAxesClick(~,~,type)
    handles=guidata(axh);
    rfhand = handles.rfhand;
    switch type
        case 1 %---Button down
            % ignore if already dragging or in merged map mode
            if(handles.macro_active)
                return;
            end
            handles.macro_active = 1;
            set(figh,'Pointer','crosshair'); 
            
            out=get(axh,'CurrentPoint');
            set(axh,'NextPlot','replace')
                  
            handles.xpos0=out(1,1);%--store initial position x
            handles.ypos0=out(1,2);%--store initial position y
            xl=get(axh,'XLim');yl=get(axh,'YLim');
            
            if(~strcmp(handles.drawMode,'allmaps'))
                % if not in drag mode, then we're always dragging the
                % whole plot
                handles.mapnum = 0;
                guidata(axh,handles);
                return;
            end
            
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
            end   
            guidata(axh,handles);
        case 2%---Button Move
            if(handles.macro_active)
                out=get(axh,'CurrentPoint');
                set(figh,'Pointer','fullcrosshair');
                
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
                    xl=get(axh,'XLim');yl=get(axh,'YLim');
                    set(axh, 'XLim', xl-handles.newoffset(1));
                    set(axh, 'YLim', yl-handles.newoffset(2));
                end

                guidata(axh,handles)
            end

        case 3 %----Button up (cleanup some variable)
            if(handles.macro_active)
                set(figh,'Pointer','arrow');
                set(axh,'NextPlot','add')
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
                guidata(axh,handles)
            end

        case 4 %----Button press
            handles.key=get(figh,'CurrentCharacter');
            guidata(axh,handles)
    end
    
    guidata(axh,handles);
end
    
%% determine closest map to cursor and dash selected rf map traces
function [mapnum, mapxData, mapyData]=map_select(pos)
    % access handles through parent onAxesClick function
    rfhand = handles.rfhand;
    %-define searching windows
    xl=get(axh,'XLim');
    xwin=abs(xl(1)-xl(2))/100;
    yl=get(axh,'YLim');
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
        set(checkmaph(j), 'Position', pos);
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
    
    pos(2) = pos(2) - 3*uiydelta;
    
    % alignment positioning
    set(findobj('Tag', 'lblAlignment'), 'Position', pos);
    
    pos(2) = pos(2) - 2*uiydelta;
    pos(4) = 1.5*uiydelta;
    set(findobj('Tag', 'btnAutoCoarse'), 'Position', pos);
    
    pos(2) = pos(2) - 2*uiydelta;   
    set(findobj('Tag', 'btnMergeCells'), 'Position', pos);
    
    pos(4) = uiydelta;
    pos(2) = pos(2) - 2*uiydelta;
    
    % Pairwise Simultaneity
    set(findobj('Tag','lblPairwise'), 'Position', pos);
    
    pos(2) = pos(2) - 2*uiydelta;
    pos(4) = 1.5*uiydelta;
    set(findobj('Tag', 'btnPairwise'), 'Position', pos);
    
    pos(2) = pos(2) - 2*uiydelta;
    set(findobj('Tag', 'btnAdjacency'), 'Position', pos);

    pos(4) = uiydelta;
    
    % restore original units
    set(figh, 'Units', old_units);
    set(axh, 'Units', old_ax_units);
end

%% show/hide specific maps by number
function showMapCheckboxCallback(hObject, ~, ~)
    handles = guidata(axh);
    tag = get(hObject, 'Tag');
    mapnum = str2num(tag(2:end)); % tag should be 'm#' 
    if (get(hObject,'Value') == get(hObject,'Max')) % checked?
        handles.mapVisible(mapnum) = 1;
    else
        handles.mapVisible(mapnum) = 0;
    end
    guidata(axh, handles);
    
    updateVisibility();
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
    handles = guidata(axh);
    if(vis)
        handles.colorVisible(cid) = 1;
        checkvalset = 'Max';
    else
        handles.colorVisible(cid) = 0;
        checkvalset = 'Min';
    end
    
    % update the checkbox too, in case not called from callback
    hobj = findobj('Tag', sprintf('c%d', cid));
    set(hobj, 'Value', get(hobj, checkvalset));
    
    guidata(axh, handles);
    updateVisibility();
end

%% autoalignment
function autoCoarseClick(~, ~, ~)
    handles = guidata(axh);
    rfhand = handles.rfhand;
    set(figh, 'Pointer', 'watch');
    title('Coarse Auto Alignment...');
    drawnow
    autooffsets = autoaligncoarse(rfs, rfoffset);
    deltaoffsets = autooffsets - rfoffset;
    for mapi = 1:nrf
        for j = 1:length(rfhand{mapi}) % loop over cells
            if(~isnan(rfhand{mapi}(j)))
                % move this trace in the plot
                xdata = get(rfhand{mapi}(j),'XData') + deltaoffsets(mapi,1);
                ydata = get(rfhand{mapi}(j),'YData') + deltaoffsets(mapi,2);
                set(rfhand{mapi}(j),'XData',xdata); %-move x trace
                set(rfhand{mapi}(j),'YData',ydata);%-move y trace
                % and update the mapxData & mapyData
            end
        end
    end
    rfoffset = autooffsets;
    title('Performed Coarse Auto Alignment');
    set(figh,'Pointer','arrow');
end

%% rf map merging
function toggleMergeCells(hobj,~,~)
    set(figh, 'Pointer', 'watch');
    handles = guidata(axh);
    state = get(hobj, 'Value') == get(hobj, 'Max');
    if(state)
        title('Merging Maps...');
        drawnow
    
        [rfunique shapeunique assignunique foundinmap] = mergemaps(rfs,rfoffset);
       
        rfmerge = [];
        rfmerge.shape = shapeunique;
        rfmerge.Parameters = rfunique;
    
        drawMerged();
        title(handles.currentTitle);
        
        handles.drawMode = 'merged';
    else
        handles.currentTitle = defaultTitle;
        title(handles.currentTitle);
%         drawAllMaps();
        handles.drawMode = 'allmaps';
    end
    
    guidata(axh,handles);
    updateVisibility();
    set(figh, 'Pointer', 'arrow');
end

function drawMerged()
    xl = get(axh,'XLim'); yl = get(axh, 'YLim');
    handles = guidata(axh);
    handles.rfmergehand = plotrfmap(rfmerge, 'fignum',figh);
    handles.uniqueVisible = ones(length(handles.rfmergehand),1);
    guidata(axh, handles);
    
    xlim(xl); ylim(yl);
end

function drawAllMaps(keepaxes)
    if(~exist('keepaxes','var'))
        keepaxes = 1;
    end
    if(keepaxes)
        xl = get(axh,'XLim'); yl = get(axh, 'YLim');
    end
    handles = guidata(axh);
    if(keepaxes)
        xlim(xl); ylim(yl);
        axis manual;
    else
        axis auto;
    end
    handles.drawMode = 'allmaps';
    handles.rfhand = cell(nrf,1);
    for mi = 1:nrf
        handles.rfhand{mi} = plotrfmap(rfs{mi}, ...
            'fignum',figh, 'colormult',colormults(mi), 'offset', rfoffset(mi,:));
    end
    axis manual
    
    guidata(axh,handles);
end

%% utility to hide/show appropriate ellipses based on color/map checkboxes
function updateVisibility()
    % loop over every trace and decide whether to make it visible based on
    % map visiblity and color visibility. all maps vs. merged mode aware.]
    handles = guidata(axh);
    
    % handle all maps displayed
    rfhand = handles.rfhand;
    for mapi = 1:nrf
        for j = 1:length(rfhand{mapi})
            if(isnan(rfhand{mapi}(j))) % never displayed anyway
                continue;
            end

            visible = 'on';
            if(~strcmp(handles.drawMode, 'allmaps')) % not in this mode
                visible = 'off';
            end
            if(~handles.mapVisible(mapi))  % is the map hidden
                visible = 'off';
            end
            if(~handles.colorVisible(rfs{mapi}.shape(j))) % color hidden?
                visible = 'off';
            end

            set(rfhand{mapi}(j), 'Visible', visible);
        end
    end      

    % handle single merged map
    rfmergehand = handles.rfmergehand;
    for j = 1:length(rfmergehand)
        visible = 'on';

        % hide based on mode;
        if(~strcmp(handles.drawMode, 'merged'))
            visible = 'off';
        end
        
        % hide based on color?
        if(~handles.colorVisible(rfmerge.shape(j)))
            visible = 'off';
        end

        % hide if it is not found in any visible map
        inVisibleMap = 0;
        for mi = 1:nrf
            if(~handles.mapVisible(mi))
                continue;
            end
            if(foundinmap(j,mi))
                inVisibleMap = 1;
                break;
            end
        end
        if(~inVisibleMap)
            visible = 'off';
        end

        set(rfmergehand(j), 'Visible', visible);
        handles.uniqueVisible(j) = strcmp(visible, 'on');
    end
    
    % handle adjacency Pair edges
    if( handles.pairEdgeVisible)
        visible = 'on';
    else
        visible = 'off';
    end
    for ei = 1:length(handles.pairEdgeHand)
        set(handles.pairEdgeHand(ei), 'Visible', visible);
    end
    
    if(strcmp(handles.drawMode, 'merged'))
        handles.currentTitle = sprintf('Merged Maps: %d / %d Unique Cells',...
            nnz(handles.uniqueVisible), size(rfmerge.Parameters,1));
        title(handles.currentTitle);
    end
    guidata(axh,handles);
end

%% pairwise/adjacency simultaneity
function pairwiseSimul(~,~,~)
    handles = guidata(axh);
    % filter uniques by those shown currently
    selshapeunique = shapeunique(logical(handles.uniqueVisible));
    selfoundinmap = foundinmap(logical(handles.uniqueVisible),logical(handles.mapVisible));
    cellinds = 1:length(shapeunique);
    cellinds = cellinds(logical(handles.uniqueVisible));
    newfig = figure();
    pairwise = pairwiseSimultaneity(selshapeunique, selfoundinmap, cellinds, newfig );
end

function adjacentSimul(hobj, ~, ~)
    handles = guidata(axh);
    state = get(hobj, 'Value') == get(hobj, 'Max');
    if(state)
        % filter uniques by those shown currently
        selrfunique = rfmerge.Parameters(logical(handles.uniqueVisible),:);
        selfoundinmap = foundinmap(logical(handles.uniqueVisible),logical(handles.mapVisible));
        
        [pairEdge pairEdgeSimul edgeHands] = adjacencySimultaneity( selrfunique, ...
            'foundinmap', selfoundinmap, 'linewidth', 2, 'grouptype', 'pair', 'axh', axh);
        
        handles.pairEdgeHand = edgeHands;
        handles.pairEdgeVisible = 1;
    else
        handles.pairEdgeVisible = 0;
    end
    
    guidata(axh, handles);
    updateVisibility();
end

end