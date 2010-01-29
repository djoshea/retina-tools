#pragma rtGlobals=1		// Use modern global access method.

// A couple things have to be done before running calcAllRF("c*_1")
// 1. Load 10 secs of photodiode recording
// 2. Extract from the photodiode recording START_T and change it in the constants section below
// 3. Make sure that Steve's "LN model" and "Spatio-temporal LN model" procedures are available.
// 4. Now you can run calcAllRF()
//		It will prompt you for 4 things:
// 		1st:		the directory where the cell files are
//		2nd: 	the cell file with the RF data
//		3rd. 	the binary file containing the random sequence of 1s/0s from Matlab.
//		4th		the directory where you want to save the RF
//	   There is no need to run macro MakeGlobals_FileTransfer in advance
//      There is no need to Load Cell data in advance

// A couple things have to be done in order to run photodiodeRF()
// 1 Load 10secs of photodiode recording, and extract START_T
// 2 Change all teh constants defined below.
// 3. Make sure that Steve's "LN model" and "Spatio-temporal LN model" procedures are available.
// PhotodiodeRF() is going to prompt for 2 filess:
// 		File1:		matlab sequences of 1/0
// 		File2:		photodiode recording.
// *****************************  User define constants ***********************************// 

constant START_T = 3.287
// BOX_PIX is in pixels and FRAMESN is the total number of frames in the stimuli, 48000 for 1600 secs @ 30Hz
constant BOX_PIX = 17, FRAMESN = 48000, FRAMEPERIOD = 0.0333462
constant HORIZONTAL_PX=1024, VERTICAL_PX = 768
//constant HORIZONTAL_PX=700, VERTICAL_PX = 700
constant THRESHOLD = 11;
constant SHOW_SCALE=400

// *****************************  User define constants ***********************************// 



function calcAllRF()
	string cell_wildcard = "c*"					// tipically of the form "c*"
	string cell, list, cmd
	variable i=0	
	NVAR myPath
	
	Init4MapRF()
	

	// Get the list of waves according to cell_ID
	list=wavelist(cell_wildcard,";","")

	do
		cell =StringFromList(i, list, ";")
		if ( stringmatch(cell,"*_recs") )
			continue;
		endif

		if (strlen(cell))
			RemoveDelay2($cell)
			CalcRFfn(rand0, $cell, -0.5, 0, .01)
			save /P=myPath $cell+"_rf" as cell+"_rf"
			killwaves $cell, $cell+"_rf"
		else
			break
		endif
		i += 1;
	while (1)

//	clean()
end


//function loadRF(printflag)
	variable printflag				// if printflag prints

//	string cell_wildcard="c*"				// tipically of the form "c*"
	make /o bestLayers={25,25,27,24,25,25,26,25,25,25,25,18,25,25,24,25,0,24,025}

	// Get the rfPath
	string rfPath, message="Folder where the RF files are located"
	NewPath/Q/O/M=message rfPath

	// Get the list of waves in the specified folder
	string cell, folderList, cmd
	folderList = IndexedFile(rfPath, -1, "????")
	folderList = listMatch(folderList, "*_rf")
	folderList = sortList(folderList, ";", 16)
	variable i=1, itemsN
 	itemsN = itemsInList(folderList)	

	// make the display
	if (printflag)
		makegraphtile("RF", ceil(sqrt(itemsN)), ceil(sqrt(itemsN)), 0)
	endif
	
	// load the RFs	
	for (i=0; i< itemsN; i+=1)
		cell = stringFromList(i, folderList)
		LoadWave /o /P=rfPath cell
		if (waveExists(bestLayers))
			make /o/n=(dimsize($cell, 0), dimsize($cell,1)) $cell+"_thr"
			wave threshW = $cell+"_thr", rfW = $cell
			threshW = rfW[p][q][bestLayers[i]]
		else
			threshrf($cell, 4, -.125, -.025)
			duplicate /o rf_thr $cell+"_thr"
		endif
		string thresholded=cell+"_thr"
		if (printflag)
			drawObject($thresholded)
			sprintf cmd, "appendimage /w=RF#G%d %s",i, thresholded
			execute cmd 
//			ModifyGraph width=200,height=200
		endif		
	endfor
	scalesubw("RF", "left", (VERTICAL_PX + SHOW_SCALE)/2, (VERTICAL_PX - SHOW_SCALE)/2)
	scalesubw("RF", "bottom", (HORIZONTAL_PX - SHOW_SCALE)/2, (HORIZONTAL_PX + SHOW_SCALE)/2)
	dosubw("RF", "ModifyGraph /w=? /z height={Plan,1,left,bottom}")

end

function DeleteWaves(cell_wildcard)
	string cell_wildcard				// tipically of the form "c*_1"
	NVAR startT, endT, period				// start and end points of the stimuli

	// Get the list of waves according to cell_ID
	string cell, list
	variable i=0
	
	list=wavelist(cell_wildcard,";","")
	print list
	do
		cell =StringFromList(i, list, ";")
		if (strlen(cell))
			killwaves $cell
		else
			break
		endif
		i += 1;
	while (1)
end

function RemoveDelay2(cell)
	wave cell
	cell -= START_T;
end

function killallwindows4MapRF(selection)
// this function is identical to the one under general.ipf but was copied here so that general.ipf does not have to be transferred with MapRF.ipf
// to every machine
// kills all the windows of a certain type.
// selection: 1 graphs
// selection: 2 tables
// selection: 4 layouts
// selection: 16 Notebooks
// selection: 64 Panels
// selection: 128 Procedure windows
// selection: 4096 XOP target windows

	variable selection
	
	string list, element, cmd
	variable i=0
	
	list = WinList("*", ";","WIN:"+num2str(selection))
	do
		element = StringFromList(i, list, ";")
		if (strlen(element))
		 	sprintf cmd, "killwindow %s", element
		 	print cmd
		 	execute cmd
		 	i +=1
		else
	break
		endif
	while (1)
end

function Init4MapRF()
	clean()
		
	execute "MakeGlobals_FileTransfer()"
	execute "LoadCellFile(\"\",\"\",1,2,\"\",1,\"include all\",\"include all\")"
	
	// delete cell_list and *_recs
	DeleteWaves("*_recs")
	DeleteWaves("cell_list")

	// load the random sequence of 1/0 generated by matlab.
	loadStim()

	// Get the path to store the cell_rf files
	string /G myPath
	string  message="Choose a folder to store the RF files"
	NewPath/Q/O/M=message myPath
end

function 	clean()
	killallwindows4MapRF(7)
	killwaves /a
	killstrings /a
	killvariables /a
	
end


// In order to reconstruct the RF with the photodiode 1st change all the values
// in the constants below and run PhotodiodeRF(), it will kill everything, if you don't want this
// to happen comment out the "killeverything()" line.
// If it doesn't work, look at wave e0_1 and make sure the threshold is such that only a few
// crossings are met.

function PhotodiodeRF()
	clean()
	execute("MakeGlobals_FileTransfer()")

	// load the random sequence of 1/0 generated by matlab.
	GBLoadWave/O/N=rand/T={8,72}/W=1 ""

	variable rows = ceil(1024/BOX_PIX), cols = ceil(768/BOX_PIX)

	setscale /p z,0,framePeriod, rand0
	Redimension /n=(rows, cols, framesN) rand0
	setscale /p z,0,framePeriod, rand0

	// Check that you are getting the right stimuli.
	 display /w=(0,0,500,500) /k=1
	appendimage rand0
	SetAxis left (rows-0.5),-.05

	// load photodiode
	execute("LoadRecord64CW(2,620,1000,3,\"stim\",\"Y\")")
	// duplicate photodiode into c0_1
	duplicate /o stim_V c0_1

	// Get rid of photodiode before start of stimuli
	c0_1[]=c0_1[p+x2pnt(c0_1, start_t)]


	// convert the photodiode recording into a sequence of 1/0 corresponding to times where the
	// photodiode saw high intensity (higher than threshold). There might be more than one 
	// monitor frame per stimuli frame and If using findlevels directly on
	// row data there is a chance the 1st frame does not cross threshold and the 2nd one does. This
	// will screw things later on. Therefore smooth data first.
	duplicate /o c0_1, d0_1
	smooth /b 16, d0_1
	duplicate d0_1, e0_1
	findlevels /D=e0_1 /edge=1 d0_1, threshold

	// calculate the RF map for the photodiode
	calcRFfn(rand0, e0_1, -0.5,0, framePeriod)

	//Display an image
	threshrf(e0_1_rf,10,-.04,0)
	display /k=1/w=(0,0,500,500); appendimage rf_thr
//	ModifyImage rf_thr ctab= {*,*,Grays16,0}
	SetAxis left (ROWS-0.5),-0.5
end


function LoadStim()

	variable rows = ceil(HORIZONTAL_PX/BOX_PIX), cols = ceil(VERTICAL_PX/BOX_PIX)
	
	// load the random sequence of 1/0 generated by matlab.
	GBLoadWave/O/N=rand/T={8,72}/W=1 ""
	Redimension /n=(rows, cols, framesN) rand0
	setscale /p z, 0, FRAMEPERIOD, rand0
end

function RFWeights(rf, st,sp)
//Function RFWeights
// Given a RF, and the spikes and random stimuli used to generate the spikes
// correlate  the RF with the stimuli preceeding the spikes to see how similar
// they are.
// Output: weights, a wave containing as many coordinates as spikes where each
// coordinate corresponds to the weight between the given spike and the RF.

// rf: wave containing the RF
// st:Wave containing white noise stimulus
// sp:Wave containing spike train
// tstart:Start time of receptive field relative to a spike

	wave rf, st, sp

	
	//Wave to hold the weights
	make /o/n=(dimsize(sp,0)) weights=nan

	// sp is a 1D wave with the times of each spike
	// rf is a 3D wave where first 2 dimension are a given frame and the 3rd dimension is time
	// st is a 3D wave where first 2 dimension are a given frame and the 3rd dimension is time
	//
	//				 dimdelta(rf, 2) might be different from dimdelta(st,2)
	//	 In general the RF is going to have resolution at least as good as st in time (meaning that
	// 	dimdelta(rf, 2) <= dimdelta(st, 2)
	//
	// For every time in sp I want to extract the 3D wave from st that has the last frame at the
	// time of the spike. That matrix should be the same dimension as the rf, then compute a dot
	// product between them and store it in weight[i]
	
	variable rfTimeLength = dimsize(rf, 2)*dimdelta(rf,2)
	variable startT=dimoffset(rf, 2)
	variable endT = dimoffset(rf, 2) + dimsize(rf, 2) * dimdelta(rf,2)
	variable i, j,k,l, temp2 = 0
	
	// make the corresponding waves to accomodate one frame of rf and st
	make /o/n=(dimsize(rf, 0), dimsize(rf, 1)) rf_frame, st_frame

	for (i=0; i<numpnts(sp); i+=1)							// for every spike
		for (j = startT; j<endT; j+=dimdelta(rf, 2))			// for every time in the rf
			rf_frame = rf[p][q](j)				// frame of RF corresponding to time j (@ t= 0 the spike takes place)
			st_frame = st[p][q](sp[i]+j)		// frame of stimulus corresponding to time j with respect to the spike.
														// st and sp are not in the same time scale. They are shifted with respect
														// to each other in START_T. st time = 0 equals sp time = START_T.
			MatrixOp /o temp = sum(rf_frame * st_frame)
			temp2 += temp[0]
		endfor
		weights[i] = temp2
		temp2 = 0
	endfor
end

function selectSpikesFromWeights(sp, weights)
	// divide the spikes into BINS according to their weights.
	// output is same name as sp +"_bin#"
	wave sp, weights
	
	string nameout, basename = nameofwave(sp) + "_set"
	variable i, lower, upper, step

	// Order the spikes according to the their weights but do not use the original SP wave
	// but a duplicate
	duplicate /o sp, temp
	sort weights, weights, temp
	variable BINS = 2, pnts = numpnts(temp)	
	for (i=0;i< BINS; i+=1)
		nameout = basename + num2str(i)
		make /o/n=(ceil(pnts/BINS))  $nameout
		wave wout = $nameout
		wout = temp[i*ceil(pnts/BINS)+p]
//		lower = i*step + V_min-1
//		upper = (i+1)*step + V_min
//		wout = selectnumber (lower < weights[p] && weights[p] < upper, nan, sp[p])
//		removenans(wout)
	endfor
end

function DrawObject(rf)
	// rf is the thresholded rf, a 2D wave


	// if using my MapRF, the 700x700 (or whatever you use) is centered on the screen. therefore the top left corner is at
	// ( (1024-700)/2 , (768-700)/2 ) = (162, 34) from the upper-left corner of the monitor
	// If you mapped the RF with the labs MapRF but the experiment (and the object) is done with the 700x700 screen, then
	// use HORIZONTAL_PX=1024, VERITCAL_PX = 768 and 
	// Corner of Object in Monitor = Corner of OBject in 700x700 box + Corner of 700x700 box in monitor.
	// Corner of Object in Monitor = Corner of OBject in 700x700 box + (162, 34)
	// 
	// object center is (x, y) from 700x700 box's top-left corner
	// object center from monitor is (x+162, y+34)
	// object dimensions are (L1, L2)
	// object coordinates are:
	// left = x-L1/2
	// right = x+L1/2
	// top = y - L2/2
	// bottom = y + L2/2
	wave rf
	variable x = 330, y = 280

	// if Using the lab's MapRF uncomment the line below
	x += 162; y += 34

	variable L1 = 50, L2 = 50
	variable left = x-L1/2, right = x+L1/2, top = y - L2/2, bottom = y + L2/2

	// rescale the rf_thr to have same number of pixels as in the displayed monitor
	make /n=(HORIZONTAL_PX, VERTICAL_PX) newRF
	variable i, j
	for (i=0; i<HORIZONTAL_PX/BOX_PIX; i+=1)
		for (j=0; j< VERTICAL_PX/BOX_PIX; j+=1)
			newRF[i*BOX_PIX, (i+1)*BOX_PIX-1][j*BOX_PIX, (j+1)*BOX_PIX-1] = rf[i][j]
		endfor
	endfor

	wavestats /Q rf
	newrf[left,right][top]=V_min/2
	newrf[left][top,bottom]=V_min/2
	
	newrf[left,right][bottom]=V_min/2
	newrf[right][top,bottom]=V_min/2
	
	duplicate /o newRF, rf
	killwaves newRF
end
