% function pinkjitter()
try
    
AssertOpenGL;

% Main Parameters
Debug = 1; % display focus points and other visual aids?
Duration = 1600; % total time in seconds
FixationTime = 1; % time between saccades (s)
SaccadeTime = 0.07; % time spend on saccade
maxJitterRadius = 15; % bounds of random walk before microsaccade back to center
jitterVariance = 3; % size of each random walk step (variance of normal dist)
ResizeFactor = 1; % supersampling of pink noise image?
Seed = 0; % for random number generators
Contrast = 2; % of pink noise on top of gray background

% Initialize Window
scn=0; % choose screen number
w=Screen('OpenWindow',scn); 
[xsize ysize]=Screen('WindowSize', w);
ifi=Screen('GetFlipInterval',w);


% total number of saccades
nSaccades = floor(Duration/FixationTime); 
% number of frames spent during saccade
saccadeFrames = floor(SaccadeTime/ifi);
% number of frames per fixation, including saccade
fixationFrames = floor(FixationTime/ifi); 
TotalFrames = Duration / ifi;

% define some colors
black=BlackIndex(w);
white=WhiteIndex(w);
red = [white 0 0]';
green = [0 white 0]';
blue = [0 0 white];
purple = [white 0 white]';
yellow = [white white 0]';
cyan = [0 white white]';
MeanIntensity=((black+white+1)/2)-1;

% utility function to shift rect(s) by offset vector(s)
fnRectOffset = @(rect,offx,offy) [rect(1,:)+offx; rect(2,:)+offy; ...
                                  rect(3,:)+offx; rect(4,:)+offy];

% initialize parallel random number generators
[rndFocusX rndFocusY rndFocusChoose rndJitter] = ...
    RandStream.create('mrg32k3a','NumStreams',4,'Seed',Seed);

% center of screen in screen coordinates
screencx = floor(xsize/2);
screency = floor(ysize/2);

focusSx = 600; % width of permitted focus locations rect
focusSy = 600; % height of permitted focus locations rect

screenRect = [0 0 xsize ysize]';
% image centered/cropped on screen in image coordinates
imgRectCenter = fnRectOffset(screenRect,focusSx/2,focusSy/2);

% size of image
imgSx = xsize+focusSx;
imgSy = ysize+focusSy;
% center of image in image coordinates
imgcx = floor(imgSx/2);
imgcy = floor(imgSy/2);

% create pink noise image 
I = pinkframe(imgSx,imgSy,Seed,0,ResizeFactor); % px in range [0,1]
pinkimg = (I-0.5)*(white-black)*Contrast + MeanIntensity;
pinkimg(pinkimg < black) = black;
pinkimg(pinkimg > white) = white;

% create texture for pink noise image
txr = Screen('MakeTexture', w, pinkimg);

% choose focus locations
nFoci = 16;
% x,y locations for ith (row) focus in image coordinates
fociLoc = round([(rand(rndFocusX,nFoci,1)-0.5)*focusSx + imgSx/2, ...
                 (rand(rndFocusY,nFoci,1)-0.5)*focusSy + imgSy/2]);
% rects for marking each focus in debug mode
fociIndicatorRect = [fociLoc(:,1)-3 fociLoc(:,2)-3 ...
                     fociLoc(:,1)+3 fociLoc(:,2)+3]';

% photodiode oval in upper right corner
photodiode=ones(4,1);
photodiode(1,:)=xsize/10*9;
photodiode(2,:)=ysize/10*1;
photodiode(3,:)=xsize/10*9+80;
photodiode(4,:)=ysize/10*1+80;

% fill screen with gray background
Screen('FillRect', w, MeanIntensity);
% show photodiode black
Screen('FillOval',w, black, photodiode);
vbl = Screen('Flip',w);

% pause for keypress, if space wait for recording signal
% KbWait;
[~,~, c]=KbCheck;
YorN=find(c);
if YorN==KbName('space')
    WaitForRec;
end
HideCursor;
Priority(MaxPriority(w));

% randomly choose a start point for the first saccade
currentfocus = ceil(nFoci*rand(rndFocusChoose,1));

for si = 1:nSaccades
    for fnum = 1:fixationFrames    
        if(fnum == 1) % first frame this fixation, choose a new target
            lastfocus = currentfocus;
            currentfocus = ceil(nFoci*rand(rndFocusChoose,1));
        end
            
        if(fnum <= saccadeFrames)
            % just started or currently doing saccade
            oldx = fociLoc(lastfocus,1) - screencx;
            oldy = fociLoc(lastfocus,2) - screency;
            newx = fociLoc(currentfocus,1) - screencx;
            newy = fociLoc(currentfocus,2) - screency;
            
            % smoothly interpolate the offsets on each frame
            offx = oldx + fnum/saccadeFrames*(newx-oldx);
            offy = oldy + fnum/saccadeFrames*(newy-oldy);
        else
            % currently jittering around fixation point  
            jumpvec = round(randn(rndJitter,1,2)*jitterVariance);
            offx = offx + jumpvec(1);
            offy = offy + jumpvec(2);
            
            % if we hit the circular boundary, microsaccade back to center
            if((offx-newx)^2 + (offy-newy)^2 > maxJitterRadius^2)
                offx = newx;
                offy = newy;
            end
        end

        % draw pink noise image at the right offset
        txrsrc = fnRectOffset(screenRect,offx,offy);
        Screen('DrawTexture',w,txr,txrsrc,screenRect);

        if(Debug)
            % valid focus locations
    %         validFocusRect = [imgcx-focusSx/2 imgcy-focusSy/2 imgcx+focusSx/2 imgcy+focusSy/2]';
    %         Screen('FillRect',w,[blue 0.1]',fnRectOffset(validFocusRect,-offx,-offy));

            % show focus locations, offset appropriately
            fociColors = repmat([0 white 0]',1,nFoci);
            fociDots = fnRectOffset(fociIndicatorRect,-offx,-offy);
            Screen('FillOval',w,fociColors,fociDots);

            % show old and new focus in purple and yellow
            Screen('FillOval',w,purple,fociDots(:,lastfocus));
            Screen('FillOval',w,yellow,fociDots(:,currentfocus));

            % draw screen center in cyan
            centerRect = [screencx-3 screency-3 screencx+3 screency+3]';
            Screen('FillOval',w,cyan,centerRect);

            % draw image corner boxes in red
%             cornerRects = fnRectOffset(repmat([0 0 focusSx focusSy]',1,4), ...
%                 [0 imgSx-focusSx 0 imgSx-focusSx], [0 0 imgSy-focusSy imgSy-focusSy]);
%             Screen('FillRect',w,repmat(red,1,4),fnRectOffset(cornerRects,-offx,-offy));
        end
        
        % set photodiode color appropriately
        if(fnum == 1)
            photodiodeColor = white; % start of saccade
        elseif(fnum <= saccadeFrames)
            photodiodeColor = black; % during saccade
        else
             % high gray, low gray alternating during jitter
            photodiodeColor = mod(fnum,2)*MeanIntensity/2+MeanIntensity;           
        end   
        Screen('FillOval',w,photodiodeColor,photodiode);
%         vbl = Screen('Flip',w, vbl+ifi+0.001);
        
        vbl = Screen('Flip',w);
        
        if KbCheck % check for keypress abort
            sca;
            return;
        end
    end
end

Screen('CloseAll');

catch exception
    Screen('CloseAll');
    ShowCursor
    disp(exception.identifier)
    for i = 1:length(exception.stack)
        disp(exception.stack(i));
    end
    
end

sca