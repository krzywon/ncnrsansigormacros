#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.22

// vers 7.13d

// TODO:
//
// -- Need to make sure that the rescaledTime and the differentiated time graphs are
//     being properly updated when the data is processed, modified, etc.
//
// -- I need better nomenclature other than "stream" for the "continuous" data set.
//     It's all a stream, just sometimes it's not oscillatory
//
// -- fix the log/lin display - it's not working correctly
// 			I could use ModifyImage and log = 0|1 keyword for the log Z display
// 			rather than creating a duplicate wave of log(data)
// 			-- it's in the Function sliceSelectEvent_Proc()
//
// -- Do something withe the PP events. Currently, nothing is done (since I still need
//     to find out what they realy mean)
//
// -- Add a switch to allow Sorting of the Stream data to remove the "time-reversed" data
//     points. Maybe not kosher, but would clean things up.
//
// -- Is there any way to improve the speed of the loader? How could an XOP be structured
//     for maximum flexibility? Leave the post processing to Igor, but how much for the XOP
//     to do? And can it handle such large amounts of data to pass back and forth, or
//     does it need to be written as an operation, rather than a function??? I'd really 
//     rather that Igor handles the memory management, not me, if I write the XOP.
//
// X- add controls to show the bar graph
// x- add popup for selecting the binning type
// x- add ability to save the slices to RAW VAX files
// X- add control to show the bin counts and bin end times
// x- ADD buttons, switches, etc for the oscillatory mode - so that this can be accessed
//
// x- How are the headers filled for the VAX files from Teabag???
// -- I currently read the events 2x. Once to count the events to make the waves the proper
//     size, then a second time to actualy process the events. Would it be faster to insert points
//     as needed, or to estimate the size, and make it too large, then trim at the end...
// ((( NO -- deleting the extra zeros at the end is WAY WAY slower - turns 2sec into 100 sec)))
//
//
//


//
// These are currently defined in the TISANE procedure file. If that file becomes depricated
// or is not loaded in, then these lines should be activated, and those in TISANE should also
// be re-declared as Static, so they will be local to each procedure
//
//Static Constant ATXY = 0
//Static Constant ATXYM = 2
//Static Constant ATMIR = 1
//Static Constant ATMAR = 3
//
//Static Constant USECSPERTICK=0.1 // microseconds
//Static Constant TICKSPERUSEC=10
//Static Constant XBINS=128
//Static Constant YBINS=128
//



Proc Show_Event_Panel()
	DoWindow/F EventModePanel
	if(V_flag ==0)
		Init_Event()
		EventModePanel()
	EndIf
End


Function Init_Event()
	String/G 	root:Packages:NIST:gEvent_logfile
	String/G 	root:Packages:NIST:gEventDisplayString="Details of the file load"
	
	Variable/G 	root:Packages:NIST:AIMTYPE_XY=0 // XY Event
	Variable/G 	root:Packages:NIST:AIMTYPE_XYM=2 // XY Minor event
	Variable/G 	root:Packages:NIST:AIMTYPE_MIR=1 // Minor rollover event
	Variable/G 	root:Packages:NIST:AIMTYPE_MAR=3 // Major rollover event

	Variable/G root:Packages:NIST:gEvent_time_msw = 0
	Variable/G root:Packages:NIST:gEvent_time_lsw = 0
	Variable/G root:Packages:NIST:gEvent_t_longest = 0

	Variable/G root:Packages:NIST:gEvent_tsdisp //Displayed slice
	Variable/G root:Packages:NIST:gEvent_nslices = 10  //Number of time slices
	
	Variable/G root:Packages:NIST:gEvent_logint = 1

	Variable/G root:Packages:NIST:gEvent_Mode = 0				// ==0 for "stream", ==1 for Oscillatory
	Variable/G root:Packages:NIST:gRemoveBadEvents = 1		// ==1 to remove "bad" events, ==0 to read "as-is"
	Variable/G root:Packages:NIST:gSortStreamEvents = 0		// ==1 to sort the event stream, a last resort for a stream of data
	
	NVAR nslices = root:Packages:NIST:gEvent_nslices
	
	SetDataFolder root:
	NewDataFolder/O/S root:Packages:NIST:Event
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
	Duplicate/O slicedData logslicedData
	Duplicate/O slicedData dispsliceData
	
	SetDataFolder root:
End

Proc EventModePanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(100,50,600,840)/N=EventModePanel/K=2
	DoWindow/C EventModePanel
	ModifyPanel fixedSize=1,noEdit =1
	//ShowTools/A
	SetDrawLayer UserBack
	Button button0,pos={10,10}, size={150,20},title="Load Event Log File",fSize=12
	Button button0,proc=LoadEventLog_Button
	
	TitleBox tb1,pos={20,650},size={460,80},fSize=12
	TitleBox tb1,variable=root:Packages:NIST:gEventDisplayString
	
	CheckBox chkbox1,pos={170,8},title="Oscillatory Mode?"
	CheckBox chkbox1,variable = root:Packages:NIST:gEvent_mode
	CheckBox chkbox3,pos={170,27},title="Remove Bad Events?"
	CheckBox chkbox3,variable = root:Packages:NIST:gRemoveBadEvents
	
	Button doneButton,pos={435,12}, size={50,20},title="Done",fSize=12
	Button doneButton,proc=EventDone_Proc

	Button button2,pos={20,122},size={140,20},proc=ShowEventDataButtonProc,title="Show Event Data"
	Button button3,pos={20,147},size={140,20},proc=ShowBinDetailsButtonProc,title="Show Bin Details"
	Button button4,pos={175,122},size={140,20},proc=UndoTimeSortButtonProc,title="Undo Time Sort"
	Button button5,pos={175,147},size={140,20},proc=ExportSlicesButtonProc,title="Export Slices as VAX"
	Button button6,pos={378,13},size={40,20},proc=EventModeHelpButtonProc,title="?"
	
	//DrawLine 10,35,490,35
	Button button1,pos = {10,50}, size={150,20},title="Process Data",fSize=12
	Button button1,proc=ProcessEventLog_Button
	SetVariable setvar1,pos={170,50},size={160,20},title="Number of slices",fSize=12
	SetVariable setvar1,value=root:Packages:NIST:gEvent_nslices
	SetVariable setvar2,pos={330,50},size={160,20},title="Max Time (s)",fSize=12
	SetVariable setvar2,value=root:Packages:NIST:gEvent_t_longest
	//DrawLine 10,65,490,65
	
//	PopupMenu popup0 title="Bin Spacing",pos={150,90},value="Equal;Fibonacci;Log;"
	PopupMenu popup0 title="Bin Spacing",pos={150,90},value="Equal;Fibonacci;"
	
	CheckBox chkbox2,pos={20,95},title="Log Intensity",value=1
	CheckBox chkbox2,variable=root:Packages:NIST:gEvent_logint,proc=LogIntEvent_Proc
	SetVariable setvar0,pos={320,90},size={160,20},title="Display Time Slice",fSize=12
	SetVariable setvar0,value= root:Packages:NIST:gEvent_tsdisp
	SetVariable setvar0,proc=sliceSelectEvent_Proc
	Display/W=(20,180,480,640)/HOST=EventModePanel/N=Event_slicegraph
	AppendImage/W=EventModePanel#Event_slicegraph/T root:Packages:NIST:Event:dispsliceData
	ModifyImage/W=EventModePanel#Event_slicegraph  ''#0 ctab= {*,*,ColdWarm,0}
	ModifyImage/W=EventModePanel#Event_slicegraph ''#0 ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetAxis/A left
	SetActiveSubwindow ##
EndMacro

Function ShowEventDataButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ShowRescaledTimeGraph()"
			//
			DifferentiatedTime()
			//
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ShowBinDetailsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ShowBinTable()"
			Execute "BinEventBarGraph()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function UndoTimeSortButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "UndoTheSorting()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ExportSlicesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "ExportSlicesAsVAX()"		//will invoke the dialog
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EventModeHelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0,"The help file has not been written yet"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function EventDone_Proc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win
	switch (ba.eventCode)
		case 2:
			DoWindow/K EventModePanel
			break
	endswitch
	return(0)
End



Function ProcessEventLog_Button(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR mode=root:Packages:NIST:gEvent_Mode
	
	if(mode == 0)
		Stream_ProcessEventLog("")
	endif
	
	if(mode == 1)
		Osc_ProcessEventLog("")
	endif
	
	
	return(0)
end

// for oscillatory mode
//
Function Osc_ProcessEventLog(ctrlName)
	String ctrlName

	Make/O/D/N=(128,128) root:Packages:NIST:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:Event:binnedData
	Wave xLoc = root:Packages:NIST:Event:xLoc
	Wave yLoc = root:Packages:NIST:Event:yLoc

// now with the number of slices and max time, process the events


	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:gEvent_nslices

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Wave timePt = timePt
	Make/O/D/N=(128,128) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount
	Wave binEndTime = binEndTime
	Wave binCount = binCount

	variable ii,del,p1,p2,t1,t2
	del = t_longest/nslices

	slicedData = 0
	binEndTime[0]=0
	BinCount[nslices]=0


	String binTypeStr=""
	ControlInfo /W=EventModePanel popup0
	binTypeStr = S_value
	
	strswitch(binTypeStr)	// string switch
		case "Equal":		// execute if case matches expression
			SetLinearBins(binEndTime,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			SetFibonacciBins(binEndTime,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			SetLogBins(binEndTime,nslices,t_longest)
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			SetLinearBins(binEndTime,nslices,t_longest)
	endswitch


// now before binning, sort the data

	//this is slow - undoing the sorting and starting over, but if you don't,
	// you'll never be able to undo the sort
	//
	SetDataFolder root:Packages:NIST:Event:

	if(WaveExists($"root:Packages:NIST:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
		MakeIndex rescaledTime OscSortIndex
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
		//SetDataFolder root:Packages:NIST:Event
		IndexForHistogram(xLoc,yLoc,binnedData)			// index the events AFTER sorting
		//SetDataFolder root:
	Endif
	
	Wave index = root:Packages:NIST:Event:SavedIndex		//this is the histogram index

	for(ii=0;ii<nslices;ii+=1)
		if(ii==0)
//			t1 = ii*del
//			t2 = (ii+1)*del
			p1 = BinarySearch(rescaledTime,0)
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1])
		else
//			t2 = (ii+1)*del
			p1 = p2+1		//one more than the old one
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1]) 		
		endif

	// typically zero will never be a valid time value in oscillatory mode. in "stream" mode, the first is normalized to == 0
	// but not here - times are what they are.
		if(p1 == -1)
			Printf "p1 = -1 Binary search off the end %15.10g <?? %15.10g\r", 0, rescaledTime[0]
			p1 = 0		//set to the first point if it's off the end
		Endif
		
		if(p2 == -2)
			Printf "p2 = -2 Binary search off the end %15.10g >?? %15.10g\r", binEndTime[ii+1], rescaledTime[numpnts(rescaledTime)-1]
			p2 = numpnts(rescaledTime)-1		//set to the last point if it's off the end
		Endif
		Print p1,p2


		tmpData=0
		JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
		slicedData[][][ii] = tmpData[p][q]
		
//		binEndTime[ii+1] = t2
		binCount[ii] = sum(tmpData,-inf,inf)
	endfor

	Duplicate/O slicedData,root:Packages:NIST:Event:dispsliceData,root:Packages:NIST:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:Event:logSlicedData
	logslicedData = log(slicedData)

	SetDataFolder root:
	return(0)
End

// for a "continuous exposure"
//
// if there is a sort of these events, I need to re-index the events for the histogram
// - see the oscillatory mode  - and sort the events here, then immediately re-index for the histogram
// - but with the added complication that I need to always remember to index for the histogram, every time
// - since I don't know if I've sorted or un-sorted. Osc mode always forces a re-sort and a re-index
//
Function Stream_ProcessEventLog(ctrlName)
	String ctrlName

//	NVAR slicewidth = root:Packages:NIST:gTISANE_slicewidth

	
	Make/O/D/N=(128,128) root:Packages:NIST:Event:binnedData
	
	Wave binnedData = root:Packages:NIST:Event:binnedData
	Wave xLoc = root:Packages:NIST:Event:xLoc
	Wave yLoc = root:Packages:NIST:Event:yLoc

// now with the number of slices and max time, process the events

	NVAR yesSortStream = root:Packages:NIST:gSortStreamEvents		//do I sort the events?
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	NVAR nslices = root:Packages:NIST:gEvent_nslices

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	
	Make/D/O/N=(XBINS,YBINS,nslices) slicedData
		
	Wave slicedData = slicedData
	Wave rescaledTime = rescaledTime
	Make/O/D/N=(128,128) tmpData
	Make/O/D/N=(nslices+1) binEndTime,binCount//,binStartTime
	Wave binEndTime = binEndTime
//	Wave binStartTime = binStartTime
	Wave binCount = binCount

	variable ii,del,p1,p2,t1,t2
	del = t_longest/nslices

	slicedData = 0
	binEndTime[0]=0
	BinCount[nslices]=0
	
	String binTypeStr=""
	ControlInfo /W=EventModePanel popup0
	binTypeStr = S_value
	
	strswitch(binTypeStr)	// string switch
		case "Equal":		// execute if case matches expression
			SetLinearBins(binEndTime,nslices,t_longest)
			break						// exit from switch
		case "Fibonacci":		// execute if case matches expression
			SetFibonacciBins(binEndTime,nslices,t_longest)
			break
		case "Log":		// execute if case matches expression
			SetLogBins(binEndTime,nslices,t_longest)
			break
		default:							// optional default expression executed
			DoAlert 0,"No match for bin type, Equal bins used"
			SetLinearBins(binEndTime,nslices,t_longest)
	endswitch

	if(yesSortStream == 1)
		SortTimeData()
	endif
// index the events before binning
// if there is a sort of these events, I need to re-index the events for the histogram
//	SetDataFolder root:Packages:NIST:Event
	IndexForHistogram(xLoc,yLoc,binnedData)
//	SetDataFolder root:
	Wave index = root:Packages:NIST:Event:SavedIndex		//the index for the histogram
	
	
	for(ii=0;ii<nslices;ii+=1)
		if(ii==0)
//			t1 = ii*del
//			t2 = (ii+1)*del
			p1 = BinarySearch(rescaledTime,0)
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1])
		else
//			t2 = (ii+1)*del
			p1 = p2+1		//one more than the old one
			p2 = BinarySearch(rescaledTime,binEndTime[ii+1]) 		
		endif

		if(p1 == -1)
			Printf "p1 = -1 Binary search off the end %15.10g <?? %15.10g\r", 0, rescaledTime[0]
			p1 = 0		//set to the first point if it's off the end
		Endif
		if(p2 == -2)
			Printf "p2 = -2 Binary search off the end %15.10g >?? %15.10g\r", binEndTime[ii+1], rescaledTime[numpnts(rescaledTime)-1]
			p2 = numpnts(rescaledTime)-1		//set to the last point if it's off the end
		Endif
		Print p1,p2


		tmpData=0
		JointHistogramWithRange(xLoc,yLoc,tmpData,index,p1,p2)
		slicedData[][][ii] = tmpData[p][q]
		
//		binEndTime[ii+1] = t2
		binCount[ii] = sum(tmpData,-inf,inf)
	endfor

	Duplicate/O slicedData,root:Packages:NIST:Event:dispsliceData,root:Packages:NIST:Event:logSlicedData
	Wave logSlicedData = root:Packages:NIST:Event:logSlicedData
	logslicedData = log(slicedData)

	SetDataFolder root:
	return(0)
End


Proc	UndoTheSorting()
	Osc_UndoSort()
End

// for oscillatory mode
//
// -- this takes the previously generated index, and un-sorts the data to restore to the
// "as-collected" state
//
Function Osc_UndoSort()

	SetDataFolder root:Packages:NIST:Event		//don't count on the folder remaining here
	Wave rescaledTime = rescaledTime
	Wave OscSortIndex = OscSortIndex
	Wave yLoc = yLoc
	Wave xLoc = xLoc
	Wave timePt = timePt

	Sort OscSortIndex OscSortIndex,yLoc,xLoc,timePt,rescaledTime

	KillWaves/Z OscSortIndex
	
	SetDataFolder root:
	return(0)
End



Function SortTimeData()

// now before binning, sort the data

	//this is slow - undoing the sorting and starting over, but if you don't,
	// you'll never be able to undo the sort
	//
	SetDataFolder root:Packages:NIST:Event:

	KillWaves/Z OscSortIndex
//	Print WaveExists($"root:Packages:NIST:Event:OscSortIndex")
	
	if(WaveExists($"root:Packages:NIST:Event:OscSortIndex") == 0 )
		Duplicate/O rescaledTime OscSortIndex
		MakeIndex rescaledTime OscSortIndex
		IndexSort OscSortIndex, yLoc,xLoc,timePt,rescaledTime	
	Endif
	
	SetDataFolder root:
	return(0)
End



Function SetLinearBins(binEndTime,nslices,t_longest)
	Wave binEndTime
	Variable nslices,t_longest

	Variable del,ii,t2
	binEndTime[0]=0		//so the bar graph plots right...
	del = t_longest/nslices
	
	for(ii=0;ii<nslices;ii+=1)
		t2 = (ii+1)*del
		binEndTime[ii+1] = t2
	endfor
	binEndTime[ii+1] = t_longest*(1-1e-6)		//otherwise floating point errors such that the last time point is off the end of the Binary search

	return(0)	
End


Function SetLogBins(binEndTime,nslices,t_longest)
	Wave binEndTime
	Variable nslices,t_longest

	Variable tMin,ii

	Wave rescaledTime = root:Packages:NIST:Event:rescaledTime
	
	binEndTime[0]=0		//so the bar graph plots right...

	// just like the log-scaled q-points
	tMin = rescaledTime[1]/1			//just a guess... can't use tMin=0, and rescaledTime[0] == 0 by definition
	Print rescaledTime[1], tMin
	for(ii=0;ii<nslices;ii+=1)
		binEndTime[ii+1] =alog(log(tMin) + (ii+1)*((log(t_longest)-log(tMin))/nslices))
	endfor
	binEndTime[ii+1] = t_longest		//otherwise floating point errors such that the last time point is off the end of the Binary search
	
	return(0)
End

Function MakeFibonacciWave(w,num)
	Wave w
	Variable num

	//skip the initial zero
	Variable f1,f2,ii
	f1=1
	f2=1
	w[0] = f1
	w[1] = f2
	for(ii=2;ii<num;ii+=1)
		w[ii] = f1+f2
		f1=f2
		f2=w[ii]
	endfor
		
	return(0)
end

Function SetFibonacciBins(binEndTime,nslices,t_longest)
	Wave binEndTime
	Variable nslices,t_longest

	Variable tMin,ii,total,t2,tmp
	Make/O/D/N=(nslices) fibo
	fibo=0
	MakeFibonacciWave(fibo,nslices)
	
//	Make/O/D tmpFib={1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946}

	binEndTime[0]=0		//so the bar graph plots right...
	total = sum(fibo,0,nslices-1)		//total number of "pieces"
	
	tmp=0
	for(ii=0;ii<nslices;ii+=1)
		t2 = sum(fibo,0,ii)/total*t_longest
		binEndTime[ii+1] = t2
	endfor
	binEndTime[ii+1] = t_longest		//otherwise floating point errors such that the last time point is off the end of the Binary search
	
	return(0)
End




Function LoadEventLog_Button(ctrlName) : ButtonControl
	String ctrlName

	NVAR mode=root:Packages:NIST:gEvent_mode
	
	if(mode == 0)
		Stream_LoadEventLog("")
	endif
	
	if(mode == 1)
		Osc_LoadEventLog("")
	endif

	STRUCT WMButtonAction ba
	ba.eventCode = 2
	ShowEventDataButtonProc(ba)

	return(0)
End

// for the mode of "one continuous exposure"
//
Function Stream_LoadEventLog(ctrlName)
	String ctrlName
	
	Variable fileref

	SVAR filename = root:Packages:NIST:gEvent_logfile
	NVAR nslices = root:Packages:NIST:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	
	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
	
	Open/R/D/F=fileFilters fileref
	filename = S_filename
	
	LoadEvents()
	
	SetDataFolder root:Packages:NIST:Event:

tic()
	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
	
toc()

	Duplicate/O timePt rescaledTime
	rescaledTime = 1e-7*(timePt-timePt[0])		//convert to seconds and start from zero
	t_longest = waveMax(rescaledTime)		//should be the last point

	SetDataFolder root:

	return(0)
End

// for the mode "oscillatory"
//
Function Osc_LoadEventLog(ctrlName)
	String ctrlName
	
	Variable fileref

	SVAR filename = root:Packages:NIST:gEvent_logfile
	NVAR nslices = root:Packages:NIST:gEvent_nslices
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	
	String fileFilters = "All Files:.*;Data Files (*.txt):.txt;"
	
	Open/R/D/F=fileFilters fileref
	filename = S_filename
	
	LoadEvents()
	
	SetDataFolder root:Packages:NIST:Event:

	Wave timePt=timePt
	Wave xLoc=xLoc
	Wave yLoc=yLoc
	CleanupTimes(xLoc,yLoc,timePt)		//remove zeroes
	
	Duplicate/O timePt rescaledTime
	rescaledTime *= 1e-7			//convert to seconds and that's all
	t_longest = waveMax(rescaledTime)		//if oscillatory, won't be the last point, so get it this way

	KillWaves/Z OscSortIndex			//to make sure that there is no old index hanging around

	SetDataFolder root:

	return(0)
End



Function CleanupTimes(xLoc,yLoc,timePt)
	Wave xLoc,yLoc,timePt

	// start at the back and remove zeros
	Variable num=numpnts(xLoc),ii
	
	ii=num
	do
		ii -= 1
		if(timePt[ii] == 0 && xLoc[ii] == 0 && yLoc[ii] == 0)
			DeletePoints ii, 1, xLoc,yLoc,timePt
		endif
	while(timePt[ii-1] == 0 && xLoc[ii-1] == 0 && yLoc[ii-1] == 0)
	
	return(0)
End

Function LogIntEvent_Proc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
		
	SetDataFolder root:Packages:NIST:Event
	if(checked)
		Duplicate/O logslicedData dispsliceData
	else
		Duplicate/O slicedData dispsliceData
	endif

	SetDataFolder root:
End



// this "fails" for data sets that have 3 or 4 slices, as the ModifyImage command
// interprets the data as being RGB - and so does nothing.
// need to find a way around this
///
// I could modify this procedure to use the log = 0|1 keyword for the log Z display
// rather than creating a duplicate wave of log(data)
//
Function sliceSelectEvent_Proc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR nslices = root:Packages:NIST:gEvent_nslices
	NVAR selectedslice = root:Packages:NIST:gEvent_tsdisp
	
	if(varNum < 0)
		selectedslice = 0
		DoUpdate
	elseif (varNum > nslices-1)
		selectedslice = nslices-1
		DoUpdate
	else
		ModifyImage/W=EventModePanel#Event_slicegraph ''#0 plane = varNum 
	endif

End

Function DifferentiatedTime()

	Wave rescaledTime = root:Packages:NIST:Event:rescaledTime
	
	Differentiate rescaledTime/D=rescaledTime_DIF
//	Display rescaledTime,rescaledTime_DIF
	DoWindow/F Differentiated_Time
	if(V_flag == 0)
		Display/N=Differentiated_Time/K=1 rescaledTime_DIF
		Legend
		Modifygraph gaps=0
		ModifyGraph zero(left)=1
		Label left "\\Z14Delta (dt/event)"
		Label bottom "\\Z14Event number"
	endif
	
	return(0)
End


//
// for the bit shifts, see the decimal-binary conversion
// http://www.binaryconvert.com/convert_unsigned_int.html
//
//		K0 = 536870912
// 		Print (K0 & 0x08000000)/134217728 	//bit 27 only, shift by 2^27
//		Print (K0 & 0x10000000)/268435456		//bit 28 only, shift by 2^28
//		Print (K0 & 0x20000000)/536870912		//bit 29 only, shift by 2^29
//
//
Function LoadEvents()
	
	NVAR time_msw = root:Packages:NIST:gEvent_time_msw
	NVAR time_lsw = root:Packages:NIST:gEvent_time_lsw
	NVAR t_longest = root:Packages:NIST:gEvent_t_longest
	
	SVAR filepathstr = root:Packages:NIST:gEvent_logfile
	SVAR dispStr = root:Packages:NIST:gEventDisplayString
	
	SetDataFolder root:Packages:NIST:Event

	Variable fileref
	String buffer
	String fileStr,tmpStr
	Variable dataval,timeval,type,numLines,verbose,verbose3
	Variable xval,yval,rollBit,nRoll,roll_time,bit29,bit28,bit27
	Variable ii,flaggedEvent,rolloverHappened,numBad=0,tmpPP=0,tmpT0=0
	Variable Xmax, yMax
	
	xMax = 127		// number the detector from 0->127 
	yMax = 127
	
	verbose3 = 0			//prints out the rollover events (type==3)
	verbose = 0
	numLines = 0

	
	// what I really need is the number of XY events
	Variable numXYevents,num1,num2,num3,num0,totBytes,numPP,numT0,numDL,numFF,numZero
	Variable numRemoved
	numXYevents = 0
	num0 = 0
	num1 = 0
	num2 = 0
	num3 = 0
	numPP = 0
	numT0 = 0
	numDL = 0
	numFF = 0
	numZero = 0
	numRemoved = 0

//tic()
	Open/R fileref as filepathstr
		FStatus fileref
	Close fileref

	totBytes = V_logEOF
	Print "total bytes = ", totBytes
	
//toc()
//


// do a "pre-scan to get some of the counts, so that I can allocate space. This does
// double the read time, but is still faster than adding points to waves as the file is read
//	

	tic()

	Open/R fileref as filepathstr
	do
		do
			FReadLine fileref, buffer			//skip the "blank" lines that have one character
		while(strlen(buffer) == 1)		

		if (strlen(buffer) == 0)
			break
		endif
		
		sscanf buffer,"%x",dataval
		
		// two most sig bits (31-30)
		type = (dataval & 0xC0000000)/1073741824		//right shift by 2^30
				
		if(type == 0)
			num0 += 1
			numXYevents += 1
		endif
		if(type == 2)
			num2 += 1
			numXYevents += 1
		endif
		if(type == 1)
			num1 += 1
		endif
		if(type == 3)
			num3 += 1
		endif	
		
		bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
		
		if(type==0 || type==2)
			numPP += round(bit29)
		endif
		
		if(type==1 || type==3)
			numT0 += round(bit29)
		endif
		
		if(dataval == 0)
			numZero += 1
		endif
		
	while(1)
	Close fileref
//		done counting the number of XY events
	toc()

Print "numT0 = ",numT0	
	
//
//	
//	Printf "numXYevents = %d\r",numXYevents
//	Printf "XY = num0 = %d\r",num0
//	Printf "XY time = num2 = %d\r",num2
//	Printf "time MSW = num1 = %d\r",num1
//	Printf "Rollover = num3 = %d\r",num3
//	Printf "num0 + num2 = %d\r",num0+num2

// dispStr will be displayed on the panel
	fileStr = ParseFilePath(0, filepathstr, ":", 1, 0)
	
	sprintf tmpStr, "%s: %d total bytes\r",fileStr,totBytes 
	dispStr = tmpStr
	sprintf tmpStr,"numXYevents = %d\r",numXYevents
	dispStr += tmpStr
//	sprintf tmpStr,"XY = num0 = %d\r",num0
//	dispStr += tmpStr
//	sprintf tmpStr,"\rXY time = num2 = %d\rtime MSW = num1 = %d",num2,num1
//	dispStr += tmpStr
//	sprintf tmpStr,"XY time = num2 = %d\r",num2
//	dispStr += tmpStr
//	sprintf tmpStr,"time MSW = num1 = %d\r",num1
//	dispStr += tmpStr
	sprintf tmpStr,"PP = %d  :  ",numPP
	dispStr += tmpStr
	sprintf tmpStr,"ZeroData = %d\r",numZero
	dispStr += tmpStr
	sprintf tmpStr,"Rollover = %d",num3
	dispStr += tmpStr

	
	
	Make/O/U/N=(numXYevents) xLoc,yLoc
	Make/O/D/N=(numXYevents) timePt
//	Make/O/U/N=(totBytes/4) xLoc,yLoc		//too large, trim when done (bad idea)
//	Make/O/D/N=(totBytes/4) timePt
	Make/O/D/N=1000 badTimePt,badEventNum,PPTime,PPEventNum,T0Time,T0EventNum
	badTimePt=0
	badEventNum=0
	PPTime=0
	PPEventNum=0
	T0Time=0
	T0EventNum=0
	xLoc=0
	yLoc=0
	timePt=0
	
	nRoll = 0		//number of rollover events
	roll_time = 2^26		//units of 10-7 sec
	
	NVAR removeBadEvents = root:Packages:NIST:gRemoveBadEvents
	
	time_msw=0
	
	tic()
	
	ii = 0
	
	Open/R fileref as filepathstr
	
	// remove events at the beginning up to a type==2 so that the msw and lsw times are reset properly
	if(RemoveBadEvents == 1)
		do
			do
				FReadLine fileref, buffer			//skip the "blank" lines that have one character
			while(strlen(buffer) == 1)		
	
			if (strlen(buffer) == 0)
				break
			endif
			
			sscanf buffer,"%x",dataval
		// two most sig bits (31-30)
			type = (dataval & 0xC0000000)/1073741824		//right shift by 2^30
			
			if(type == 2)
				// this is the first event with a proper time value, so process the XY-time event as ususal
				// and then break to drop to the main loop, where the next event == type 1
				
				xval = xMax - (dataval & 255)						//last 8 bits (7-0)
				yval = (dataval & 65280)/256						//bits 15-8, right shift by 2^8
		
				time_lsw = (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16
		
				if(verbose)
		//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "%u : %u : %u : %u\r",dataval,timeval,xval,yval
				endif
				
				// this is the first point, be sure that ii = 0
				ii = 0
				xLoc[ii] = xval
				yLoc[ii] = yval
				
				Print "At beginning of file, numBad = ",numBad
				break	// the next do loop processes the bulk of the file (** the next event == type 1 = MIR)
			else
				numBad += 1
				numRemoved += 1
			endif
			
			//ii+=1		don't increment the counter
		while(1)
	endif
	
	// now read the main portion of the file.
	do
		do
			FReadLine fileref, buffer			//skip the "blank" lines that have one character
		while(strlen(buffer) == 1)		

		if (strlen(buffer) == 0)
			break
		endif
		
		sscanf buffer,"%x",dataval
		

//		type = (dataval & ~(2^32 - 2^30 -1))/2^30

		// two most sig bits (31-30)
		type = (dataval & 0xC0000000)/1073741824		//right shift by 2^30
		
		//
		//Constant ATXY = 0
		//Constant ATXYM = 2
		//Constant ATMIR = 1
		//Constant ATMAR = 3
		//
						
		if(verbose > 0)
			verbose -= 1
		endif
//		
		switch(type)
			case ATXY:		// 0
				if(verbose)		
					printf "XY : "		
				endif
				
				// if the datavalue is == 0, just skip it now (it can only be interpreted as type 0, obviously)
				if(dataval == 0 && RemoveBadEvents == 1)
					numRemoved += 1
					break		//don't increment ii
				endif
				
				// if it's a pileup event, skip it now (this can be either type 0 or 2)
				bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
				if(bit29 == 1 && RemoveBadEvents == 1)
					PPTime[tmpPP] = timeval
					PPEventNum[tmpPP] = ii
					tmpPP += 1
					numRemoved += 1
					break		//don't increment ii
				endif
				
//				xval = ~(dataval & ~(2^32 - 2^8)) & 127
//				yval = ((dataval & ~(2^32 - 2^16 ))/2^8) & 127
//				time_lsw = (dataval & ~(2^32 - 2^29))/2^16

				xval = xMax - (dataval & 255)						//last 8 bits (7-0)
				yval = (dataval & 65280)/256						//bits 15-8, right shift by 2^8
				time_lsw = (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16

				timeval = trunc( nRoll*roll_time + (time_msw * (8192)) + time_lsw )		//left shift msw by 2^13, then add in lsw, as an integer
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				
				
				// catch the "bad" events:
				// if an XY event follows a rollover, time_msw is 0 by definition, but does not immediately get 
				// re-evalulated here. Throw out only the immediately following points where msw is still 8191
				if(rolloverHappened && RemoveBadEvents == 1)
					// maybe a bad event
					if(time_msw == 8191)
						badTimePt[numBad] = timeVal
						badEventNum[numBad] = ii
						numBad +=1
						numRemoved += 1
					else
						// time_msw has been reset, points are good now, so keep this one
						xLoc[ii] = xval
						yLoc[ii] = yval
						timePt[ii] = timeval
						
//						if(xval == 127 && yval == 0)
//							// check bit 29
//							bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
//							Print "XY=127,0 : bit29 = ",bit29
//						endif
						
						ii+=1
						rolloverHappened = 0
					endif
				else
					// normal processing of good point, keep it
					xLoc[ii] = xval
					yLoc[ii] = yval
					timePt[ii] = timeval
				
//					if(xval == 127 && yval == 0)
//						// check bit 29
//						bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
//						Printf "XY=127,0 : bit29 = %u : d=%u\r",bit29,dataval
//					endif
					ii+=1
				endif


				if(verbose)		
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "d=%u : t=%u : msw=%u : lsw=%u : %u : %u \r",dataval,timeval,time_msw,time_lsw,xval,yval
				endif				
	
//				verbose = 0
				break
			case ATXYM: // 2 
				if(verbose)
					printf "XYM : "
				endif
				
				// if it's a pileup event, skip it now (this can be either type 0 or 2)
				// - but can I do this if this is an XY-time event? This will lead to a wrong time, and a time 
				// assigned to an XY (0,0)...
//				bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
//				if(bit29 == 1 && RemoveBadEvents == 1)
//					Print "*****Bit 29 (PP) event set for Type==2, but not handled, ii = ",ii
////					break		//don't increment ii
//				endif
				
//				xval = ~(dataval & ~(2^32 - 2^8)) & 127
//				yval = ((dataval & ~(2^32 - 2^16 ))/2^8) & 127
//				time_lsw =  (dataval & ~(2^32 - 2^29 ))/2^16		//this method gives a FP result!! likely since the "^" operation gives FP result...

				xval = xMax - (dataval & 255)						//last 8 bits (7-0)
				yval = (dataval & 65280)/256						//bits 15-8, right shift by 2^8

				time_lsw = (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16 (result is integer)

				if(verbose)
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "%u : %u : %u : %u\r",dataval,timeval,xval,yval
				endif
				
				xLoc[ii] = xval
				yLoc[ii] = yval

				// don't fill in the time yet, or increment the index ii
				// the next event MUST be ATMIR with the MSW time bits
				//
//				verbose = 0
				break
			case ATMIR:  // 1
				if(verbose)
					printf "MIR : "
				endif

				time_msw =  (dataval & 536805376)/65536			//13 bits, 28-16, right shift by 2^16
				timeval = trunc( nRoll*roll_time + (time_msw * (8192)) + time_lsw )
				if (timeval > t_longest) 
					t_longest = timeval
				endif
				if(verbose)
//					printf "%u : %u : %u : %u\r",dataval,time_lsw,time_msw,timeval
					printf "d=%u : t=%u : msw=%u : lsw=%u : tlong=%u\r",dataval,timeval,time_msw,time_lsw,t_longest
				endif
				
				// the XY position was in the previous event ATXYM
				timePt[ii] = timeval

				bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
				if(bit29 != 0)		// bit 29 set is a T0 event
					//Printf "bit29 = 1 at ii = %d : type = %d\r",ii,type
					T0Time[tmpT0] = timeval
					T0EventNum[tmpT0] = ii
					tmpT0 += 1
					// reset nRoll = 0 for calcluating the time
					nRoll = 0
				endif
								
				ii+=1
//				verbose = 0
				break
			case ATMAR:  // 3
				if(verbose3)
//					verbose = 15
//					verbose = 2
					printf "MAR : "
				endif
				
				// do something with the rollover event?
				
				// check bit 29
				bit29 = (dataval & 0x20000000)/536870912		//bit 29 only , shift by 2^29
				nRoll += 1
// not doing anything with these bits yet	
				bit28 = (dataval & 0x10000000)/268435456		//bit 28 only, shift by 2^28	
				bit27 = (dataval & 0x08000000)/134217728 	//bit 27 only, shift by 2^27

				if(verbose3)
					printf "d=%u : b29=%u : b28=%u : b27=%u : #Roll=%u \r",dataval,bit29, bit28, bit27,nRoll
				endif
				
				if(bit29 != 0)		// bit 29 set is a T0 event
					//Printf "bit29 = 1 at ii = %d : type = %d\r",ii,type
					T0Time[tmpT0] = timeval
					T0EventNum[tmpT0] = ii
					tmpT0 += 1
					// reset nRoll = 0 for calcluating the time
					nRoll = 0
				endif
				
				rolloverHappened = 1

				break
		endswitch
		
//		if(ii<18)
//			printf "TYPE=%d : ii=%d : d=%u : t=%u : msw=%u : lsw=%u : %u : %u \r",type,ii,dataval,timeval,time_msw,time_lsw,xval,yval
//		endif	
			
	while(1)
	
	
	Close fileref
	
	toc()
	
	Print "Events removed = ",numRemoved
	
	sPrintf tmpStr,"\rBad Events = numBad = %d (%g %% of events)",numBad,numBad/numXYevents*100
	dispStr += tmpStr

	SetDataFolder root:
	
	return(0)
	
End 

///

Proc BinEventBarGraph()
	
	DoWindow/F EventBarGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(110,705,610,1132)/N=EventBarGraph /K=1 binCount vs binEndTime
		SetDataFolder fldrSav0
		ModifyGraph mode=5
		ModifyGraph marker=19
		ModifyGraph lSize=2
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=2
		ModifyGraph hbFill=2
		ModifyGraph gaps=0
		ModifyGraph usePlusRGB=1
		ModifyGraph toMode=1
		ModifyGraph useBarStrokeRGB=1
	//	ModifyGraph log=1
		ModifyGraph standoff=0
		Label bottom "\\Z14Time (seconds)"
		Label left "\\Z14Number of Events"
	//	SetAxis left 0.1,4189
	//	SetAxis bottom 0.0001,180.84853
	endif
End


Proc ShowBinTable() : Table

	DoWindow/F BinEventTable
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Edit/W=(498,699,1003,955) /K=1/N=BinEventTable binCount,binEndTime
		ModifyTable format(Point)=1,sigDigits(binEndTime)=16,width(binEndTime)=218
		SetDataFolder fldrSav0
	endif
EndMacro


// only show the first 1500 data points
//
Proc ShowRescaledTimeGraph() : Graph

	DoWindow/F RescaledTimeGraph
	if(V_flag == 0)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:Packages:NIST:Event:
		Display /W=(25,44,486,356)/K=1/N=RescaledTimeGraph rescaledTime
		SetDataFolder fldrSav0
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph rgb(rescaledTime)=(0,0,0)
		ModifyGraph msize=2
//		SetAxis/A=2 left			//only autoscale the visible data (based on the bottom limits)
//		SetAxis bottom 0,1500
		ErrorBars rescaledTime OFF 
		Label left "\\Z14Time (seconds)"
		Label bottom "\\Z14Event number"
		ShowInfo
	endif
	
EndMacro



Proc ExportSlicesAsVAX(firstNum,prefix)
	Variable firstNum=1
	String prefix="SAMPL"

	SaveSlicesAsVAX(firstNum,prefix[0,4])		//make sure that the prefix is 5 chars
End

//////// procedures to be able to export the slices as RAW VAX files.

// 1- load the raw data file to use the header (it must already be in RAW)
// 1.5- copy the raw data to the temp folder (STO)
// 1.7- ask for the prefix and starting run number (these are passed in)
// 2- copy the slice of data to the temp folder (STO)
// 3- touch up the time/counts in the slice header values in STO
// 4- write out the VAX file
// 5- repeat (2-4) for the number of slices
//
//
Function SaveSlicesAsVAX(firstNum,prefix)
	Variable firstNum
	String prefix

	DoAlert 1,"Is the full data file loaded as a RAW data file? If not, load it and start over..."
	if(V_flag == 2)
		return (0)
	endif
	
// copy the contents of RAW to STO so I can work from there
	CopyWorkContents("RAW","STO")

	// now declare all of the waves, now that they are sure to be there

	WAVE slicedData=root:Packages:NIST:Event:slicedData
	Make/O/D/N=(128,128) curSlice
	
	NVAR nslices = root:Packages:NIST:gEvent_nslices
	WAVE binEndTime = root:Packages:NIST:Event:binEndTime

	Wave rw=root:Packages:NIST:STO:realsRead
	Wave iw=root:Packages:NIST:STO:integersRead
	Wave/T tw=root:Packages:NIST:STO:textRead
	Wave data=root:Packages:NIST:STO:data
	Wave linear_data=root:Packages:NIST:STO:linear_data
	
	
	Wave rw_raw=root:Packages:NIST:RAW:realsRead
	Wave iw_raw=root:Packages:NIST:RAW:integersRead
	Wave/T tw_raw=root:Packages:NIST:RAW:textRead

// for generating the alphanumeric
	String timeStr= secs2date(datetime,-1)
	String monthStr=StringFromList(1, timeStr  ,"/")
	String numStr="",labelStr

	Variable ii,err,binFraction
	
	for(ii=0;ii<nslices;ii+=1)

		//get the current slice and put it in the STO folder
		curSlice = slicedData[p][q][ii]
		data = curSlice
		linear_data = curSlice
		
		// touch up the header as needed
		// count time = iw[2]
		// monCt = rw[0]
		// detCt = rw[2]
		//tw[0] must now be the file name
		//
		// count time = fraction of total binning * total count time
		binFraction = (binEndTime[ii+1]-binEndTime[ii])/(binEndTime[nslices]-binEndTime[0])
		
		iw[2] = trunc(binFraction*iw_raw[2])
		rw[0] = trunc(binFraction*rw_raw[0])
		rw[2] = sum(curSlice,-inf,inf)		//total counts in slice
	
		if(firstNum<10)
			numStr = "00"+num2str(firstNum)
		else
			if(firstNum<100)
				numStr = "0"+num2str(firstNum)
			else
				numStr = num2str(firstNum)
			Endif
		Endif	
		tw[0] = prefix+numstr+".SA2_EVE_"+(num2char(str2num(monthStr)+64))+numStr
		labelStr = tw_raw[6]
		
		labelStr = PadString(labelStr,60,0x20) 	//60 fortran-style spaces
		tw[6] = labelStr[0,59]
		
		//write out the file - this uses the tw[0] and home path
		Write_VAXRaw_Data("STO","",0)

		//increment the run number, alpha
		firstNum += 1	
	endfor

	return(0)
End





/////////////
//The histogramming
//
// 6 AUG 2012
//
// from Igor Exchange, RGerkin
//  http://www.igorexchange.com/node/1373
// -- see the related thread on the mailing list
//

//
// Now see if this can be succesfully applied to the timeslicing data sets
// -- talk to Jeff about what he's gotten implemented, and what's still missing
// - both in timeslicing, and in TISANE
// - un-scale the wave? or make it work as 128x128

Function Setup_JointHistogram()

//	tic()

	make/D /o/n=1000000 data1=gnoise(1), data2=gnoise(1)
	make/D /o/n=(25,25) myHist
	setscale x,-3,3,myHist
	setscale y,-3,3,myHist
	IndexForHistogram(data1,data2,myhist)
	Wave index=SavedIndex
	JointHistogram(data1,data2,myHist,index)
	NewImage myHist
	
//	toc()
	
End


Function JointHistogram(w0,w1,hist,index)
	wave w0,w1,hist,index
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)
 	
	// Compute the histogram and redimension it.  
	histogram /b={0,1,bins0*bins1} index,hist
	redimension/D /n=(bins0,bins1) hist // Redimension to 2D.  
	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End


// need a way of visualizing the bin spacing / number of bins vs the full time of the data collection
// then set the range of the source to send to the joint histogram operation
// to assign to arrays (or a 3D wave)
//
// -- see my model with the "layered" form factor - or whatever I called it. That shows different
// binning and visualizing as bar graphs.
//
// -- just need to send x2pnt or findLevel, or something similar to define the POINT
// values
//
// can also speed this up since the index only needs to be done once, so the
// histogram operation can be done separately, as the bins require
//
//
Function JointHistogramWithRange(w0,w1,hist,index,pt1,pt2)
	wave w0,w1,hist,index
	Variable pt1,pt2
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)

	// Compute the histogram and redimension it.  
	histogram /b={0,1,bins0*bins1}/R=[pt1,pt2] index,hist
	redimension/D /n=(bins0,bins1) hist // Redimension to 2D.  
	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End


// just does the indexing, creates wave SavedIndex in the current folder for the index
//
Function IndexForHistogram(w0,w1,hist)
	wave w0,w1,hist
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=dimoffset(hist,0)
	variable left1=dimoffset(hist,1)
	variable right0=left0+bins0*dimdelta(hist,0)
	variable right1=left1+bins1*dimdelta(hist,1)
 
	// Scale between 0 and the number of bins to create an index wave.  
	if(ThreadProcessorCount<4) // For older machines, matrixop is faster.  
		matrixop /free idx=round(bins0*(w0-left0)/(right0-left0))+bins0*round(bins1*(w1-left1)/(right1-left1))
	else // For newer machines with many cores, multithreading with make is faster.  
		make/free/n=(n) idx
		multithread idx=round(bins0*(w0-left0)/(right0-left0))+bins0*round(bins1*(w1-left1)/(right1-left1))
	endif
 
 	KillWaves/Z SavedIndex
 	MoveWave idx,SavedIndex
 	
//	// Compute the histogram and redimension it.  
//	histogram /b={0,1,bins0*bins1} idx,hist
//	redimension /n=(bins0,bins1) hist // Redimension to 2D.  
//	setscale x,left0,right0,hist // Fix the histogram scaling in the x-dimension.  
//	setscale y,left1,right1,hist // Fix the histogram scaling in the y-dimension.  
End




///////
//// @ IgorExchange
////TicToc
////Posted April 16th, 2009 by bgallarda
////	�	in Programming 6.10.x
//	
//function tic()
//	variable/G tictoc = startMSTimer
//end
// 
//function toc()
//	NVAR/Z tictoc
//	variable ttTime = stopMSTimer(tictoc)
//	printf "%g seconds\r", (ttTime/1e6)
//	killvariables/Z tictoc
//end
//
//
//Function testTicToc()
// 
//	tic()
//	variable i
//	For(i=0;i<10000;i+=1)
//		make/O/N=512 temp = gnoise(2)
//		FFT temp
//	Endfor
//	killwaves/z temp
//	toc()
//End
//
////////////////