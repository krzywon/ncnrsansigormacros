#pragma rtGlobals=1		// Use modern global access method.

//
// ********
//
//   JAN 2018
//
// TODO:
// x- complete the description of the steps needed...
// Data needs to be reduced to the "COR" level - that means that the 
// PLEX data has been added to work files, and the empty and blocked beam have been
// subtracted off.
// -- but what detector corrections should/ should not be done?
// -- non-linear corrections are not needed, since this will strictly be a per-pixel correction
// -- solid angle?
// -- dead time?
// -- efficiency?
// -- large angle transmission?
//
// we may need to think more carefully about some of these since the front carriage may need to be 
// closer than the nominal 4m distance on SANS that was deemed far enough back to be "safe" from 
// the high angle issues.
//
// x- what about the T/B panels? Since a large chunk of these detectors may be obscured,
//   the normalization will be way off -- and the "active" area will end up much larger 
//   than it should be - since the wings of the detector are mostly zero...
//   ? Can I apply a mask, or will the detectors be set in a different configuration?
//
//




/// DONE:
// x- need a way to view the DIV data (each panel) and see the stats on the values
//  (maybe a simple panel viewer, one-at-a-time, or all 4 as individuals, not on the same scale)

// x- this is the basic renormalization that is done in PRODIV. see that file for all of the 
//    details of how it's used
// x- update to VSANS file locations and data reads
// x- expand this to do a basic renormalization of all 9 panels, and move the data into the 
//    appropriate locations for saving as a DIV file.
// x- (YES, done) what about error propogation? Can I store the error in the data file?
//    Makes a difference if the DIV is not collected for long "enough".
// x- then I need to be able to read the error in (done)



//
// Simple panel to walk through the steps of generating a DIV file
//
Proc DIV_Setup_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1207,593,1444,953)/N=DIV_Setup_Panel/K=1
	DoWindow/C DIV_Setup_Panel
	Button button0,pos={54.00,10.00},size={120.00,20.00},proc=V_DIVSetupButtonProc,title="Setup Folder"
	Button button1,pos={54.00,40.00},size={120.00,20.00},proc=V_DIVClearOldButtonProc,title="Clear Old DIV"
	Button button1_2,pos={54.00,70.00},size={120.00,20.00},proc=V_DIVMaskButtonProc,title="Mask for DIV"

	DrawText 32,130,"Reduce data for one carriage"	
	DrawText 32,200,"Repeat for the other carriage(s)"
	
	Button button2,pos={54.00,145.00},size={120.00,20.00},proc=V_DIVNormalizeButtonProc,title="Normalize+Copy"

	DrawText 32,290,"Once data for both (or 3) carriages\rhas been normalized, save the file"	
	
	Button button3,pos={54.00,300.00},size={120.00,20.00},proc=V_DIVSaveButtonProc,title="Save DIV"
EndMacro



// set up the folder structure for the DIV file to fill in
Function V_DIVSetupButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "Setup_VSANS_DIV_Struct()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// clear out whatever is in the current DIV folder to ensure that it is not 
// accidentally applied during the reduction of the DIV file
//
Function V_DIVClearOldButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			KillDataFolder/Z $"root:Packages:NIST:VSANS:DIV"			//many subfolders, so Kill all
			if(V_flag == 0)		// kill DF was OK
				NewDataFolder root:Packages:NIST:VSANS:DIV
				Print "DIV folder cleared successfully"
			else
				Print "DIV folder in use - could not be cleared"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function V_DIVNormalizeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_NormalizeDIV_proc()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_DIVMaskButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "V_Edit_a_Mask()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_DIVSaveButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "Save_VSANS_DIV_Nexus()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




Proc V_NormalizeDIV_proc(reducedFolderType,carriageStr)
	String reducedFolderType="COR",carriageStr="F"
	
	if (cmpstr(carriageStr,"B")==0)
		V_NormalizeDIV_onePanel(reducedFolderType,"B")
	elseif (cmpstr(carriageStr,"F")==0)
		V_NormalizeDIV_onePanel(reducedFolderType,"FL")
		V_NormalizeDIV_onePanel(reducedFolderType,"FR")
		V_NormalizeDIV_onePanel(reducedFolderType,"FT")
		V_NormalizeDIV_onePanel(reducedFolderType,"FB")
	else
		V_NormalizeDIV_onePanel(reducedFolderType,"ML")
		V_NormalizeDIV_onePanel(reducedFolderType,"MR")
		V_NormalizeDIV_onePanel(reducedFolderType,"MT")
		V_NormalizeDIV_onePanel(reducedFolderType,"MB")	
	endif
	
end


// Normalizes a single panel
// then copies that panel over to the DIV_Struct for later saving
//
// type is the work folder where the (? corrected) data is currently
//
// DONE
// x- data should be copied to some alternate work folder before this step
// x- for T/B detectors, this may not work as intended if the whole detector is not illuminated.
//    How to handle? A mask?
// x- is this the correct calculation of the error? (YES) It should be correct up to this point since the
//    standard reduction has been used, but now the normalization step is a multiplication
//    by a constant (w/no error). Be sure this error transformation is correct. (YES - this is correct, and is
//    what is done in SANS)
//
Function V_NormalizeDIV_onePanel(type,detStr)
	String type,detStr

	Variable ii,totCts,pixelX,pixelY


	Wave w = V_getDetectorDataW(type,detStr)
	Wave w_err = V_getDetectorDataErrW(type,detStr)
//	pixelX = V_getDet_pixel_num_x(type,detStr)
//	pixelY = V_getDet_pixel_num_y(type,detStr)

	// get the mask data
	// 1== mask, 0 == no mask
	Wave maskW = $("root:Packages:NIST:VSANS:MSK:entry:instrument:detector_"+detStr+":data")

// work on a copy of the data and error
	Duplicate/O w w_copy
	Duplicate/O w_err w_err_copy
	
	w_copy = (maskW == 1) ? NaN : w_copy	
	WaveStats/Q/M=1 w_copy
	totCts = V_npnts*V_avg		// does not count the NaN values


	w_copy /= totCts
	w_copy *= V_npnts

	w_err_copy /= totCts
	w_err_copy *= V_npnts

// TODO:
// -- do I want to replace the NaN values with 1 for the DIV (the user will mask the data as
//    needed, and the NaN values may be an issue later...
	w_copy = (numtype(w_copy) == 2) ? 1 : w_copy			//turns 2==NaN into 1
	

// copy the normalized data to the folder to save
	Wave w_norm = $("root:VSANS_DIV_file:entry:instrument:detector_"+detStr+":data")
	Wave w_norm_err = $("root:VSANS_DIV_file:entry:instrument:detector_"+detStr+":linear_data_error")
		
	w_norm = w_copy
	w_norm_err = w_err_copy


	KillWaves/Z w_copy,w_err_copy
	
	return(0)
End


//
// Normalizes each panel independently
// Normalizes in-place, replacing whatever was there
//
// type is the work folder where the (? corrected) data is currently
//
// NOTE (Currently unused. use V_NormalizeDIV_onePanel() instead)
//
// -- data should be copied to some alternate work folder before this step
// -- for T/B detectors, this may not work as intended if the whole detector is not illuminated.
//    How to handle? A mask?
// x- is this the correct calculation of the error? (YES) It should be correct up to this point since the
//    standard reduction has been used, but now the normalization step is a multiplication
//    by a constant (w/no error). Be sure this error transformation is correct. (YES - this is correct, and is
//    what is done in SANS)
//
Function V_NormalizeDIV(type)
	String type

	Variable ii,totCts,pixelX,pixelY
	String detStr

	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave w = V_getDetectorDataW(type,detStr)
		Wave w_err = V_getDetectorDataErrW(type,detStr)
		pixelX = V_getDet_pixel_num_x(type,detStr)
		pixelY = V_getDet_pixel_num_y(type,detStr)

		totCts = sum(w,Inf,-Inf)		//sum all of the data
		
		w /= totCts
		w *= pixelX*pixelY

		w_err /= totCts
		w_err *= pixelX*pixelY
		
	endfor
	
	return(0)
End


// copies an entire work folder, all 9 detectors (at COR level)
// to the DIV structure to write out
//
Function V_CopyDIVToSave(type)
	String type
	
	Variable ii,totCts,pixelX,pixelY
	String detStr
	String topath = "root:VSANS_DIV_file:entry:instrument:detector_"
	String fromPath = "root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"
	
	
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")

		Duplicate/O $(fromPath+detStr+":data") $(toPath+detStr+":data")
		Duplicate/O $(fromPath+detStr+":linear_data_error") $(toPath+detStr+":linear_data_error")
		
	endfor
	
	return(0)
End

//
// copies only the specified panel from a work folder, (at COR level)
// to the DIV structure to write out
//
// used to replace a single panel, or to fill in carriage by carriage.
//
Function V_CopyDIVToSave_OnePanel(type,detStr)
	String type,detStr
	
	Variable ii,totCts,pixelX,pixelY
	String topath = "root:VSANS_DIV_file:entry:instrument:detector_"
	String fromPath = "root:Packages:NIST:VSANS:"+type+":entry:instrument:detector_"
	
	
		Duplicate/O $(fromPath+detStr+":data") $(toPath+detStr+":data")
		Duplicate/O $(fromPath+detStr+":linear_data_error") $(toPath+detStr+":linear_data_error")
			
	return(0)
End





// currently, there are no dummy fill values or attributes for the fake DIV file
//
Proc Setup_VSANS_DIV_Struct()

	// lays out the tree and fills with dummy values
	H_Setup_VSANS_DIV_Structure()
	
	// writes in the attributes
//	H_Fill_VSANS_Attributes()
	
	// fill in with VCALC simulation bits
//	H_Fill_VSANS_wSim()
	
End

Proc Save_VSANS_DIV_Nexus(fileName)
	String fileName="Test_VSANS_DIV_file"

	// save as HDF5 (no attributes saved yet)
	Save_VSANS_file("root:VSANS_DIV_file", fileName+".h5")
	
//	// read in a data file using the gateway-- reads from the home path
//	H_HDF5Gate_Read_Raw(fileName+".h5")
//	
//	// after reading in a "partial" file using the gateway (to generate the xref)
//	// Save the xref to disk (for later use)
//	Save_HDF5___xref("root:"+fileName,"HDF5___xref")
//	
//	// after you've generated the HDF5___xref, load it in and copy it
//	// to the necessary folder location.
//	Copy_HDF5___xref("root:VSANS_DIV_file", "HDF5___xref")
//	
//	// writes out the contents of a data folder using the gateway
//	H_HDF5Gate_Write_Raw("root:VSANS_DIV_file", fileName+".h5")
//
//	// re-load the data file using the gateway-- reads from the home path
//	// now with attributes
//	H_HDF5Gate_Read_Raw(fileName+".h5")
	
End

//////////////  DIV file tests
//
//
//	Make/O/T/N=1	file_name	= "VSANS_DIV_test.h5"
//
// simple generation of a fake div file. for sans, nothing other than the creation date was written to the 
// file header. nothing more is needed (possibly)
//
//
//
// TODO -- correct the number of pixels for the BACK detector
//
Proc H_Setup_VSANS_DIV_Structure()
	
	NewDataFolder/O/S root:VSANS_DIV_file		

	NewDataFolder/O/S root:VSANS_DIV_file:entry	
		Make/O/T/N=1	title	= "This is a DIV file for VSANS: VSANS_DIV"
		Make/O/T/N=1	start_date	= "2017-02-28T08:15:30-5:00"
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument		
			Make/O/T/N=1	name	= "NG3_VSANS"
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_B	
			Make/O/D/N=(680,1656)	data	= 1 
			Make/O/D/N=(680,1656)	linear_data_error	= 0.01
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MR		
			Make/O/D/N=(48,128)	data = 1
			Make/O/D/N=(48,128)	linear_data_error	= 0.01
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_ML		
			Make/O/D/N=(48,128)	data = 1
			Make/O/D/N=(48,128)	linear_data_error	= 0.01
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MT		
			Make/O/D/N=(128,48)	data	= 1
			Make/O/D/N=(128,48)	linear_data_error	= 0.01
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MB		
			Make/O/D/N=(128,48)	data	= 1 
			Make/O/D/N=(128,48)	linear_data_error	= 0.01
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FR		
			Make/O/D/N=(48,128)	data = 1
			Make/O/D/N=(48,128)	linear_data_error	= 0.01
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FL		
			Make/O/D/N=(48,128)	data = 1
			Make/O/D/N=(48,128)	linear_data_error	= 0.01
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FT		
			Make/O/D/N=(128,48)	data	= 1 
			Make/O/D/N=(128,48)	linear_data_error	= 0.01
		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FB		
			Make/O/D/N=(128,48)	data	= 1 
			Make/O/D/N=(128,48)	linear_data_error	= 0.01

//
// version that is NOT perfect, LR detectors are "striped"
//
//	NewDataFolder/O/S root:VSANS_DIV_file:entry	
//		Make/O/T/N=1	title	= "This is a DIV file for VSANS: VSANS_DIV"
//		Make/O/T/N=1	start_date	= "2017-02-28T08:15:30-5:00"
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument		
//			Make/O/T/N=1	name	= "NG3_VSANS"
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_B	
//			Make/O/D/N=(150,150)	data	= 1 + (enoise(0.1))
//			Make/O/D/N=(150,150)	linear_data_error	= 0.01*abs(gnoise(1))
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MR		
//			Make/O/D/N=(48,128)	data
//			data[][0] = 1+enoise(0.1)
//			data[][] = data[p][0]
//			Make/O/D/N=(48,128)	linear_data_error	= 0.01*abs(gnoise(1))
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_ML		
//			Make/O/D/N=(48,128)	data
//			data[][0] = 1+enoise(0.1)
//			data[][] = data[p][0]
//			Make/O/D/N=(48,128)	linear_data_error	= 0.01*abs(gnoise(1))
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MT		
//			Make/O/D/N=(128,48)	data	= 1 + (enoise(0.1))
//			Make/O/D/N=(128,48)	linear_data_error	= 0.01*abs(gnoise(1))
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_MB		
//			Make/O/D/N=(128,48)	data	= 1 + (enoise(0.1))
//			Make/O/D/N=(128,48)	linear_data_error	= 0.01*abs(gnoise(1))
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FR		
//			Make/O/D/N=(48,128)	data
//			data[][0] = 1+enoise(0.1)
//			data[][] = data[p][0]
//			Make/O/D/N=(48,128)	linear_data_error	= 0.01*abs(gnoise(1))
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FL		
//			Make/O/D/N=(48,128)	data
//			data[][0] = 1+enoise(0.1)
//			data[][] = data[p][0]
//			Make/O/D/N=(48,128)	linear_data_error	= 0.01*abs(gnoise(1))
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FT		
//			Make/O/D/N=(128,48)	data	= 1 + (enoise(0.1))
//			Make/O/D/N=(128,48)	linear_data_error	= 0.01*abs(gnoise(1))
//		NewDataFolder/O/S root:VSANS_DIV_file:entry:instrument:detector_FB		
//			Make/O/D/N=(128,48)	data	= 1 + (enoise(0.1))
//			Make/O/D/N=(128,48)	linear_data_error	= 0.01*abs(gnoise(1))
		
		
		// fake, empty folders so that the generic loaders can be used
		NewDataFolder/O root:VSANS_DIV_file:entry:DAS_logs
		NewDataFolder/O root:VSANS_DIV_file:entry:control
		NewDataFolder/O root:VSANS_DIV_file:entry:reduction
		NewDataFolder/O root:VSANS_DIV_file:entry:sample
		NewDataFolder/O root:VSANS_DIV_file:entry:user

			
	SetDataFolder root:

End



//
// simple panel to display the 4 detector panels
//
// TODO:
// -- label panels, axes
// x- any manipulations, stats ?
// x- add an "update" button (to update the status of the data - this may be automatic with an operation)
// -- add a "load DIV" button (to make it easy)
// -- add a "copy" button (to fill move data to STO and SUB)
// x- add a "ratio" button
// x- add a "difference" button
// -- propagate the error in the arithmetic (see WorkFileMath)
// -- un hard-wire the Front carriage from the panel proc

Proc V_Display_DIV_Panels()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(720,45,1530,570)/N=VSANS_DIVPanels/K=1
	DoWindow/C VSANS_DIVPanels
//	ModifyPanel fixedSize=1,noEdit =1


	PopupMenu popup0,pos={17.00,10.00},size={77.00,23.00},proc=V_DispCarriagePopMenuProc,title="Carriage"
	PopupMenu popup0,mode=1,value= #"\"F;M;B;\""
	PopupMenu popup1,pos={134.00,10.00},size={68.00,23.00},proc=V_DispFolderPopMenuProc,title="Folder"
	PopupMenu popup1,mode=1,popvalue="RAW",value= #"\"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;MSK;ADJ;\""
	PopupMenu popup2,pos={246.00,10.00},size={83.00,23.00},proc=V_DispOperationPopMenuProc,title="Operation"
	PopupMenu popup2,mode=1,value= #"\"none;ADJ=STO-SUB;ADJ=STO/SUB;\""
	Button button0,pos={440.00,10.00},size={70.00,20.00},proc=V_DispUpdateButtonProc,title="Update"


//	Display/W=(745,45,945,425)/HOST=# 
	Display/W=(10,45,210,425)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:RAW:entry:instrument:detector_FL:data		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly

	ModifyImage data ctab= {*,*,ColdWarm,0}
	ModifyImage data ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Panel_L
	SetActiveSubwindow ##

//	Display/W=(1300,45,1500,425)/HOST=# 
	Display/W=(565,45,765,425)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:RAW:entry:instrument:detector_FR:data		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage data ctab= {*,*,ColdWarm,0}
	ModifyImage data ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Panel_R
	SetActiveSubwindow ##

//	Display/W=(945,45,1300,235)/HOST=# 
	Display/W=(210,45,565,235)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:RAW:entry:instrument:detector_FT:data		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage data ctab= {*,*,ColdWarm,0}
	ModifyImage data ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Panel_T
	SetActiveSubwindow ##

//	Display/W=(945,235,1300,425)/HOST=# 
	Display/W=(210,235,565,425)/HOST=# 
	AppendImage/T/G=1 :Packages:NIST:VSANS:RAW:entry:instrument:detector_FB:data		//  /G=1 flag prevents interpretation as RGB so 3, 4 slices display correctly
	ModifyImage data ctab= {*,*,ColdWarm,0}
	ModifyImage data ctabAutoscale=3
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	RenameWindow #,Panel_B
	SetActiveSubwindow ##
//

	String/G root:Packages:NIST:VSANS:Globals:gDIVstr0 = "this is the title box0\rwith two lines"
	String/G root:Packages:NIST:VSANS:Globals:gDIVstr1 = "this is the title box1\rwith two lines"
	String/G root:Packages:NIST:VSANS:Globals:gDIVstr2 = "this is the title box2\rwith two lines"
	String/G root:Packages:NIST:VSANS:Globals:gDIVstr3 = "this is the title box3\rwith two lines"
	
	
	TitleBox title0 pos={15,450},size={112,36},title=root:Packages:NIST:VSANS:Globals:gDIVstr0,fSize=11
	TitleBox title1 pos={300,433},size={112,36},title=root:Packages:NIST:VSANS:Globals:gDIVstr1,fSize=11
	TitleBox title2 pos={300,482},size={112,36},title=root:Packages:NIST:VSANS:Globals:gDIVstr2,fSize=11
	TitleBox title3 pos={580,450},size={112,36},title=root:Packages:NIST:VSANS:Globals:gDIVstr3,fSize=11


	V_UpdateDIVStrings()
End


// called by the "update" button
Function V_UpdatePanelDisp()

	ControlInfo popup0
	String carrStr = S_value
	
	ControlInfo popup1
	String folder = S_Value
	
	string tmpStr=""
	Variable isVCALC=0
	if(cmpstr("VCALC",folder)==0)
		isVCALC=1
	endif
		
	// remove everything from each of the 4 panels
	tmpStr = ImageNameList("VSANS_DIVPanels#Panel_L",";")
	if(ItemsInList(tmpStr) > 0)
		do
			RemoveImage /W=VSANS_DIVPanels#Panel_L $(StringFromList(0,tmpStr,";"))		//get 1st item
			tmpStr = ImageNameList("VSANS_DIVPanels#Panel_L",";")								//refresh list
		while(ItemsInList(tmpStr) > 0)
	endif
	
	tmpStr = ImageNameList("VSANS_DIVPanels#Panel_R",";")
	if(ItemsInList(tmpStr) > 0)
		do
			RemoveImage /W=VSANS_DIVPanels#Panel_R $(StringFromList(0,tmpStr,";"))		//get 1st item
			tmpStr = ImageNameList("VSANS_DIVPanels#Panel_R",";")								//refresh list
		while(ItemsInList(tmpStr) > 0)
	endif
	
	tmpStr = ImageNameList("VSANS_DIVPanels#Panel_T",";")
	if(ItemsInList(tmpStr) > 0)
		do
			RemoveImage /W=VSANS_DIVPanels#Panel_T $(StringFromList(0,tmpStr,";"))		//get 1st item
			tmpStr = ImageNameList("VSANS_DIVPanels#Panel_T",";")								//refresh list
		while(ItemsInList(tmpStr) > 0)
	endif
	
	tmpStr = ImageNameList("VSANS_DIVPanels#Panel_B",";")
	if(ItemsInList(tmpStr) > 0)
		do
			RemoveImage /W=VSANS_DIVPanels#Panel_B $(StringFromList(0,tmpStr,";"))		//get 1st item
			tmpStr = ImageNameList("VSANS_DIVPanels#Panel_B",";")								//refresh list
		while(ItemsInList(tmpStr) > 0)
	endif
	

	// append the new image
	// if back, put this in the "left" postion, and nothing else
	if(cmpstr("B",carrStr)==0)
		if(isVCALC)
			AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_L $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+":det_"+carrStr)		
			SetActiveSubwindow VSANS_DIVPanels#Panel_L
			ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
			ModifyImage ''#0 ctabAutoscale=3
		else
			AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_L $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+":data")		
			SetActiveSubwindow VSANS_DIVPanels#Panel_L
			ModifyImage data ctab= {*,*,ColdWarm,0}
			ModifyImage data ctabAutoscale=3	
		endif
		ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
		ModifyGraph mirror=2
		ModifyGraph nticks=4
		ModifyGraph minor=1
		ModifyGraph fSize=9
		ModifyGraph standoff=0
		ModifyGraph tkLblRot(left)=90
		ModifyGraph btLen=3
		ModifyGraph tlOffset=-2
		SetActiveSubwindow ##
		return(0)
	endif
	
//	RemoveImage/Z/W=VSANS_DIVPanels#Panel_L data
	if(isVCALC)
		AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_L $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"L:det_"+carrStr+"L")		
		SetActiveSubwindow VSANS_DIVPanels#Panel_L
		ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage ''#0 ctabAutoscale=3
	else
		AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_L $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"L:data")		
		SetActiveSubwindow VSANS_DIVPanels#Panel_L
		ModifyImage data ctab= {*,*,ColdWarm,0}
		ModifyImage data ctabAutoscale=3	
	endif
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetActiveSubwindow ##


//	RemoveImage/Z/W=VSANS_DIVPanels#Panel_T data
	if(isVCALC)
		AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_T $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"T:det_"+carrStr+"T")		
		SetActiveSubwindow VSANS_DIVPanels#Panel_T
		ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage ''#0 ctabAutoscale=3
	else
		AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_T $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"T:data")		
		SetActiveSubwindow VSANS_DIVPanels#Panel_T
		ModifyImage data ctab= {*,*,ColdWarm,0}
		ModifyImage data ctabAutoscale=3
	endif
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetActiveSubwindow ##
	
//	RemoveImage/Z/W=VSANS_DIVPanels#Panel_B data
	if(isVCALC)
		AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_B $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"B:det_"+carrStr+"B")		
		SetActiveSubwindow VSANS_DIVPanels#Panel_B
		ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage ''#0 ctabAutoscale=3
	else
		AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_B $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"B:data")		
		SetActiveSubwindow VSANS_DIVPanels#Panel_B
		ModifyImage data ctab= {*,*,ColdWarm,0}
		ModifyImage data ctabAutoscale=3
	endif
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetActiveSubwindow ##

//	RemoveImage/Z/W=VSANS_DIVPanels#Panel_R data
	if(isVCALC)
		AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_R $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"R:det_"+carrStr+"R")		
		SetActiveSubwindow VSANS_DIVPanels#Panel_R
		ModifyImage ''#0 ctab= {*,*,ColdWarm,0}
		ModifyImage ''#0 ctabAutoscale=3
	else
		AppendImage/T/G=1/W=VSANS_DIVPanels#Panel_R $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"R:data")		
		SetActiveSubwindow VSANS_DIVPanels#Panel_R
		ModifyImage data ctab= {*,*,ColdWarm,0}
		ModifyImage data ctabAutoscale=3
	endif
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetActiveSubwindow ##

	return(0)
End




Function V_DispFolderPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_DispCarriagePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_DispOperationPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_DispUpdateButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// if there is an operation, do it
			V_DoDIVOperation()
			
			// update the data that is displayed
			V_UpdatePanelDisp()
			
			
			// update the global strings
			V_UpdateDIVStrings()

			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function V_UpdateDIVStrings()

	SVAR gDIVstr0 = root:Packages:NIST:VSANS:Globals:gDIVstr0 
	SVAR gDIVstr1 = root:Packages:NIST:VSANS:Globals:gDIVstr1
	SVAR gDIVstr2 = root:Packages:NIST:VSANS:Globals:gDIVstr2
	SVAR gDIVstr3 = root:Packages:NIST:VSANS:Globals:gDIVstr3
	
	ControlInfo popup0
	String carrStr = S_value
	
	ControlInfo popup1
	String folder = S_Value
	
	String  formatStr="Avg = %g +/- %g\rMin = %g, Max = %g"

	if(cmpstr(carrStr,"B")==0)
		WaveStats/Q $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_B:data")
		sprintf gDIVstr0,formatStr,V_avg,V_sdev,V_min,V_max
		gDIVStr1 = ""
		gDIVStr2 = ""
		gDIVStr3 = ""
		TitleBox title0 title=gDIVstr0
		TitleBox title1 title=gDIVstr1
		TitleBox title2 title=gDIVstr2
		TitleBox title3 title=gDIVstr3
		return(0)
	endif
		
	WaveStats/Q $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"L:data")
	sprintf gDIVstr0,formatStr,V_avg,V_sdev,V_min,V_max
	
	WaveStats/Q $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"T:data")
	sprintf gDIVstr1,formatStr,V_avg,V_sdev,V_min,V_max
	
	WaveStats/Q $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"B:data")
	sprintf gDIVstr2,formatStr,V_avg,V_sdev,V_min,V_max
	
	WaveStats/Q $("root:Packages:NIST:VSANS:"+folder+":entry:instrument:detector_"+carrStr+"R:data")
	sprintf gDIVstr3,formatStr,V_avg,V_sdev,V_min,V_max

	TitleBox title0 title=gDIVstr0
	TitleBox title1 title=gDIVstr1
	TitleBox title2 title=gDIVstr2
	TitleBox title3 title=gDIVstr3
			
	return(0)
end

// if there is no operation called, immediately exit
//
// if there is a simple operation called, do it
// TODO -- if there are more than these two simple operations, a more sophisticated switch will be necessary
//
Function V_DoDIVOperation()

	ControlInfo popup2
	String opStr = S_value
	
	if(cmpstr(opStr,"none")==0)
		return(0)
	endif
	
	ControlInfo popup0
	String carrStr = S_value
	// an operation is desired
	// hard-wired use of STO and SUB, copy results to ADJ
	
	// make sure that something is in ADJ
	// TODO -- reset the values of the data in ADJ, or it will look like the wrong calculation was done
	//V_CopyWorkFolder("STO","ADJ")		// this is a macro, use the function instead
	V_CopyHDFToWorkFolder("STO","ADJ")


	if(cmpstr(carrStr,"B")==0)
		WAVE w_sto_B = $("root:Packages:NIST:VSANS:STO:entry:instrument:detector_B:data")
		WAVE w_sub_B = $("root:Packages:NIST:VSANS:SUB:entry:instrument:detector_B:data")
		Duplicate/O w_sto_B $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_B:data")
		WAVE w_adj_B = $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_B:data") 
	else
		WAVE w_sto_L = $("root:Packages:NIST:VSANS:STO:entry:instrument:detector_"+carrStr+"L:data")
		WAVE w_sub_L = $("root:Packages:NIST:VSANS:SUB:entry:instrument:detector_"+carrStr+"L:data")
		Duplicate/O w_sto_L $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+carrStr+"L:data")
		WAVE w_adj_L = $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+carrStr+"L:data")
	
		WAVE w_sto_R = $("root:Packages:NIST:VSANS:STO:entry:instrument:detector_"+carrStr+"R:data")
		WAVE w_sub_R = $("root:Packages:NIST:VSANS:SUB:entry:instrument:detector_"+carrStr+"R:data")
		Duplicate/O w_sto_R $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+carrStr+"R:data")
		WAVE w_adj_R = $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+carrStr+"R:data")
	
		WAVE w_sto_T = $("root:Packages:NIST:VSANS:STO:entry:instrument:detector_"+carrStr+"T:data")
		WAVE w_sub_T = $("root:Packages:NIST:VSANS:SUB:entry:instrument:detector_"+carrStr+"T:data")
		Duplicate/O w_sto_T $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+carrStr+"T:data")
		WAVE w_adj_T = $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+carrStr+"T:data")
	
		WAVE w_sto_B = $("root:Packages:NIST:VSANS:STO:entry:instrument:detector_"+carrStr+"B:data")
		WAVE w_sub_B = $("root:Packages:NIST:VSANS:SUB:entry:instrument:detector_"+carrStr+"B:data")
		Duplicate/O w_sto_B $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+carrStr+"B:data")
		WAVE w_adj_B = $("root:Packages:NIST:VSANS:ADJ:entry:instrument:detector_"+carrStr+"B:data")
	endif


//handle the back detector separately, then exit
	if(cmpstr(carrStr,"B")==0)
		if(cmpstr(opStr,"ADJ=STO/SUB")==0)
			w_adj_B = w_sto_B/w_sub_B
		else
			w_adj_B = w_sto_B - w_sub_B
		endif
		return(0)
	endif


// M or F carriages	
	if(cmpstr(opStr,"ADJ=STO/SUB")==0)
		w_adj_L = w_sto_L/w_sub_L
		w_adj_R = w_sto_R/w_sub_R
		w_adj_T = w_sto_T/w_sub_T
		w_adj_B = w_sto_B/w_sub_B
	else
		w_adj_L = w_sto_L - w_sub_L
		w_adj_R = w_sto_R - w_sub_R
		w_adj_T = w_sto_T - w_sub_T
		w_adj_B = w_sto_B - w_sub_B
	endif

	return(0)
end


