#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0
#pragma IgorVersion=6.1

//*******************
// Vers 1.0 JAN2016
//
//*******************
//  VSANS Utility procedures for handling of workfiles (each is housed in a separate datafolder)
//
// - adding RAW data to a workfile
// -- **this conversion applies the detector corrections**
//
// - copying workfiles to another folder
//
// - absolute scaling
//
// - (no) the WorkFile Math panel for simple image math (not done - maybe in the future?)
// - 
// - (no) adding work.drk data without normalizing to monitor counts (the case not currently handled)
//***************************

//
// Functions used for manipulation of the local Igor "WORK" folder
// structure as raw data is displayed and processed.
//
//
Strconstant ksDetectorListNoB = "FT;FB;FL;FR;MT;MB;ML;MR;"
Strconstant ksDetectorListAll = "FT;FB;FL;FR;MT;MB;ML;MR;B;"


//
//Entry procedure from main panel
//
Proc CopyWorkFolder(oldType,newType)
	String oldType,newType
	Prompt oldType,"Source WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"
	Prompt newType,"Destination WORK data type",popup,"SAM;EMP;BGD;DIV;COR;CAL;RAW;ABS;STO;SUB;DRK;"

	// data folder "old" will be copied to "new" (either kills/copies or will overwrite)
	CopyHDFToWorkFolder(oldtype,newtype)
End

//
// copy what is needed for data processing (not the DAS_logs)
// from the RawVSANS storage folder to the local WORK folder as needed
//
// TODO -- at what stage do I make copies of data in linear/log forms for data display?
//			-- when do I make the 2D error waves?
//
// TODO - decide what exactly I need to copy over. May be best to copy all, and delete
//       what I know that I don't need
//
// TODO !!! DuplicateDataFolder will FAIL - in the base case of RAW data files, the
//  data is actually in use - so it will fail every time. need an alternate solution. in SANS,
// there are a limited number of waves to carry over, so Dupliate/O is used for rw, tw, data, etc.
//
// TODO : I also need a list of what is generated during processing that may be hanging around - that I need to
//     be sure to get rid of - like the calibration waves, solidAngle, etc.
//
// hdfDF is the name only of the data in storage. May be full file name with extension (clean as needed)
// type is the destination WORK folder for the copy
//
Function CopyHDFToWorkFolder(fromStr,toStr)
	String fromStr,toStr
	
	String fromDF, toDF
	
	// make the DF paths - source and destination
	fromDF = "root:Packages:NIST:VSANS:"+fromStr
	toDF = "root:Packages:NIST:VSANS:"+toStr
	
//	// make a copy of the file name for my own use, since it's not in the file
//	String/G $(toDF+":file_name") = root:
	
	// copy the folders
	KillDataFolder/Z $toDF			//DuplicateDataFolder will not overwrite, so Kill
	
	if(V_flag == 0)		// kill DF was OK
		DuplicateDataFolder $("root:Packages:NIST:VSANS:"+fromStr),$("root:Packages:NIST:VSANS:"+toStr)
		
		// I can delete these if they came along with RAW
		//   DAS_logs
		//   top-level copies of data (duplicate links)
		KillDataFolder/Z $(toDF+":entry:entry:DAS_logs")
		KillDataFolder/Z $(toDF+":entry:entry:data")
		KillDataFolder/Z $(toDF+":entry:entry:data_B")
		KillDataFolder/Z $(toDF+":entry:entry:data_ML")
		KillDataFolder/Z $(toDF+":entry:entry:data_MR")
		KillDataFolder/Z $(toDF+":entry:entry:data_MT")
		KillDataFolder/Z $(toDF+":entry:entry:data_MB")
		KillDataFolder/Z $(toDF+":entry:entry:data_FL")
		KillDataFolder/Z $(toDF+":entry:entry:data_FR")
		KillDataFolder/Z $(toDF+":entry:entry:data_FT")
		KillDataFolder/Z $(toDF+":entry:entry:data_FB")

		return(0)
	else
		// need to do this the hard way, duplicate/O recursively
		// see V_CopyToWorkFolder()
		
		// everything on the top level
		V_DuplicateDataFolder($(fromDF+":entry:entry"),fromStr,toStr,0,"",0)	//no recursion here
		// control
		V_DuplicateDataFolder($(fromDF+":entry:entry:control"),fromStr,toStr,0,"",1)	//yes recursion here
		// instrument
		V_DuplicateDataFolder($(fromDF+":entry:entry:instrument"),fromStr,toStr,0,"",1)	//yes recursion here
		// reduction
		V_DuplicateDataFolder($(fromDF+":entry:entry:reduction"),fromStr,toStr,0,"",1)	//yes recursion here
		// sample
		V_DuplicateDataFolder($(fromDF+":entry:entry:sample"),fromStr,toStr,0,"",1)	//yes recursion here

	endif	
	
	return(0)
end


////////
// see the help entry for IndexedDir for help on (possibly) how to do this faster
// -- see the function Function ScanDirectories(pathName, printDirNames)
//


// from IgorExchange On July 17th, 2011 jtigor
// started from "Recursively List Data Folder Contents"
// Posted July 15th, 2011 by hrodstein
//
//
//
Proc V_CopyWorkFolderTest(dataFolderStr, fromStr, toStr, level, sNBName, recurse)
	String dataFolderStr="root:Packages:NIST:VSANS:RAW"
	String fromStr = "RAW"
	String toStr="SAM"
	Variable level=0
	String sNBName="DataFolderTree"
	Variable recurse = 1
	
	V_DuplicateDataFolder($dataFolderStr, fromStr, toStr, level, sNBName, recurse)


end

// ListDataFolder(dfr, level)
// Recursively lists objects in data folder.
// Pass data folder path for dfr and 0 for level.
// pass level == 0 for the first call
//  sNBName = "" prints nothing. any name will generate a notebook
//
// recurse == 0 will do only the specified folder, anything else will recurse all levels
// toStr is the string name of the top-level folder only, not the full path
//
//
Function V_DuplicateDataFolder(dfr, fromStr, toStr, level, sNBName,recurse)
	DFREF dfr
	String fromStr
	String toStr
	Variable level			// Pass 0 to start
 	String sNBName
 	Variable recurse
 
	String name
	String dfName
 	String sString
 	
 	String toDF = ""
 
	if (level == 0)		// this is the data folder, generate if needed in the destination
		name = GetDataFolder(1, dfr)
//		sPrintf sString, "%s (data folder)\r", name
		toDF = ReplaceString(fromStr,name,toStr,1)		// case-sensitive replace
		sprintf sString, "NewDataFolder/O %s\r",toDF
		NewDataFolder/O $(RemoveEnding(toDF,":"))			// remove trailing semicolon if it's there
		
		V_WriteBrowserInfo(sString, 1, sNBName)
	endif
 
 	dfName = GetDataFolder(1, dfr)
 	toDF = ReplaceString(fromStr,dfName,toStr,1)		// case-sensitive replace
	Variable i
 
	String indentStr = "\t"
	for(i=0; i<level; i+=1)
		indentStr += "\t"
	endfor
 
	Variable numWaves = CountObjectsDFR(dfr, 1)
	for(i=0; i<numWaves; i+=1)
		name = GetIndexedObjNameDFR(dfr, 1, i)
		//
		// wave type does not matter now. Duplicate does not care
		//
		sPrintf sString, "Duplicate/O  %s,  %s\r",dfName+name,toDF+name
		Duplicate/O $(dfName+name),$(toDF+name)
		
		V_WriteBrowserInfo(sString, 2, sNBName)
	endfor	
 
	Variable numNumericVariables = CountObjectsDFR(dfr, 2)	
	for(i=0; i<numNumericVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 2, i)
		sPrintf sString, "%s%s (numeric variable)\r", indentStr, name
		V_WriteBrowserInfo(sString, 3, sNBName)
	endfor	
 
	Variable numStringVariables = CountObjectsDFR(dfr, 3)	
	for(i=0; i<numStringVariables; i+=1)
		name = GetIndexedObjNameDFR(dfr, 3, i)
		sPrintf sString, "%s%s (string variable)\r", indentStr, name
		V_WriteBrowserInfo(sString, 4, sNBName)
	endfor	

	if(recurse) 
		Variable numDataFolders = CountObjectsDFR(dfr, 4)	
		for(i=0; i<numDataFolders; i+=1)
			name = GetIndexedObjNameDFR(dfr, 4, i)
//			sPrintf sString, "%s%s (data folder)\r", indentStr, name
			 dfName = GetDataFolder(1, dfr)
			 
			toDF = ReplaceString(fromStr,dfName,toStr,1)		// case-sensitive replace
			sprintf sString, "NewDataFolder/O %s\r",toDF+name
			NewDataFolder/O $(toDF+name)
			
			
			V_WriteBrowserInfo(sString, 1, sNBName)
			DFREF childDFR = dfr:$(name)
			V_DuplicateDataFolder(childDFR, fromStr, toStr, level+1, sNBName, recurse)
		endfor	
	endif
	 
//when finished walking tree, save as RTF with dialog	
//	if(level == 0 && strlen(sNBName) != 0)
//		SaveNotebook /I /S=4  $sNBName
//	endif
End
 
Function V_WriteBrowserInfo(sString, vType, sNBName)
	String sString
	Variable vType
	String sNBName
 
	if(strlen(sNBName) == 0)
//		print sString
		return 0
	endif
	DoWindow $sNBName
	if(V_flag != 1)
		NewNoteBook/F=0 /N=$sNBName /V=1 as sNBName
	else
		DoWindow/F $sNBName
	endif
	Notebook $sNBName selection={endOfFile, endOfFile}
	if(vType == 1)		// a data folder
//		Notebook $sNBName fstyle=1
		Notebook $sNBName text=sString
//		Notebook $sNBName fstyle=-1
	else
		Notebook $sNBName text=sString	
	endif
 
End

///////////////////////////////


//
// given the folder, duplicate the data -> linear_data and generate the error
// TODO
// -- do I want to use different names here? If it turns out that I don't need to drag a copy of
//    the data around as "linear_data", then I can eliminate that, and rename the error wave
// -- be sure the data is either properly written as 2D in the file, or converted to 2D before
//    duplicating here
// -- ? do I recast to DP here. Probably necessary since I'm doing a DP calculation, but Redimension
//    is done in the Raw_to_Work step too. very confusing.
Function V_MakeDataError(folderStr)
	String folderStr
	
	SetDataFolder $folderStr
	Wave data=data
	Duplicate/O data linear_data			// at this point, the data is still the raw data, and is linear_data
	
	// proper error for counting statistics, good for low count values too
	// rather than just sqrt(n)
	// see N. Gehrels, Astrophys. J., 303 (1986) 336-346, equation (7)
	// for S = 1 in eq (7), this corresponds to one sigma error bars
	Duplicate/O linear_data linear_data_error
	linear_data_error = 1 + sqrt(linear_data + 0.75)				
	//
	
	SetDataFolder root:
	return(0)
End


/////////////////////



//testing procedure
// TODO -- can't duplicate this with another proceudre, but if I change the name of the variable
//   "newType" to "type", then when Raw_to_work() gets to CopyHDFToWorkFolder(), the KillDataFolder/Z
//   line fails (but reports no error), then DuplicateDataFolder fails, and reports an error. Trying
//   to simplify this condition, I can't duplicate the error for WM...
Macro Convert_to_Workfile(newtype, doadd)
	String newtype,doadd
	Prompt newtype,"WORK data type",popup,"SAM;EMP;BGD;ADJ;"
	Prompt doadd,"Add to current WORK contents?",popup,"No;Yes;"
	
	//macro will take whatever is in RAW folder and "ADD" it to the folder specified
	//in the popup menu
	
	//"add" = yes/no, don't add to previous runs
	//switch here - two separate functions to avoid (my) confusion
	Variable err// = Raw_to_work(newtype)
	if(cmpstr(doadd,"No")==0)
		//don't add to prev work contents, copy RAW contents to work and convert
		err = Raw_to_work(newtype)
	else
		//yes, add RAW to the current work folder contents
		Abort "Adding RAW data files is currently unsupported"
		err = Add_raw_to_work(newtype)
	endif
	
	String newTitle = "WORK_"+newtype
	DoWindow/F VSANS_Data
	DoWindow/T VSANS_Data, newTitle
	KillStrings/Z newTitle
	
	//need to update the display with "data" from the correct dataFolder
	UpdateDisplayInformation(newtype)
	
End


//
// THIS IS THE MAJOR ROUTINE TO APPLY DATA CORRECTIONS
// 
//will copy the current contents of the RAW folder to the newType work folder
//and do the geometric corrections and normalization to monitor counts
//(the function Add_Raw_to_work(type) adds multiple runs together - and is LOW priority)
//
//the current display type is updated to newType (global)
//
Function Raw_to_work(newType)
	String newType
	
	Variable deadTime,defmon,total_mon,total_det,total_trn,total_numruns,total_rtime
	Variable ii,jj,itim,cntrate,dscale,scale,uscale
	String destPath
	
	String fname = newType
	String detStr
	Variable ctTime

	//initialize values before normalization
	total_mon=0
	total_det=0
	total_trn=0
	total_numruns=0
	total_rtime=0
	
	//Not adding multiple runs, so wipe out the old contents of the work folder and 
	// replace with the contents of raw

	destPath = "root:Packages:NIST:VSANS:" + newType
	
	//copy from current dir (RAW) to work, defined by newType
	CopyHDFToWorkFolder("RAW",newType)
	
	// now work with the waves from the destination folder.	
	
	// apply corrections ---
	// switches to control what is done, don't do the transmission correction for the BGD measurement
	// start with the DIV correction, before conversion to mm
	// then do all of the other corrections, order doesn't matter.
	// rescaling to default monitor counts however, must be LAST.

// each correction must loop over each detector. tedious.

	// (0) Redimension the data waves in the destination folder
	//     so that they are DP, not integer
	// TODO
	// -- currently only redimensioning the data and linear_data_error - What else???
	//
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave w = V_getDetectorDataW(fname,detStr)
		Wave w_err = V_getDetectorDataErrW(fname,detStr)
		Redimension/D w,w_err
	endfor
	
	
	// (1) DIV correction
	// do this in terms of pixels. 
	// TODO : This must also exist at the time the first work folder is generated.
	//   So it must be in the user folder at the start of the experiment, and defined.
	NVAR gDoDIVCor = root:Packages:NIST:VSANS:Globals:gDoDIVCor
	if (gDoDIVCor == 1)
		// need extra check here for file existence
		// if not in DIV folder, load.
		// if unable to load, skip correction and report error (Alert?) (Ask to Load?)
		
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			Wave w = V_getDetectorDataW(fname,detStr)
			Wave w_err = V_getDetectorDataErrW(fname,detStr)
			Print "Doing DIV correction for "+ detStr
			DIVCorrection(w,w_err,detStr,newType)
		endfor
	else
		Print "DIV correction not done"		// not an error since correction was unchecked
	endif
	
	// (2) non-linear correction	
	NVAR gDoNonLinearCor = root:Packages:NIST:VSANS:Globals:gDoNonLinearCor
	// generate a distance matrix for each of the detectors
	if (gDoNonLinearCor == 1)
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			Wave w = V_getDetectorDataW(fname,detStr)
			Wave w_err = V_getDetectorDataErrW(fname,detStr)
			Wave w_calib = V_getDetTube_spatialCalib(fname,detStr)
			Print "Doing Non-linear correction for "+ detStr
//			NonLinearCorrection(fill this in)
			
		endfor
	else
		Print "Non-linear correction not done"
	endif
	
	// (3) solid angle correction
	NVAR gDoSolidAngleCor = root:Packages:NIST:VSANS:Globals:gDoSolidAngleCor
	if (gDoSolidAngleCor == 1)
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			Wave w = V_getDetectorDataW(fname,detStr)
			Wave w_err = V_getDetectorDataErrW(fname,detStr)
			Wave w_dt = V_getDetector_deadtime(fname,detStr)
			Print "Doing Solid Angle correction for "+ detStr
//			SolidAngleCorrection(fill this in)
			
		endfor
	else
		Print "Solid Angle correction not done"
	endif	
	
	// (4) dead time correction
	// TODO: -- remove the hard-wired test
	// -- test for correct operation
	// -- loop over all of the detectors
	// -- B detector is a special case (do separately, then loop over NoB)
	NVAR gDoDeadTimeCor = root:Packages:NIST:VSANS:Globals:gDoDeadTimeCor
	ctTime = V_getCount_time(fname)
	if (gDoDeadTimeCor == 1)
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			Wave w = V_getDetectorDataW(fname,detStr)
			Wave w_err = V_getDetectorDataErrW(fname,detStr)
			Wave w_dt = V_getDetector_deadtime(fname,detStr)
			Print "Doing DeadTime correction for "+ detStr
//			DeadTimeCorrectionTubes(w,w_err,w_dt,ctTime)
				//deadtime corrections
//	itim = integersread[2]
//	cntrate = sum(data,-inf,inf)/itim		//use sum of detector counts rather than scaler value
//	//TODO - do correct dead time correction for tubes
//	deadtime = 1//DetectorDeadtime(textread[3],textread[9],dateAndTimeStr=textRead[1],dtime=realsRead[48])	//pick the correct deadtime
//	dscale = 1/(1-deadTime*cntrate)
//	
	
// dead time correction
//	data *= dscale		//deadtime correction for everyone else, including NCNR
//	data_err *= dscale

		endfor
	else
		Print "Dead Time correction not done"
	endif	
	
	// (5) angle-dependent tube shadowing
	NVAR gDoTubeShadowCor = root:Packages:NIST:VSANS:Globals:gDoTubeShadowCor
	if (gDoTubeShadowCor == 1)
	
	else
		Print "Tube shadowing correction not done"
	endif	
		
	// (6) angle dependent transmission correction
	NVAR gDoTrans = root:Packages:NIST:VSANS:Globals:gDoTransmissionCor
	if (gDoTrans == 1)
		for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
			detStr = StringFromList(ii, ksDetectorListAll, ";")
			Wave w = V_getDetectorDataW(fname,detStr)
			Wave w_err = V_getDetectorDataErrW(fname,detStr)
			Wave w_dt = V_getDetector_deadtime(fname,detStr)
			Print "Doing Large-angle transmission correction for "+ detStr
//			TransmissionCorrection(fill this in)
			
		endfor
	else
		Print "Sample Transmission correction not done"
	endif	
	
	// (7) normalize to default monitor counts
	// TODO -- each detector is rescaled separately, but the rescaling factor is global (only one monitor!)
	// TODO -- but there are TWO monitors - so how to switch?
	// TODO -- what do I really need to save?
	defmon=1e8			//default monitor counts
	for(ii=0;ii<ItemsInList(ksDetectorListAll);ii+=1)
		detStr = StringFromList(ii, ksDetectorListAll, ";")
		Wave w = V_getDetectorDataW(fname,detStr)
		Wave w_err = V_getDetectorDataErrW(fname,detStr)
		Variable monCt = V_getBeamMonNormData(fname)
		Print "Doing monitor normalization for "+ detStr
//			MonitorNormalization(fill this in)
	//scale the data to the default montor counts
	
	// TODO -- un-comment these three lines once monitor counts are reasonable - currently monCt = 9!!!
//		scale = defmon/monCt
//		w *= scale
//		w_err *= scale		//assumes total monitor count is so large there is essentially no error

// TODO
// -- to write back to the local value, get the wave reference rather than the value, then I can 
//    re-assign the value directly, rather than this method (which is not terrible)	
		// V_getBeamMonNormSaved_count()
		// save the true monitor counts? save the scaling factor?
		String path = "entry:instrument:beam_monitor_norm:saved_count"
		Wave/Z savW = $("root:Packages:NIST:VSANS:"+fname+":entry:"+path)
		savW[0] = scale
	endfor
	
	
	// (not done) angle dependent efficiency correction
	NVAR doEfficiency = root:Packages:NIST:VSANS:Globals:gDoDetectorEffCor

	
// this function, in the past did the non-linear, solid angle, transmission, and efficiency corrections all at once
//	DetCorr(data,data_err,realsread,doEfficiency,doTrans)		//the parameters are waves, and will be changed by the function


	
	//update totals to put in the work header (at the end of the function)
//	total_mon += realsread[0]
//
//	total_det += dscale*realsread[2]
//
//	total_trn += realsread[39]
//	total_rtime += integersread[2]
//	total_numruns +=1
//	

	//all is done, except for the bookkeeping, updating the header information in the work folder

//	integersread[3] = total_numruns						//numruns = 1
//	realsread[1] = total_mon			//save the true monitor count
//	realsread[0] = defmon					//monitor ct = defmon
//	realsread[2] = scale*total_det			//scaled detector counts
//	
	//reset the current displaytype to "newtype"
	String/G root:Packages:NIST:VSANS:Globals:gCurDispType=newType
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return(0)
End


//will "ADD" the current contents of the RAW folder to the newType work folder
//and will ADD the RAW contents to the existing content of the newType folder
// - used when adding multiple runs together
//(the function Raw_to_work(type) makes a fresh workfile)
//
//the current display type is updated to newType (global)
Function Add_raw_to_work(newType)
	String newType
	
	// NEW OCT 2014
	// this corrects for adding raw data files with different attenuation	
	// does nothing if the attenuation of RAW and destination are the same
	NVAR doAdjustRAW_Atten = root:Packages:NIST:gDoAdjustRAW_Atten
	if(doAdjustRAW_Atten)
		Adjust_RAW_Attenuation(newType)
	endif
	
	String destPath=""
	
	// if the desired workfile doesn't exist, let the user know, and just make a new one
	if(WaveExists($("root:Packages:NIST:"+newType + ":data")) == 0)
		Print "There is no old work file to add to - a new one will be created"
		//call Raw_to_work(), then return from this function
		Raw_to_Work(newType)
		Return(0)		//does not generate an error - a single file was converted to work.newtype
	Endif
	
	NVAR pixelsX = root:myGlobals:gNPixelsX
	NVAR pixelsY = root:myGlobals:gNPixelsY
	
	//now make references to data in newType folder
	DestPath="root:Packages:NIST:"+newType	
	WAVE data=$(destPath +":linear_data")			// these wave references point to the EXISTING work data
	WAVE data_copy=$(destPath +":data")			// these wave references point to the EXISTING work data
	WAVE dest_data_err=$(destPath +":linear_data_error")			// these wave references point to the EXISTING work data
	WAVE/T textread=$(destPath + ":textread")
	WAVE integersread=$(destPath + ":integersread")
	WAVE realsread=$(destPath + ":realsread")
	
	Variable deadTime,defmon,total_mon,total_det,total_trn,total_numruns,total_rtime
	Variable ii,jj,itim,cntrate,dscale,scale,uscale,wrk_beamx,wrk_beamy,xshift,yshift


	defmon=1e8			//default monitor counts
	
	//Yes, add to previous run(s) in work, that does exist
	//use the actual monitor count run.savmon rather than the normalized monitor count
	//in run.moncnt and unscale the work data
	
	total_mon = realsread[1]	//saved monitor count
	uscale = total_mon/defmon		//unscaling factor
	total_det = uscale*realsread[2]		//unscaled detector count
	total_trn = uscale*realsread[39]	//unscaled trans det count
	total_numruns = integersread[3]	//number of runs in workfile
	total_rtime = integersread[2]		//total counting time in workfile
	//retrieve workfile beamcenter
	wrk_beamx = realsread[16]
	wrk_beamy = realsread[17]
	//unscale the workfile data in "newType"
	//
	//check for log-scaling and adjust if necessary
	// should not be needed now - using display flag instead
//	ConvertFolderToLinearScale(newType)
	//
	//then unscale the data array
	data *= uscale
	dest_data_err *= uscale
	
	//DetCorr() has not been applied to the data in RAW , do it now in a local reference to the raw data
	WAVE raw_data = $"root:Packages:NIST:RAW:linear_data"
	WAVE raw_data_err = $"root:Packages:NIST:RAW:linear_data_error"
	WAVE raw_reals =  $"root:Packages:NIST:RAW:realsread"
	WAVE/T raw_text = $"root:Packages:NIST:RAW:textread"
	WAVE raw_ints = $"root:Packages:NIST:RAW:integersread"
	
	//check for log-scaling of the raw data - make sure it's linear
	// should not be needed now - using display flag instead
//	ConvertFolderToLinearScale("RAW")
	
	// switches to control what is done, don't do the transmission correction for the BGD measurement
	NVAR doEfficiency = root:Packages:NIST:gDoDetectorEffCorr
	NVAR gDoTrans = root:Packages:NIST:gDoTransmissionCorr
	Variable doTrans = gDoTrans
	if(cmpstr("BGD",newtype) == 0)
		doTrans = 0		//skip the trans correction for the BGD file but don't change the value of the global
	endif	
	
	DetCorr(raw_data,raw_data_err,raw_reals,doEfficiency,doTrans)	//applies correction to raw_data, and overwrites it
	
	//deadtime corrections to raw data
	// TODO - do the tube correction for dead time now
	deadTime = 1//DetectorDeadtime(raw_text[3],raw_text[9],dateAndTimeStr=raw_text[1],dtime=raw_reals[48])		//pick the correct detector deadtime, switch on date too
	itim = raw_ints[2]
	cntrate = sum(raw_data,-inf,inf)/itim		//080802 use data sum, rather than scaler value
	dscale = 1/(1-deadTime*cntrate)

#if (exists("ILL_D22")==6)
	Variable tubeSum
	// for D22 detector might need to use cntrate/128 as it is the tube response
	for(ii=0;ii<pixelsX;ii+=1)
		//sum the counts in each tube
		tubeSum = 0
		for(jj=0;jj<pixelsY;jj+=1)
			tubeSum += data[jj][ii]
		endfor
		// countrate in tube ii
		cntrate = tubeSum/itim
		// deadtime scaling in tube ii
		dscale = 1/(1-deadTime*cntrate)
		// multiply data[ii][] by the dead time
		raw_data[][ii] *= dscale
		raw_data_err[][ii] *= dscale
	endfor
#else
	// dead time correction on all other RAW data, including NCNR
	raw_data *= dscale
	raw_data_err *= dscale
#endif

	//update totals by adding RAW values to the local ones (write to work header at end of function)
	total_mon += raw_reals[0]

	total_det += dscale*raw_reals[2]

	total_trn += raw_reals[39]
	total_rtime += raw_ints[2]
	total_numruns +=1
	
	//do the beamcenter shifting if there is a mismatch
	//and then add the two data sets together, changing "data" since it is the workfile data
	xshift = raw_reals[16] - wrk_beamx
	yshift = raw_reals[17] - wrk_beamy
	
	If((xshift != 0) || (yshift != 0))
		DoAlert 1,"Do you want to ignore the beam center mismatch?"
		if(V_flag==1)
			xshift=0
			yshift=0
		endif
	endif
	
	If((xshift == 0) && (yshift == 0))		//no shift, just add them
		data += raw_data		//deadtime correction has already been done to the raw data
		dest_data_err = sqrt(dest_data_err^2 + raw_data_err^2)			// error of the sum
	Endif
	
	//scale the data to the default montor counts
	scale = defmon/total_mon
	data *= scale
	dest_data_err *= scale
	
	// keep "data" and linear_data in sync in the destination folder
	data_copy = data
	
	//all is done, except for the bookkeeping of updating the header info in the work folder
	textread[1] = date() + " " + time()		//date + time stamp
	integersread[3] = total_numruns						//numruns = more than one
	realsread[1] = total_mon			//save the true monitor count
	realsread[0] = defmon					//monitor ct = defmon
	integersread[2] = total_rtime			// total counting time
	realsread[2] = scale*total_det			//scaled detector counts
	realsread[39] = scale*total_trn			//scaled transmission counts
	
	//Add the added raw filename to the list of files in the workfile
	String newfile = ";" + raw_text[0]
	SVAR oldList = $(destPath + ":fileList")
	String/G $(destPath + ":fileList") = oldList + newfile
	
	//reset the current displaytype to "newtype"
	String/G root:myGlobals:gDataDisplayType=newType
	
	//return to root folder (redundant)
	SetDataFolder root:
	
	Return(0)
End


//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function Raw_to_Work_NoNorm(type)
	String type
	
	WAVE reals=$("root:Packages:NIST:RAW:realsread")
	reals[1]=1		//true monitor counts, still in raw
	Raw_to_work(type)
	//data is now in "type" folder
	WAVE data=$("root:Packages:NIST:"+type+":linear_data")
	WAVE data_copy=$("root:Packages:NIST:"+type+":data")
	WAVE data_err=$("root:Packages:NIST:"+type+":linear_data_error")
	WAVE new_reals=$("root:Packages:NIST:"+type+":realsread")
	
	Variable norm_mon,tot_mon,scale
	
	norm_mon = new_reals[0]		//should be 1e8
	tot_mon = new_reals[1]		//should be 1
	scale= norm_mon/tot_mon
	
	data /= scale		//unscale the data
	data_err /= scale
	
	// to keep "data" and linear_data in sync
	data_copy = data
	
	return(0)
End

//used for adding DRK (beam shutter CLOSED) data to a workfile
//force the monitor count to 1, since it's irrelevant
// run data through normal "add" step, then unscale default monitor counts
//to get the data back on a simple time basis
//
Function Add_Raw_to_Work_NoNorm(type)
	String type
	
	WAVE reals=$("root:Packages:NIST:RAW:realsread")
	reals[1]=1		//true monitor counts, still in raw
	Add_Raw_to_work(type)
	//data is now in "type" folder
	WAVE data=$("root:Packages:NIST:"+type+":linear_data")
	WAVE data_copy=$("root:Packages:NIST:"+type+":data")
	WAVE data_err=$("root:Packages:NIST:"+type+":linear_data_error")
	WAVE new_reals=$("root:Packages:NIST:"+type+":realsread")
	
	Variable norm_mon,tot_mon,scale
	
	norm_mon = new_reals[0]		//should be 1e8
	tot_mon = new_reals[1]		//should be equal to the number of runs (1 count per run)
	scale= norm_mon/tot_mon
	
	data /= scale		//unscale the data
	data_err /= scale
	
	// to keep "data" and linear_data in sync
	data_copy = data
	
	return(0)
End
