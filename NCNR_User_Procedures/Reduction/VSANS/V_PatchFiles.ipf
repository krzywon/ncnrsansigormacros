#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1


//
// Updated for use with VSANS (in process)
// -- currently very crude, and needs to be changed to accomodate the 
//   large number of parameters in the file that may/will need to be patched.
// -- if this turns out to be too crude or too difficult to work with for what 
//   VSANS needs, I may ditch the entire procedure and start fresh
//
// June 2016 SRK
//

// TODOs have been inserted to comment out all of the calls that don't compile and need to be replaced

// TODO
// -- not all of the functions here have been prefixed with "V_", especially the action procedures from the panel
//   so this cannot be opened with the SANS Reduction, or there will be clashes
// -- same file load/reload issue as with other operations that read a field from the file. ANY read requires
//   that the entire file is read in, even just to check and see if it's raw data... then there is a local
//   copy present to confuse matters of what was actually written
//
// -- for the batch entering of fields, when all of the proper beam center values are determined, then
//    all (2 x 9 = 18) of these values will need to be entered in all of the data files that "match" this 
//    "configuration" - however a configuration is to be defined and differentiated from other configurations.
//
// -- there may be other situations where batch entering needs are
//		 different, and this may lead to different interface choices
//
//


//**************************
// Vers. 1.2 092101
//
//procedures required to allow patching of raw SANS data headers
//only a limited number of fields are allowable for changes, although the list could
//be enhanced quite easily, at the expense of a larger, more complex panel
//information for the Patch Panel is stored in the root:Packages:NIST:VSANS:Globals:Patch subfolder
//
// writes changes directly to the raw data headers as requested
// * note that if a data file is currently in a work folder, the (real) header on disk
// will be updated, but the data in the (WORK) folder will not reflect these changes, unless
// the data folder is first cleared and the data is re-loaded
//
//**************************

//main entry procedure for displaying the Patch Panel
//
Proc V_PatchFiles()
	
	DoWindow/F V_Patch_Panel
	If(V_flag == 0)
		V_InitializePatchPanel()
		//draw panel
		V_Patch_Panel()
	Endif
End

//initialization of the panel, creating the necessary data folder and global
//variables if necessary - simultaneously initialize the globals for the Trans
//panel at this time, to make sure they all exist
//
// root:Packages:NIST:VSANS:Globals:
Proc V_InitializePatchPanel()
	//create the global variables needed to run the Patch Panel
	//all are kept in root:Packages:NIST:VSANS:Globals:Patch
	If( ! (DataFolderExists("root:Packages:NIST:VSANS:Globals:Patch"))  )
		//create the data folder and the globals for BOTH the Patch and Trans panels
		NewDataFolder/O root:Packages:NIST:VSANS:Globals:Patch
	Endif
	V_CreatePatchGlobals()		//re-create them every time (so text and radio buttons are correct)
End

//the data folder root:Packages:NIST:VSANS:Globals:Patch must exist
//
Proc V_CreatePatchGlobals()
	//ok, create the globals
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr = "*"
	PathInfo catPathName
	If(V_flag==1)
		String dum = S_path
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = dum
	else
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = "no path selected"
	endif
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = "none"
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS1 = "no file selected"
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS2 = "no file selected"
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS3 = "no box selected"
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS4 = "no file selected"
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS5 = "no file selected"
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS6 = "no file selected"
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV1 =0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV2 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV3 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV4 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV5 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV6 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV7 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV8 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV9 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV10 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV11 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV12 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV13 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV14 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV15 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV16 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV17 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV18 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV19 = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gTransCts = 0
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gRadioVal = 1
End

//button action procedure to select the local path to the folder that
//contains the SANS data
//sets catPathName, updates the path display and the popup of files (in that folder)
//
Function V_PickPathButton(PathButton) : ButtonControl
	String PathButton
	
	//set the global string to the selected pathname
	V_PickPath()
	//set a local copy of the path for Patch
	PathInfo/S catPathName
        String dum = S_path
	if (V_flag == 0)
		//path does not exist - no folder selected
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = "no folder selected"
	else
		String/G root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr = dum
	endif
	
	//Update the pathStr variable box
	ControlUpdate/W=V_Patch_Panel $"PathDisplay"
	
	//then update the popup list
	// (don't update the list - not until someone enters a search critera) -- Jul09
	//
	SetMatchStrProc("",0,"*","")		//this is equivalent to finding everything, typical startup case

End


//returns a list of valid files (raw data, no version numbers, no averaged files)
//that is semicolon delimited, and is suitable for display in a popup menu
//
Function/S xGetValidPatchPopupList()

	//make sure that path exists
	PathInfo catPathName
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif
	
	String newList = ""

	newList = V_GetRawDataFileList()

	//trim list to include only selected files
	SVAR match = root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr
	if(strlen(match) == 0)		//if nothing is entered for a match string, return everything, rather than nothing
		match = "*"
	endif

	newlist = V_MyMatchList(match,newlist,";")
	
	newList = SortList(newList,";",0)
	Return(newList)
End

//returns a list of valid files (raw data, no version numbers, no averaged files)
//that is semicolon delimited, and is suitable for display in a popup menu
//
// Uses Grep to look through the any text in the file, which includes the sample label
// can be very slow across the network, as it re-pops the menu on a selection (since some folks don't hit
// enter when inputing a filter string)
//
// - or -
// a list or range of run numbers
// - or - 
// a SDD (to within 0.001m)
// - or -
// * to get everything
//
// 	NVAR gRadioVal= root:Packages:NIST:VSANS:Globals:Patch:gRadioVal
 // 1== Run # (comma range OK)
 // 2== Grep the text (SLOW)
 // 3== filter by SDD (within 0.001 m)
Function/S GetValidPatchPopupList()

	//make sure that path exists
	PathInfo catPathName
	String path = S_path
	if (V_flag == 0)
		Abort "folder path does not exist - use Pick Path button"
	Endif
	
	String newList = ""

	newList = V_GetRawDataFileList()

	//trim list to include only selected files
	SVAR match = root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr
	if(strlen(match) == 0 || cmpstr(match,"*")==0)		//if nothing or "*" entered for a match string, return everything, rather than nothing
		match = "*"
	// old way, with simply a wildcard
		newlist = V_MyMatchList(match,newlist,";")
		newList = SortList(newList,";",0)
		return(newList)
	endif
	
	//loop through all of the files as needed

	
	String list="",item="",fname,runList="",numStr=""
	Variable ii,num=ItemsInList(newList),val,sdd
	NVAR gRadioVal= root:Packages:NIST:VSANS:Globals:Patch:gRadioVal
	
	// run number list
	if(gRadioVal == 1)
			
		list = V_ExpandNumRanges(match)		//now simply comma delimited
		num=ItemsInList(list,",")
		for(ii=0;ii<num;ii+=1)
			item = StringFromList(ii,list,",")
			val=str2num(item)

			runList += V_GetFileNameFromPathNoSemi(V_FindFileFromRunNumber(val)) + ";"		
		endfor
		newlist = runList
		
	endif
	
	//grep through what text I can find in the VAX binary
	// Grep Note: the \\b sequences limit matches to a word boundary before and after
	// "boondoggle", so "boondoggles" and "aboondoggle" won't match.
	if(gRadioVal == 2)
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, newList , ";")
//			Grep/P=catPathName/Q/E=("(?i)\\b"+match+"\\b") item
			Grep/P=catPathName/Q/E=("(?i)"+match) item
			if( V_value )	// at least one instance was found
//				Print "found ", item,ii
				list += item + ";"
			endif
		endfor

		newList = list
	endif
	
	// SDD
	Variable pos
	String SDDStr=""
	if(gRadioVal == 3)
		pos = strsearch(match, "*", 0)
		if(pos == -1)		//no wildcard
			val = str2num(match)
		else
			val = str2num(match[0,pos-1])
		endif
		
//		print val
		for(ii=0;ii<num;ii+=1)
			item=StringFromList(ii, newList , ";")
			fname = path + item
// TODO -- replace call -- this is hard-wired for "FL"
			sdd = V_getDet_ActualDistance(fname,"FL")
			if(pos == -1)
				//no wildcard
				if(abs(val - sdd) < 0.01	)		//if numerically within 0.01 meter, they're the same
					list += item + ";"
				endif
			else
				//yes, wildcard, try a string match?
				// string match doesn't work -- 1* returns 1m and 13m data
				// round the value (or truncate?)
				
				//SDDStr = num2str(sdd)
				//if(strsearch(SDDStr,match[0,pos-1],0) != -1)
				//	list += item + ";"
				//endif
				
				if(abs(val - round(sdd)) < 0.01	)		//if numerically within 0.01 meter, they're the same
					list += item + ";"
				endif
	
			endif
		endfor
		
		newList = list
	endif

	newList = SortList(newList,";",0)
	Return(newList)
End




// -- no longer refreshes the list - this seems redundant, and can be slow if grepping
//
//updates the popup list when the menu is "popped" so the list is 
//always fresh, then automatically displays the header of the popped file
//value of match string is used in the creation of the list - use * to get
//all valid files
//
Function PatchPopMenuProc(PatchPopup,popNum,popStr) : PopupMenuControl
	String PatchPopup
	Variable popNum
	String popStr

	//change the contents of gPatchList that is displayed
	//based on selected Path, match str, and
	//further trim list to include only RAW SANS files
	//this will exclude version numbers, .AVE, .ABS files, etc. from the popup (which can't be patched)

//	String list = GetValidPatchPopupList()
	
//	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = list
//	ControlUpdate PatchPopup
	ShowHeaderButtonProc("SHButton")
End

//when text is entered in the match string, the popup list is refined to 
//include only the selected files, useful for trimming a lengthy list, or selecting
//a range of files to patch
//only one wildcard (*) is allowed
//
Function SetMatchStrProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	//change the contents of gPatchList that is displayed
	//based on selected Path, match str, and
	//further trim list to include only RAW SANS files
	//this will exclude version numbers, .AVE, .ABS files, etc. from the popup (which can't be patched)
	
	String list = GetValidPatchPopupList()
	
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPatchList = list
	ControlUpdate PatchPopup
	PopupMenu PatchPopup,mode=1
	
	if(strlen(list) > 0)
		ShowHeaderButtonProc("SHButton")
	endif
End


//displays the header of the selected file (top in the popup) when the button is clicked
//sort of a redundant button, since the procedure is automatically called (as if it were
//clicked) when a new file is chosen from the popup
//
Function ShowHeaderButtonProc(SHButton) : ButtonControl
	String SHButton

	//displays (editable) header information about current file in popup control
	//putting the values in the SetVariable displays (resetting the global variables)
	
	//get the popup string
	String partialName, tempName
	Variable ok
	ControlInfo/W=V_Patch_Panel PatchPopup
	If(strlen(S_value)==0 || cmpstr(S_Value,"none")==0)
		//null selection
		Abort "no file selected in popup menu"
	else
		//selection not null
		partialName = S_value
		//Print partialName
	Endif
	//get a valid file based on this partialName and catPathName
	tempName = V_FindValidFilename(partialName)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	
	//make sure the file is really a RAW data file
	ok = V_CheckIfRawData(tempName)
	if (!ok)
		Abort "this file is not recognized as a RAW SANS data file"
	Endif
	
	//Print tempName
	
	ReadHeaderForPatch(tempName)
	
	ControlUpdate/A/W=V_Patch_Panel
	
End

//utility function that polls the checkboxes of the editable parameters
//returns a wave with the yes/no checked state of the boxes
// 0 = not checked (user does NOT want this header value updated)
// 1 = checked (YES, change this value in the header)
//num (input) is a simple check to make sure that the wave is set up properly
//from the calling routine
//
//Function GetCheckBoxesState(w,num)
//	Wave w	   //on return, this wave contains the current state of the checkboxes
//	Variable num
//	
//	if(num != 20)
//		Abort "wrong number of checkboxes GetCheckBoxesState()"
//	Endif
//	ControlInfo checkPS1
//	w[0] = V_value
//	
//	Variable ii
//	String baseStr="checkPV"
//	
//	ii=1
//	do
//		ControlInfo $(baseStr + num2str(ii))
//		w[ii] = V_Value
//		ii+=1
//	while(ii<num)
//	return(0)
//End

//on return, wt is a TEXT wave with the values in the SetVar boxes
//will poll the SetVariable controls to get the new values - will get all the values,
//and let the writing routine decide which ones it will actually use
//num (input) is a simple check to make sure that the wave is set up properly
//from the calling routine
//
//Function GetEditedSetVarBoxes(wt,num)
//	Wave/T wt	   
//	Variable num
//	
//	if(num != 20)
//		Abort "wrong number of checkboxes GetEditedSetVarBoxes()"
//	Endif
//	
//	//pass all as a text wave - so only one wave has to be passed (conversion 2x, though)
//	//global is set to the changed value when entered. read others directly from the control
//	
//	//make sure the text label is exactly 60 characters long, to match VAX field length
//	SVAR dum=root:Packages:NIST:VSANS:Globals:Patch:gPS1
//
////	wt[0] = str60
//	wt[0] = dum			//with Nexus, no need to enforce 60 character field
////	
//	Variable ii
//	String baseStr="PV"
//	ii=1
//	do
//		ControlInfo $(baseStr + num2str(ii))
//		wt[ii] = num2str(V_Value)
//		ii+=1
//	while(ii<num)
//	
//	return(0)	//no error
//End


//simple function to get the string value from the popup list of filenames
//returned string is only the text in the popup, a partial name with no path
//or VAX version number.
//
Function/S GetPatchPopupString()

	String str=""
	
	ControlInfo patchPopup
	If(cmpstr(S_value,"")==0)
		//null selection
		Abort "no file selected in popup menu"
	else
		//selection not null
		str = S_value
		//Print str
	Endif
	
	Return str
End

//Changes (writes to disk!) the specified changes to the (single) file selected in the popup
//reads the checkboxes to determine which (if any) values need to be written
//
Function ChangeHeaderButtonProc(CHButton) : ButtonControl
	String CHButton

	//read the (20) checkboxes to determine what changes to make
	//The order/length of these waves are crucial!, set by nvars	 
	String partialName="", tempName = ""
	Variable ok,nvars = 20,ii
	
//	Make/O/N=(nvars) tempChange
//	Wave w=tempchange
//	GetCheckBoxesState(w,nvars)
	//Print "w[0] = ",w[0]
	
	
//	//Get the current values in each of the fields - to pass to Write() as a textwave
//	Make/O/T/N=(nvars) tempValues
//	Wave/T wt=tempValues
//	//initialize textwave
//	ii=0
//	do
//		wt[ii] = ""
//		ii+=1
//	while(ii<nvars)
//	GetEditedSetVarBoxes(wt,nvars)
	
	//get the popup string
	partialName = GetPatchPopupString()
	
	//get a valid file based on this partialName and catPathName
	tempName = V_FindValidFilename(partialName)
	
	//prepend path to tempName for read routine 
	PathInfo catPathName
	tempName = S_path + tempName
	
	//make sure the file is really a RAW data file
	ok = V_CheckIfRawData(tempName)
	if (!ok)
		Abort "this file is not recognized as a RAW SANS data file"
	Endif
	
	//go write the changes to the file
//	WriteHeaderForPatch(tempName,w,wt)
	WriteHeaderForPatch(tempName)
	
	//clean up wave before leaving
	KillWaves/Z w,wt
	
End


//	ControlInfo checkPS1
//	w[0] = V_value
//	
//	Variable ii
//	String baseStr="checkPV"
//	
//	ii=1
//	do
//		ControlInfo $(baseStr + num2str(ii))
//		w[ii] = V_Value
//		ii+=1
//	while(ii<num)
	
//*****this function actually writes the data to disk*****
//overwrites the specific bytes the the header that are to be changed
//real values are written out mimicking VAX format, so that can be properly
//re-read as raw binary VAX files.
//if any additional fields are to be edited, the exact byte location must be known
//
Function WriteHeaderForPatch(fname)
	String fname
//	Wave change
//	Wave/T textVal
	
	Variable refnum,num
	String textstr

// TODO:
// -- currently I hard-wired a detector choice. This needs to be changed (somehow), with a better interface
//
	ControlInfo popup_0
	String detStr = S_value

// handle strings differently

	ControlInfo checkPS1		//change the sample label ?
	if(V_Value == 1)
		SVAR gPS1 = root:Packages:NIST:VSANS:Globals:Patch:gPS1
		V_writeSampleDescription(fname,gPS1)
	endif
	
	ControlInfo checkPV1
	if(V_Value == 1)		//sample transmission
		ControlInfo PV1
		V_writeSampleTransmission(fname,V_value)
	Endif
	
	ControlInfo checkPV2
	if(V_Value == 1)		//sample thickness
		ControlInfo PV2
		V_writeSampleThickness(fname,V_Value)
	Endif
	
	ControlInfo checkPV5
	if(V_Value == 1)		//attenuator number
		ControlInfo PV5
		V_writeAttenThickness(fname,V_value)
	Endif

	ControlInfo checkPV6		// count time
	if(V_Value == 1)
		ControlInfo PV6
		V_writeCount_time(fname,V_Value)
	Endif

	ControlInfo checkPV7	
	if(V_Value == 1)    //monitor count
		ControlInfo PV7 
		V_writeMonitorCount(fname,V_Value)
	Endif

	ControlInfo checkPV10	
	if(V_Value == 1)      //wavelength
		ControlInfo PV10
		V_writeWavelength(fname,V_Value)
	Endif

	ControlInfo checkPV11		
	if(V_Value == 1)      //wavelength spread
		ControlInfo PV11
		V_writeWavelength_spread(fname,V_Value)
	Endif	

	ControlInfo checkPV14		
	if(V_Value == 1)      //source aperture
		ControlInfo PV14
		textStr = num2str(V_Value)
		V_writeSourceAp_size(fname,textStr)		//this is expecting a string
	Endif
	
	ControlInfo checkPV15		
	if(V_Value == 1)      //sample aperture
		ControlInfo PV15
		V_writeSampleAp2_size(fname,V_Value)		//TODO -- not sure if this is correct call
	Endif

	ControlInfo checkPV16
	if(V_Value == 1)      //source-sam dist
		ControlInfo PV16
// TODO -- replace call
//		WriteSrcToSamDistToHeader(fname,num)
	Endif

	ControlInfo checkPV18
	if(V_Value == 1)      //beamstop diam
		ControlInfo PV18
		V_writeBeamStopC2_size(fname,V_Value)			//TODO depends on which det carriage I'm working with (2) or (3)
	Endif	

	ControlInfo checkPS2		//change the DIV file name?
	if(V_Value == 1)
		SVAR gPS2 = root:Packages:NIST:VSANS:Globals:Patch:gPS2
		V_writeSensitivityFileName(fname,gPS2)
	endif	
	
	ControlInfo checkPS3		//change the sample intent?
	if(V_Value == 1)
		SVAR gPS3 = root:Packages:NIST:VSANS:Globals:Patch:gPS3
		V_writeReductionIntent(fname,gPS3)
	endif	

	
// individual detector values	
	ControlInfo checkPV3
	if(V_Value == 1)		//pixel X
		ControlInfo PV3
		V_writeDet_beam_center_x(fname,detStr,V_Value)	
	Endif
	
	ControlInfo checkPV4
	if(V_Value == 1)		// pixel Y
		ControlInfo PV4
		V_writeDet_beam_center_y(fname,detStr,V_Value)	
	Endif
	
	ControlInfo checkPV17
	if(V_Value == 1)      //det offset
		ControlInfo PV17
		V_writeDet_LateralOffset(fname,detStr,V_Value)		// TODO lateral or vertical offset, based on detStr
	Endif

	ControlInfo checkPV19
	if(V_Value == 1)     //SDD
		ControlInfo PV19
		V_writeDet_distance(fname,detStr,V_Value)	 
	Endif

	ControlInfo checkPV8	
	if(V_Value == 1)     //total detector count
		ControlInfo PV8
		V_writeDet_IntegratedCount(fname,detStr,V_value)		
	Endif


	Return(0)
End

//panel recreation macro for the PatchPanel...
//
Proc V_Patch_Panel()
	PauseUpdate; Silent 1	   // building window...
	NewPanel /W=(519,85,950,688)/K=2 as "Patch Raw VSANS Data Files"
	DoWindow/C V_Patch_Panel
	ModifyPanel cbRGB=(11291,48000,3012)
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv fname= "Courier",fstyle= 1
	DrawText 3,107,"Change?"
	DrawLine 7,30,422,30
	DrawLine 7,288,422,288
	DrawLine 7,199,422,199
	DrawLine 7,378+18,422,378+18
	DrawLine 7,469+18,422,469+18
	
	SetVariable PathDisplay,pos={77,7},size={310,13},title="Path"
	SetVariable PathDisplay,help={"This is the path to the folder that will be used to find the SANS data while patching. If no files appear in the popup, make sure that this folder is set correctly"}
	SetVariable PathDisplay,font="Courier",fSize=10
	SetVariable PathDisplay,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gCatPathStr
	Button PathButton,pos={2,3},size={70,20},proc=PickPathButton,title="Pick Path"
	Button PathButton,help={"Select the folder containing the raw SANS data files"}
	Button helpButton,pos={400,3},size={25,20},proc=ShowPatchHelp,title="?"
	Button helpButton,help={"Show the help file for patching raw data headers"}
	PopupMenu PatchPopup,pos={4,37},size={156,19},proc=PatchPopMenuProc,title="File(s) to Patch"
	PopupMenu PatchPopup,help={"The displayed file is the one that will be edited. The entire list will be edited if \"Change All..\" is selected. \r If no items, or the wrong items appear, click on the popup to refresh. \r List items are selected from the file based on MatchString"}
	PopupMenu PatchPopup,mode=1,popvalue="none",value= #"root:Packages:NIST:VSANS:Globals:Patch:gPatchList"
//	Button SHButton,pos={324,37},size={100,20},proc=ShowHeaderButtonProc,title="Show Header"
//	Button SHButton,help={"This will display the header of the file indicated in the popup menu."}
	Button CHButton,pos={314,37},size={110,20},proc=ChangeHeaderButtonProc,title="Change Header"
	Button CHButton,help={"This will change the checked values (ONLY) in the single file selected in the popup."}
	SetVariable PMStr,pos={6,63},size={174,13},proc=SetMatchStrProc,title="Match String"
	SetVariable PMStr,help={"Enter the search string to narrow the list of files. \"*\" is the wildcard character. After entering, \"pop\" the menu to refresh the file list."}
	SetVariable PMStr,font="Courier",fSize=10
	SetVariable PMStr,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPatchMatchStr
	Button ChAllButton,pos={245,60},size={180,20},proc=ChAllHeadersButtonProc,title="Change All Headers in List"
	Button ChAllButton,help={"This will change the checked values (ONLY) in ALL of the files in the popup list, not just the top file. If the \"change\" checkbox for the item is not checked, nothing will be changed for that item."}
	Button DoneButton,pos={314,85},size={110,20},proc=DoneButtonProc,title="Done Patching"
	Button DoneButton,help={"When done Patching files, this will close this control panel."}
//	Button cat_short,pos={9,485},size={100,20},proc=DoCatShort,title="File Catalog"
//	Button cat_short,help={"Use this button to generate a notebook with file header information. Very useful for identifying files."}
	CheckBox check0,pos={18,80},size={40,15},title="Run #",value= 1,mode=1,proc=MatchCheckProc
	CheckBox check1,pos={78,80},size={40,15},title="Text",value= 0,mode=1,proc=MatchCheckProc
	CheckBox check2,pos={138,80},size={40,15},title="SDD",value= 0,mode=1,proc=MatchCheckProc

	Variable base=111,step=18
	SetVariable PS1,pos={42,base},size={340,13},proc=SetLabelVarProc,title="label"
	SetVariable PS1,help={"Current sample label"},font="Courier",fSize=10
	SetVariable PS1,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPS1
	SetVariable PV1,pos={42,base+step},size={340,13},title="Transmission"
	SetVariable PV1,help={"Current transmission\rvalue"},font="Courier",fSize=10
	SetVariable PV1,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV1
	SetVariable PV2,pos={42,base+2*step},size={340,13},title="Thickness (cm)"
	SetVariable PV2,help={"Current sample thickness, in units of centimeters"}
	SetVariable PV2,font="Courier",fSize=10
	SetVariable PV2,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV2

	SetVariable PV5,pos={42,base+3*step},size={340,13},title="Attenuator number"
	SetVariable PV5,help={"attenuator number present during data collection"}
	SetVariable PV5,font="Courier",fSize=10
	SetVariable PV5,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV5
	SetVariable PV6,pos={42,base+4*step},size={340,13},title="Counting time (s)",font="Courier",fSize=10
	SetVariable PV6,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV6
	SetVariable PV6,help={"total counting time in seconds"}
	SetVariable PV7,pos={42,base+5*step},size={340,13},title="Monitor count",font="Courier",fSize=10
	SetVariable PV7,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV7
	SetVariable PV7,help={"total monitor counts"}

	SetVariable PV10,pos={42,base+6*step},size={340,13},title="Wavelength (A)",font="Courier",fSize=10
	SetVariable PV10,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV10
	SetVariable PV10,help={"neutron wavelength in angstroms"}
	SetVariable PV11,pos={42,base+7*step},size={340,13},title="Wavelength spread (dL/L)",font="Courier",fSize=10
	SetVariable PV11,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV11
	SetVariable PV11,help={"wavelength spread (delta lambda)/lambda"}

	SetVariable PV14,pos={42,base+8*step},size={340,13},title="Source aperture diameter (mm)",font="Courier",fSize=10
	SetVariable PV14,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV14
	SetVariable PV14,help={"source aperture diameter, in millimeters"}
	SetVariable PV15,pos={42,base+9*step},size={340,13},title="Sample aperture diameter (mm)",font="Courier",fSize=10
	SetVariable PV15,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV15
	SetVariable PV15,help={"sample aperture diameter, in millimeters"}
	SetVariable PV16,pos={42,base+10*step},size={340,13},title="Source to sample distance (cm)",font="Courier",fSize=10
	SetVariable PV16,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV16
	SetVariable PV16,help={"Source to sample distance in centimeters"}
	
	SetVariable PV18,pos={42,base+11*step},size={340,13},title="Beamstop diameter (mm)",font="Courier",fSize=10
	SetVariable PV18,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV18
	SetVariable PV18,help={"beamstop diamter, in millimeters (1 inch = 25.4mm)"}
// TODO: add functions for these, make the intent a popup (since it's an enumerated type)
	SetVariable PS2,pos={42,base+12*step},size={340,13},proc=SetLabelVarProc,title="DIV file name"
	SetVariable PS2,help={"DIV file name"},font="Courier",fSize=10
	SetVariable PS2,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPS2
	SetVariable PS3,pos={42,base+13*step},size={340,13},proc=SetLabelVarProc,title="Intent"
	SetVariable PS3,help={"File Intent"},font="Courier",fSize=10
	SetVariable PS3,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPS3
	PopupMenu popup_1,pos={42,base+14*step},size={109,20},title="File intent"
	PopupMenu popup_1,mode=1,popvalue="SCATTER",value= #"\"SCATTER;EMPTY;TRANS;EMPTY BEAM;\""
	
	CheckBox checkPS1,pos={18,base},size={20,20},title=""
	CheckBox checkPS1,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV1,pos={18,base+step},size={20,20},title=""
	CheckBox checkPV1,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV2,pos={18,base+2*step},size={20,20},title=""
	CheckBox checkPV2,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

	CheckBox checkPV5,pos={18,base+3*step},size={20,20},title=""
	CheckBox checkPV5,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV6,pos={18,base+4*step},size={20,20},title=""
	CheckBox checkPV6,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV7,pos={18,base+5*step},size={20,20},title="",value=0
	CheckBox checkPV7,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

	CheckBox checkPV10,pos={18,base+6*step},size={20,20},title="",value=0
	CheckBox checkPV10,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV11,pos={18,base+7*step},size={20,20},title="",value=0
	CheckBox checkPV11,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

	CheckBox checkPV14,pos={18,base+8*step},size={20,20},title="",value=0
	CheckBox checkPV14,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV15,pos={18,base+9*step},size={20,20},title="",value=0
	CheckBox checkPV15,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV16,pos={18,base+10*step},size={20,20},title="",value=0
	CheckBox checkPV16,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

	CheckBox checkPV18,pos={18,base+11*step},size={20,20},title="",value=0
	CheckBox checkPV18,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPS2,pos={18,base+12*step},size={20,20},title="",value=0
	CheckBox checkPS2,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPS3,pos={18,base+13*step},size={20,20},title="",value=0
	CheckBox checkPS3,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0




// put these in a tabbed? section for the 9 different panels
// will it be able to patch all "FL" with the proper values, then all "FR", etc. to batchwise correct files?

	base = base+19*step
	PopupMenu popup_0,pos={30,base-step-10},size={109,20},title="Detector Panel",proc=PatchPopMenuProc
	PopupMenu popup_0,mode=1,popvalue="FL",value= #"\"FL;FR;FT;FB;MR;ML;MT;MB;B;\""

	SetVariable PV3,pos={42,base},size={340,13},title="Beamcenter X"
	SetVariable PV3,help={"Current X-position of the beamcenter, in pixels"}
	SetVariable PV3,font="Courier",fSize=10
	SetVariable PV3,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV3
	SetVariable PV4,pos={42,base+step},size={340,13},title="Beamcenter Y"
	SetVariable PV4,help={"Current Y-position of the beamcenter, in pixels"}
	SetVariable PV4,font="Courier",fSize=10
	SetVariable PV4,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV4


	SetVariable PV17,pos={42,base+2*step},size={340,13},title="Detector offset (mm)",font="Courier",fSize=10
	SetVariable PV17,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV17
	SetVariable PV17,help={"Detector offset, in millimeters"}
	SetVariable PV19,pos={42,base+3*step},size={340,13},title="Sample to detector distance (cm)",font="Courier",fSize=10
	SetVariable PV19,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV19
	SetVariable PV19,help={"sample to detector distance, in centimeters"}
	
	SetVariable PV8,pos={42,base+4*step},size={340,13},title="Detector count",font="Courier",fSize=10
	SetVariable PV8,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV8
	SetVariable PV8,help={"total detector counts"}

		
	CheckBox checkPV3,pos={18,base},size={20,20},title=""
	CheckBox checkPV3,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
	CheckBox checkPV4,pos={18,base+step},size={20,20},title=""
	CheckBox checkPV4,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

	CheckBox checkPV8,pos={18,base+2*step},size={20,20},title="",value=0
	CheckBox checkPV8,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

	CheckBox checkPV17,pos={18,base+3*step},size={20,20},title="",value=0
	CheckBox checkPV17,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

	CheckBox checkPV19,pos={18,base+4*step},size={20,20},title="",value=0
	CheckBox checkPV19,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

//	SetVariable PV9,pos={42,273},size={340,13},title="Trans. det. count",font="Courier",fSize=10
//	SetVariable PV9,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV9
//	SetVariable PV9,help={"Transmission\r detector counts"}
//	SetVariable PV12,pos={42,327},size={340,13},title="Temperature (C)",font="Courier",fSize=10
//	SetVariable PV12,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV12
//	SetVariable PV12,help={"Set point temperature in centigrade"}
//	SetVariable PV13,pos={42,345},size={340,13},title="Magnetic field (G)",font="Courier",fSize=10
//	SetVariable PV13,limits={-Inf,Inf,0},value= root:Packages:NIST:VSANS:Globals:Patch:gPV13
//	SetVariable PV13,help={"magnetic field strength units?"}
//	CheckBox checkPV9,pos={18,270},size={20,20},title="",value=0
//	CheckBox checkPV9,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
//	CheckBox checkPV12,pos={18,324},size={20,20},title="",value=0
//	CheckBox checkPV12,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0
//	CheckBox checkPV13,pos={18,342},size={20,20},title="",value=0
//	CheckBox checkPV13,help={"If checked, the entered value will be written to the data file if either of the \"Change..\" buttons is pressed."},value=0

End


Function MatchCheckProc(name,value)
	String name
	Variable value
	
	NVAR gRadioVal= root:Packages:NIST:VSANS:Globals:Patch:gRadioVal
	
	strswitch (name)
		case "check0":
			gRadioVal= 1
			break
		case "check1":
			gRadioVal= 2
			break
		case "check2":
			gRadioVal= 3
			break
	endswitch
	CheckBox check0,value= gRadioVal==1
	CheckBox check1,value= gRadioVal==2
	CheckBox check2,value= gRadioVal==3
End

//This function will read only the selected values editable in the patch panel
//The values read are passed to the panel through the global variables
//the function WriteHeaderForPatch() MUST mirror this set of reads, or nothing can be updated
//
//fname is the full path:name;vers to open the file
//
Function ReadHeaderForPatch(fname)
	String fname
	
	//assign to the globals for display in the panel

	// TODO -- replace ALL (get) calls below
	// TODO -- verify that these calls are really returning what is expected by the checkbox label
	// -- some are clearly wrong for VSANS
	
	// TODO -- remove the hard-wired detStr. This will require some serious interface thought.
	ControlInfo popup_0
	String detStr = S_value
	
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS1= V_getSampleDescription(fname)

	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV1 = V_getSampleTransmission(fname)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV2 = V_getSampleThickness(fname)

	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV5 = V_getAttenThickness(fname)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV6 = V_getCount_Time(fname)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV7 = V_getMonitorCount(fname)

//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV9 = -999		// TODO no equivalent for VSANS to --getTransDetectorCounts(fname)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV10 = V_getWavelength(fname)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV11 = V_getWavelength_Spread(fname)
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV12 = -999 // TODO no equivalent yet for -- getTemperature(fname)
//	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV13 = -999 // TODO no equivalent yet for -- getFieldStrength(fname)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV14 = str2num(V_getSourceAp_size(fname))
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV15 = V_getSampleAp2_size(fname)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV16 = -999 // TODO no equivalent yet for -- getSourceToSampleDist(fname)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV18 = V_getBeamStopC3_size(fname)

// per detector information
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV3 = V_getDet_beam_center_x(fname,detStr)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV4 = V_getDet_beam_center_y(fname,detStr)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV17 = V_getDet_LateralOffset(fname,detStr)	//TODO lateral vs vertical offset
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV19 = V_getDet_ActualDistance(fname,detStr)
	Variable/G root:Packages:NIST:VSANS:Globals:Patch:gPV8 = V_getDet_IntegratedCount(fname,detStr)
		
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS2= V_getSensitivityFileName(fname)	//DIV file name
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS3= V_getReduction_intent(fname)		//intent
	
	Return 0
End

Function ShowPatchHelp(ctrlName) : ButtonControl
	String ctrlName
//	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Tutorial[Patch File Headers]"
//	if(V_flag !=0)
		DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found"
//	endif
End

//button action procedure to change the selected information (checked values)
//in each file in the popup list. This will change multiple files, and as such,
//the user is given a chance to bail out before the whole list of files
//is modified
//useful for patching a series of runs with the same beamcenters, or transmissions
//
Function ChAllHeadersButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String msg
	msg = "Do you really want to write all of these values to each data file in the popup list? "
	msg += "- clicking NO will leave all files unchanged"
	DoAlert 1,msg
	If(V_flag == 2)
		Abort "no files were changed"
	Endif
	
	//this will change (checked) values in ALL of the headers in the popup list
	SVAR list = root:Packages:NIST:VSANS:Globals:Patch:gPatchList
	Variable numitems,ii
	numitems = ItemsInList(list,";")
	
	if(numitems == 0)
		Abort "no items in list for multiple patch"
	Endif
	
	//read the (6) checkboxes to determine what changes to make
	//The order/length of these waves are crucial!, set by nvars	 
	String partialName="", tempName = ""
	Variable ok,nvars = 20
	
//	Make/O/N=(nvars) tempChange
//	Wave w=tempchange
//	GetCheckBoxesState(w,nvars)
	//Print "w[0] = ",w[0]
	
//	//Get the current values in each of the fields - to pass to Write() as a textwave
//	Make/O/T/N=(nvars) tempValues
//	Wave/T wt=tempValues
//	//initialize textwave
//	ii=0
//	do
//		wt[ii] = ""
//		ii+=1
//	while(ii<nvars)
//	GetEditedSetVarBoxes(wt,nvars)
	
	//loop through all of the files in the list, applying changes as dictated by w and wt waves
	ii=0
	do
		//get current item in the list
		partialName = StringFromList(ii, list, ";")
		   
		//get a valid file based on this partialName and catPathName
		tempName = V_FindValidFilename(partialName)
	
		//prepend path to tempName for read routine 
		PathInfo catPathName
		tempName = S_path + tempName
	
		//make sure the file is really a RAW data file
		ok = V_CheckIfRawData(tempName)
		if (!ok)
		   Print "this file is not recognized as a RAW SANS data file = ",tempName
		else
		   //go write the changes to the file
//		   WriteHeaderForPatch(tempName,w,wt)
		   WriteHeaderForPatch(tempName)
		Endif
		
		ii+=1
	while(ii<numitems)
	
	//clean up wave before leaving
	KillWaves/Z w,wt
		
End


//simple action for button to close the panel
//
// cleans out the RawVSANS folder on closing 
//
Function DoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K V_Patch_Panel

//	V_CleanOutRawVSANS()
// present a progress window
	V_CleanupData_w_Progress(0,1)	
	
	return(0)
End

//resets the global string corresponding to the sample label 
//updates when new text is entered
//
Function SetLabelVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	//reset the global variable to the entered text so that it can be relayed to the 
	//write() routine. Only the TEXT SetVariable control needs to be handled this way
	
	String/G root:Packages:NIST:VSANS:Globals:Patch:gPS1 = varStr

End

