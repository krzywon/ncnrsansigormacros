#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0
#pragma IgorVersion=6.1

//
// this will become the equivalent of "RawWindowHook"
//
// Procedures to display the detector data along with whatever visualization tools
// necessary to understand the data
//


// TODO
//
// -- have the status automatically fill in when a new file is loaded, rather than needing a click of the "status" button
// -- need a place somewhere to show the currently displayed folder
// -- checkboxes for "active" corrections?
// -- display of Q, counts, QxQy, X and Y
// -- do I need a color bar? or is this not used at all? I like it to be there, or the colors are a waste of information
//		(then... where do I put the color bar?)
// -- define the "hook" function, and attach it to the panel (or the main detector subwindow?)
//


//
// call this after loading data to either draw the data display panel or to update the contents
//
// TODO
// -- make sure that the "type" input is correctly used for the updating of the data, values, etc.
// -- add a procedure to define the global variables for pos, counts, QxQy, etc.
//
Proc UpdateDisplayInformation(type)
	String type 
	
	DoWindow/F VSANS_Data
	Print V_flag
	if(V_flag==0)
	
		VSANSDataPanelGlobals()
		
		VSANS_DataPanel()		//draws the panel
		// fake a click on all three tabs - to populate the data
		FakeTabClick(2)
		FakeTabClick(1)
		FakeTabClick(0)
	endif
	
	// TODO: update the information here  - in either case
	// what isn't automatically picked up? What is "stale" on the display?
	String/G root:Packages:NIST:VSANS:Globals:gCurDispType = type
//	DoWindow/T VSANS_Data,type + " VSANS_Data"
end

//
// creates/initializes the globals for display of the data panel
//
Function VSANSDataPanelGlobals()

	SetDataFolder root:Packages:NIST:VSANS:Globals
	
	Variable/G gXPos=0
	Variable/G gYPos=0
	Variable/G gQX=0
	Variable/G gQY=0
	Variable/G gQQ=0
	Variable/G gNCounts=0
	String/G gCurDispFile = "default string"
	String/G gCurTitle = ""
	String/G gCurDispType = ""
	
	SetDataFolder root:
End

// TODO
//
// -- fill in the proper window title in the DoWindow/T command
// -- add help text for all of the controls
//
Window VSANS_DataPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(37,45,1038,719) /N=VSANS_Data
	ShowTools/A
	ModifyPanel cbRGB=(65535,60076,49151)

	String curFolder = root:Packages:NIST:VSANS:Globals:gCurDispType
	DoWindow/T VSANS_Data,curFolder + " VSANS_Data"
	SetWindow VSANS_Data,hook(dataHook)=VSANSDataHook,hookevents=2
	
	SetDrawLayer UserBack
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 200,70,310,160
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 320,70,430,160
	SetDrawEnv linethick= 2,dash= 1,fillpat= 0
	DrawRect 440,70,550,160
	
	SetDrawEnv fsize= 18
	DrawText 230,115,"Front"
	SetDrawEnv fsize= 18
	DrawText 348,115,"Middle"
	SetDrawEnv fsize= 18
	DrawText 476,115,"Back"
	
	ToolsGrid visible=1


	TabControl tab0,pos={13,41},size={572,617},proc=VDataTabProc,tabLabel(0)="Front"
	TabControl tab0,tabLabel(1)="Middle",tabLabel(2)="Back",value= 2

// on the side	
	Button button_status,pos={607,146},size={70,20},proc=StatusButtonProc,title="Status"
	Button button_IvsQ,pos={689,113},size={70,20},proc=IvsQPanelButtonProc,title="I vs. Q"
	Button button_file_m,pos={619,55},size={50,20},proc=File_m_ButtonProc,title="File <"
	Button button_file_p,pos={679,55},size={50,20},proc=File_p_ButtonProc,title="File >"
	Button button_log,pos={689,146},size={70,20},proc=LogLinButtonProc,title="isLin",userData="0"
	Button button_tab_p,pos={648,81},size={50,20},proc=Tab_p_ButtonProc,title="Tab >"
	Button button_isolate,pos={606,114},size={70,20},proc=IsolateButtonProc,title="Isolate"

	TitleBox title_file,pos={606,178},size={76,20},variable= file_name
	TitleBox title_status,pos={606,210},size={76,20},variable= root:Packages:NIST:VSANS:Globals:gCurDispFile
	
	Button button_tagFile,pos={603,412},size={70,20},proc=TagFileButtonProc,title="Tag File"
	Button button_BeamCtr,pos={603,450},size={70,20},proc=BeamCtrButtonProc,title="Beam Ctr"

// on the tabs, always visible
	TitleBox title_xy,pos={24,71},size={76,20},variable= file_name
	Slider slider_hi,pos={558,224},size={16,80},proc=HiMapSliderProc
	Slider slider_hi,limits={0,1,0},value= 1,ticks= 0
	Slider slider_lo,pos={558,315},size={16,80},proc=LowMapSliderProc
	Slider slider_lo,limits={0,1,0},value= 0,ticks= 0

	SetVariable xpos,pos={22,97},size={50,17},title="X "
	SetVariable xpos,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:gXPos
	SetVariable xpos,help={"x-position on the detector"},frame=0,noedit=1
	SetVariable ypos,pos={22,121},size={50,17},title="Y "
	SetVariable ypos,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:gYPos
	SetVariable ypos,help={"y-position on the detector"},frame=0,noedit=1
	SetVariable counts,pos={22,151},size={150,17},title="Counts "
	SetVariable counts,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:gNCounts
	SetVariable counts,help={"Neutron counts"},frame=0,noedit=1
	SetVariable qxval,pos={83,94},size={85,17},title="qX"
	SetVariable qxval,help={"q value in the x-direction on the detector"},frame=0,noedit=1
	SetVariable qxval,format="%+7.5f",limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:gQX
	SetVariable qyval,pos={83,113},size={85,17},title="qY"
	SetVariable qyval,help={"q value in the y-direction on the detector"},frame=0,noedit=1
	SetVariable qyval,format="%+7.5f",limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:gQY
	SetVariable q_pos,pos={83,132},size={85,17},title="q "
	SetVariable q_pos,help={"q-value on the detector at (x,y)"},format="%+7.5f"
	SetVariable q_pos,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:gQQ,frame=0,noedit=1
	
	Make/O/D tmp_asdf
	// for back panels (in pixels?)	
	Display/W=(50,185,545,620)/HOST=# tmp_asdf 
	RenameWindow #,det_panelsB
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "pixels"
	Label bottom "pixels"	
	SetActiveSubwindow ##
	
	// for middle panels (in pixels?)	
	Display/W=(50,185,545,620)/HOST=# tmp_asdf 
	RenameWindow #,det_panelsM
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "pixels"
	Label bottom "pixels"	
	SetActiveSubwindow ##
	
	// for front panels (in pixels?)	
	Display/W=(50,185,545,620)/HOST=# tmp_asdf 
	RenameWindow #,det_panelsF
	ModifyGraph mode=2		// mode = 2 = dots
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2,mirror=1
	Label left "pixels"
	Label bottom "pixels"	
	SetActiveSubwindow ##
	
EndMacro

//
// event code 4 = mouse moved
// 
// mouse moved is the only event that I really care about for the data display.
//
// TODO
// -- figure out how to respond only to events in the main window
// -- figure out which is the correct image to respond "from"
//
Function VSANSDataHook(s)
	STRUCT WMWinHookStruct &s

	Variable hookResult = 0

	switch(s.eventCode)
		case 0:				// Activate
			// Handle activate
//			Print "Activate"
			break

		case 1:				// Deactivate
			// Handle deactivate
			break
			
		case 3:		//mouse down
//			Print "mouse down"
			break
			
		case 4:		// mouse moved
			NVAR xloc = root:Packages:NIST:VSANS:Globals:gXPos
			NVAR yloc = root:Packages:NIST:VSANS:Globals:gYPos
			NVAR gQX = root:Packages:NIST:VSANS:Globals:gQX
			NVAR gQY = root:Packages:NIST:VSANS:Globals:gQY
			NVAR gQQ = root:Packages:NIST:VSANS:Globals:gQQ
			NVAR gNCounts = root:Packages:NIST:VSANS:Globals:gNCounts
			SVAR gCurDispFile = root:Packages:NIST:VSANS:Globals:gCurDispFile
			SVAR gCurDispType = root:Packages:NIST:VSANS:Globals:gCurDispType		//the current folder
			Variable xaxval,yaxval,tab
			
			// is the mouse location within the "main" display window?
			// if so, do something, if not, do nothing?
			// right now, the "main" display is at (50,185,545,620). its name depends on the active tab
			
//				xloc = s.mouseLoc.h
//				yloc = s.mouseLoc.v

//			if out of bounds, exit now
//		TODO - currently the values are hard-wired. eliminate this later if the size of the graph changes
			if(s.mouseLoc.h < 50 || s.mouseLoc.h > 545 || s.mouseLoc.v < 185 || s.mouseLoc.v > 620)
				break
			endif	
			
//			if(in bounds)
//				get the point location
//				update the globals --
//				but which data instance am I pointing to?
//				deduce the carriage and panel, and calculate Q
//			endif

			GetWindow $s.winName activeSW
			String activeSubwindow = S_value		// returns something like: "VSANS_Data#det_panelsF"
				
			xaxval= AxisValFromPixel("","bottom",s.mouseLoc.h)
			yaxval= AxisValFromPixel("","left",s.mouseLoc.v)
			xloc = round(xaxval)
			yloc = round(yaxval)
			
			// which tab is selected? -this is the main graph panel (subwindow may not be the active one!)
			ControlInfo/W=VSANS_Data tab0
			tab = V_Value
			if(tab == 0)
				activeSubwindow = "VSANS_Data#det_panelsF"
			elseif (tab == 1)
				activeSubwindow = "VSANS_Data#det_panelsM"
			else
				activeSubwindow = "VSANS_Data#det_panelsB"
			endif
			
			// which images are here?
			String detStr="",imStr,carriageStr
			String currentImageRef
			String imageList = ImageNameList(activeSubwindow,";")
			Variable ii,nIm,testX,testY,xctr,yctr,sdd,lam,pixSizeX,pixSizeY
			nIm = ItemsInList(imageList,";")
			gCurDispFile = imageList
			if(nIm==0)
				break		//problem, get out
			endif

			// images were added in the order TBLR, so look back through in the order RLBT, checking each to see if
			// the xy value is found on that (scaled) array
						
			// loop backwards through the list of panels (may only be one if on the back)
			for(ii=nIm-1;ii>=0;ii-=1)
				Wave w = ImageNameToWaveRef(activeSubwindow,StringFromList(ii, imageList,";"))
				
				// which, if any image is the mouse xy location on?
				// use a multidemensional equivalent to x2pnt: (ScaledDimPos - DimOffset(waveName, dim))/DimDelta(waveName,dim)
				testX = trunc( (xloc - DimOffset(w,0))/DimDelta(w,0) )
				testY = trunc( (yloc - DimOffset(w,1))/DimDelta(w,1) )
				
				if( (testX > 0 && testX < DimSize(w,0)) && (testY > 0 && testY < DimSize(w,1)) )
					// we're in-bounds on this wave
					
					// count value to the global
					gNCounts = w[testX][testY]
					
					// deduce the detector panel
					currentImageRef = StringFromList(ii, imageList,";")	//the image instance ##
					// string is "data", or "data#2" etc. - so this returns "", "1", "2", or "3"
					imStr = StringFromList(1, currentImageRef,"#")		
					carriageStr = activeSubWindow[strlen(activeSubWindow)-1]
					
					if(cmpstr(carriageStr,"B")==0)
						detStr = carriageStr
					else
						if(strlen(imStr)==0)
							imStr = "9"			// a dummy value so I can replace it later
						endif
						detStr = carriageStr+imStr		// "F2" or something similar
						detStr = ReplaceString("9", detStr, "T") 	// ASSUMPTION :::: instances 0123 correspond to TBLR
						detStr = ReplaceString("1", detStr, "B") 	// ASSUMPTION :::: this is the order that the panels
						detStr = ReplaceString("2", detStr, "L") 	// ASSUMPTION :::: are ALWAYS added to the graph
						detStr = ReplaceString("3", detStr, "R") 	// ASSUMPTION :::: 
					endif
					gCurDispFile = detStr

					// now figure out q
					// calculate the q-values, will be different depending on which panel is up (pixel size, geometry, etc.)
					// TODO: !!!! get rid of the hard-wired values
					// TODO: be sure that the units from HDF are what I expect
					// TODO: beam center XY are pixels in the file, expected in the function, but are better suited for mm or cm
					// TODO: units of xy pixel size are likely wrong
					xctr = V_getDet_beam_center_x(gCurDispType,detStr)		//written in pixels
					yctr = V_getDet_beam_center_y(gCurDispType,detStr)
					sdd = V_getDet_distance(gCurDispType,detStr)	/ 100	//written in cm, pass in meters
					lam = V_getVSWavelength(gCurDispType)		//A
					pixSizeX = V_getDet_x_pixel_size(gCurDispType,detStr)/10		// written mm? need cm
					pixSizeY = V_getDet_y_pixel_size(gCurDispType,detStr)/10		// written mm? need cm
					
					gQQ = V_CalcQval(xaxval+1,yaxval+1,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
					gQX = V_CalcQX(xaxval+1,yaxval+1,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
					gQY = V_CalcQY(xaxval+1,yaxval+1,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)

					ii = -1		//look no further, set ii to bad value to exit the for loop
				endif	//end if(mouse is over a detector panel)
			endfor		// end loop over list of displayed images
		
			break
			
		// And so on . . .
	endswitch

	return hookResult		// 0 if nothing done, else 1
End

//
//lots to to here:
//
// - 1 - display the appropriate controls for each tab, and hide the others
// - 2 - display the correct detector data for each tab, and remove the others from the graph
// -----?? can I draw 3 graphs, and just put the right one on top?? move the other two to the side?
//
//
// TODO 
//  -- add all of the controls of the VCALC panel (log scaling, adjusting the axes, etc.)
//  x- get the panel to be correctly populated first, rather than needing to click everywhere to fill in
//  x- remove the dependency on VCALC being initialized first, and using dummy waves from there...
//
Function VDataTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
		
//			SetDataFolder root:Packages:NIST:VSANS:VCALC
			SetDataFolder root:
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsB tmp_asdf
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsM tmp_asdf
			RemoveFromGraph/Z /W=VSANS_Data#det_panelsF tmp_asdf
			SetDataFolder root:
			
			if(tab==2)
				//SetDataFolder root:Packages:NIST:VSANS:VCALC:Back
				//Wave det_B
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_B
				Wave det_B=data
				CheckDisplayed /W=VSANS_Data#det_panelsB det_B
				if(V_flag == 0)
					AppendImage/W=VSANS_Data#det_panelsB det_B
//					ModifyImage/W=VSANS_Data#det_panelsB det_B ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsB ''#0 ctab= {*,*,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(50,185,545,620)
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(320,70,430,160)
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(200,70,310,160)
				
				SetActiveSubWindow VSANS_Data#det_panelsB
				SetDataFolder root:
			endif
	
			if(tab==1)
				//SetDataFolder root:Packages:NIST:VSANS:VCALC:Middle
				//Wave det_MR,det_ML,det_MB,det_MT
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_ML
				Wave det_ML=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MR
				Wave det_MR=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MT
				Wave det_MT=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_MB
				Wave det_MB=data
				CheckDisplayed /W=VSANS_Data#det_panelsM det_MR
				if(V_flag == 0)
					AppendImage/W=VSANS_Data#det_panelsM det_MT		//order is important here to get LR on "top" of display
					AppendImage/W=VSANS_Data#det_panelsM det_MB
					AppendImage/W=VSANS_Data#det_panelsM det_ML
					AppendImage/W=VSANS_Data#det_panelsM det_MR
//					ModifyImage/W=VSANS_Data#det_panelsM det_MT ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsM det_MB ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsM det_ML ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsM det_MR ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsM ''#0 ctab= {*,*,ColdWarm,0}		// ''#n means act on the nth image (there are 4)
					ModifyImage/W=VSANS_Data#det_panelsM ''#1 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsM ''#2 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsM ''#3 ctab= {*,*,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(50,185,545,620)
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(440,70,550,160)
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(200,70,310,160)
				
				SetActiveSubWindow VSANS_Data#det_panelsM
				SetDataFolder root:
			endif

			if(tab==0)
				//SetDataFolder root:Packages:NIST:VSANS:VCALC:Front
				//Wave det_FL,det_FR,det_FT,det_FB
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FL
				Wave det_FL=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FR
				Wave det_FR=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FT
				Wave det_FT=data
				SetDataFolder root:Packages:NIST:VSANS:RAW:entry:entry:instrument:detector_FB
				Wave det_FB=data
				CheckDisplayed /W=VSANS_Data#det_panelsF det_FL
				if(V_flag == 0)
					AppendImage/W=VSANS_Data#det_panelsF det_FT
					AppendImage/W=VSANS_Data#det_panelsF det_FB
					AppendImage/W=VSANS_Data#det_panelsF det_FL
					AppendImage/W=VSANS_Data#det_panelsF det_FR
//					ModifyImage/W=VSANS_Data#det_panelsF det_FT ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF det_FB ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF det_FL ctab= {*,*,ColdWarm,0}
//					ModifyImage/W=VSANS_Data#det_panelsF det_FR ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#0 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#1 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#2 ctab= {*,*,ColdWarm,0}
					ModifyImage/W=VSANS_Data#det_panelsF ''#3 ctab= {*,*,ColdWarm,0}
				endif
				MoveSubWindow/W=VSANS_Data#det_panelsF fnum=(50,185,545,620)
				MoveSubWindow/W=VSANS_Data#det_panelsB fnum=(440,70,550,160)
				MoveSubWindow/W=VSANS_Data#det_panelsM fnum=(320,70,430,160)
				
				SetActiveSubWindow VSANS_Data#det_panelsF
				SetDataFolder root:
			endif
			
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// fake click on each tab to populate the data
Function FakeTabClick(tab)
	Variable tab
	
	STRUCT WMTabControlAction tca

	tca.eventCode = 2		//fake mouse up
	tca.tab = tab
	VDataTabProc(tca)
	
	TabControl tab0,win=VSANS_Data,value= tab		//select the proper tab
	return(0)
End

// TODO
//
// move one file number back
//
Function File_m_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO
//
// move one file number forward
//
Function File_p_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//
// button that mimics a click on the tab, cycling through the tabs 0->1->2->0 etc.
// only goes one direction
//
Function Tab_p_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo/W=VSANS_Data tab0
			
			V_Value += 1
			if(V_Value == 3)
				V_Value = 0		//reset to 0
			endif
			FakeTabClick(V_Value)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO
//
// isolates a single panel to allow a better view of the details
// useful for T/B panels which are partially blocked from view
//
// will open a separate graph or panel to display the selected detector
// (lots to do here, depending what is necessary for instrument troubleshooting)
// - like being able to turn corrections on/off and view with different axes (pix, mm, Q)
//
Function IsolateButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO
//
// opens a separate panel with the I(q) representation of the data
// ? controls here to select how the data is processed/grouped/saved, etc.
//
Function IvsQPanelButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO
//
// gets the status of the currently displayed file and dumps it to the panel (not the cmd window)
// - lots to decide here about what is the important stuff to display. There's a lot more information now
//
Function StatusButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// TODO
// toggle the (z) value of the display log/lin
//
Function LogLinButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// which tab is active? does it matter - or do I log-scale everything?
			// log/lin current state is in the S_UserData string (0=linear, 1=log)
			ControlInfo/W=VSANS_Data button_log
			Variable curState,newState
			String newStateStr,newTitleStr
			
			curState = str2num(S_UserData)
			
			if(curState == 0)
				newState = 1
				newStateStr="1"
				newTitleStr = "isLog"
			else
				newState = 0
				newStateStr="0"
				newTitleStr = "isLin"
			endif
			
			// update the button and the global value
			Button button_log,userData=newStateStr,title=newTitleStr
			NVAR state = root:Packages:NIST:VSANS:Globals:gIsLogScale
			state = newState
			
			// on the front:			
			ModifyImage/W=VSANS_Data#det_panelsF ''#0 log=newState
			ModifyImage/W=VSANS_Data#det_panelsF ''#1 log=newState
			ModifyImage/W=VSANS_Data#det_panelsF ''#2 log=newState
			ModifyImage/W=VSANS_Data#det_panelsF ''#3 log=newState
			//on the middle:
			ModifyImage/W=VSANS_Data#det_panelsM ''#0 log=newState
			ModifyImage/W=VSANS_Data#det_panelsM ''#1 log=newState
			ModifyImage/W=VSANS_Data#det_panelsM ''#2 log=newState
			ModifyImage/W=VSANS_Data#det_panelsM ''#3 log=newState
			// on the back:
			ModifyImage/W=VSANS_Data#det_panelsB ''#0 log=newState

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO
// possibly function to "tag" files right here in the disaply with things
// like their intent, or other values that reduction will need, 
Function TagFileButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0, "TagFileButtonProc(ba) unfinished"
			
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//TODO
//
//link this to the beam center finding panel
//
Function BeamCtrButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// TODO
//
// link this slider to the "high" end of the color mapping for whatever is currently displayed
//
// -- see Buttons.ipf for the old SANS implementation
//
Function HiMapSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
			endif
			break
	endswitch

	return 0
End

// TODO
//
// link this slider to the "low" end of the color mapping for whatever is currently displayed
//
// -- see Buttons.ipf for the old SANS implementation
//
Function LowMapSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
			endif
			break
	endswitch

	return 0
End


