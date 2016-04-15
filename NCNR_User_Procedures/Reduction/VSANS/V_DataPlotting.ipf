#pragma TextEncoding = "MacRoman"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0


//
// functions to plot the averaged data in various views.
//



//
// simple entry procedure
//
Function V_PlotData_Panel()
	DoWindow V_1D_Data
	if(V_flag==0)
		Execute "V_DrawPlotPanel()"
	else
		SVAR type = root:Packages:NIST:VSANS:Globals:gCurDispType

		V_QBinAllPanels(type)

	// TODO:
	// x- "B" detector is currently skipped - Q is not yet calculated
		Execute ("V_Back_IQ_Graph(\""+type+"\")")
		Execute ("V_Middle_IQ_Graph(\""+type+"\")")
		Execute ("V_Front_IQ_Graph(\""+type+"\")")
	endif
End


// graph with the 1D representation of the VSANS detectors
//
// TODO:
// -- add multiple options for how to present/rescale the data
// -- automatically position the window next to the 2D data
// -- color coding of the different panels (data tags/arrows/toggle on/off)?
// -- VERIFY accuracy
// -- decide what to add to the control bar
//
// -- see Middle_IQ_Graph() and similar for how VCALC does this plot
//
Proc V_DrawPlotPanel()
	
	String type = root:Packages:NIST:VSANS:Globals:gCurDispType

	PauseUpdate; Silent 1		// building window...
	Display /W=(277,526,748,938)/N=V_1D_Data

	V_QBinAllPanels(type)

// TODO 
// x- "B" detector is currently skipped - Q is not yet calculated
	V_Back_IQ_Graph(type)
	V_Middle_IQ_Graph(type)
	V_Front_IQ_Graph(type)
	
End



//
// see the VCALC BinAllMiddlePanels() for an example of this
//
// TODO 
// x- detector "B" is currently skipped since the calibration waves are not faked
//    when the raw data is loaded. Then the qxqyqz waves are not generated.
//
// -- REDO the logic here. It's a mess, and will get the calculation wrong 
//
// -- figure out the binning type (where is it set?)
// -- binning type is HARD-WIRED
// -- figure out when this is to be called to re-calculate the I vs Q
//
Function V_QBinAllPanels(folderStr)
	String folderStr

	// do the back, middle, and front separately
	
//	figure out the binning type (where is it set?)
	Variable binType,ii,delQ
	String detStr
	binType = 1
	
	

//// TODO:
// x- currently the "B" detector is skipped - it was skipped in 
//       previous functions where q values are calculated	
//	
	delQ = SetDeltaQ(folderStr,"B")
	
	// dispatch based on binning type
	if(binType == 1)
		VC_fDoBinning_QxQy2D(folderStr, "B")		//normal binning, nothing to combine
	endif

// TODO -- this is only a temporary fix for slit mode	
	if(binType == 4)
		/// this is for a tall, narrow slit mode	
		VC_fBinDetector_byRows(folderStr,"B")
	endif	

// these are the binning types where detectors are not combined
// other combined binning is below the loop
	for(ii=0;ii<ItemsInList(ksDetectorListNoB);ii+=1)
		detStr = StringFromList(ii, ksDetectorListNoB, ";")
		
		// set delta Q for binning
		delQ = SetDeltaQ(folderStr,detStr)
		
		// dispatch based on binning type
		if(binType==1)
			VC_fDoBinning_QxQy2D(folderStr,detStr)
		endif
		
		// TODO -- this is only a temporary fix for slit mode	
		if(binType == 4)
			/// this is for a tall, narrow slit mode	
			VC_fBinDetector_byRows(folderStr,detStr)
		endif	
		
	endfor
	
	// bin in pairs
	if(binType == 2)
		VC_fDoBinning_QxQy2D(folderStr,"MLR")
		VC_fDoBinning_QxQy2D(folderStr,"MTB")
		VC_fDoBinning_QxQy2D(folderStr,"FLR")
		VC_fDoBinning_QxQy2D(folderStr,"FTB")	
	endif
	
	// bin everything on front or middle together
	if(binType == 3)
		VC_fDoBinning_QxQy2D(folderStr,"MLRTB")
		VC_fDoBinning_QxQy2D(folderStr,"FLRTB")
	endif

	return(0)
End


//
// duplicated from Middle_IQ_Graph from VCALC
// but plotted in a standalone graph window and not the VCALC subwindow
//
// V_1D_Data
//
// TODO
// -- need to set binType
// -- currently  hard-wired == 1
//
//
Proc V_Middle_IQ_Graph(type) 
	String type

	Variable binType
	
//	ControlInfo/W=VCALC popup_b
//	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	binType = 1
	SetDataFolder $("root:Packages:NIST:VSANS:"+type)

	if(binType==1)
		ClearIQIfDisplayed(type,"MLRTB")
		ClearIQIfDisplayed(type,"MLR")
		ClearIQIfDisplayed(type,"MTB")		//this returns to root:
		
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_ML
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_ML vs qBin_qxqy_ML
			AppendToGraph/W=V_1D_Data iBin_qxqy_MR vs qBin_qxqy_MR
			AppendToGraph/W=V_1D_Data iBin_qxqy_MT vs qBin_qxqy_MT
			AppendToGraph/W=V_1D_Data iBin_qxqy_MB vs qBin_qxqy_MB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_ML)=(65535,0,0),rgb(iBin_qxqy_MB)=(1,16019,65535),rgb(iBin_qxqy_MR)=(65535,0,0),rgb(iBin_qxqy_MT)=(1,16019,65535)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_ML)={0,4},muloffset(iBin_qxqy_MB)={0,2},muloffset(iBin_qxqy_MR)={0,8}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif		
	endif
	
	if(binType==2)
		ClearIQIfDisplayed(type,"MLRTB")
		ClearIQIfDisplayed(type,"MT")	
		ClearIQIfDisplayed(type,"ML")	
		ClearIQIfDisplayed(type,"MR")	
		ClearIQIfDisplayed(type,"MB")
	

		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_MLR
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_MLR vs qBin_qxqy_MLR
			AppendToGraph/W=V_1D_Data iBin_qxqy_MTB vs qBin_qxqy_MTB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_MLR)=(65535,0,0),rgb(iBin_qxqy_MTB)=(1,16019,65535)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_MLR)={0,2}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
			Label/W=V_1D_Data left "Intensity (1/cm)"
			Label/W=V_1D_Data bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)
		ClearIQIfDisplayed(type,"MLR")
		ClearIQIfDisplayed(type,"MTB")	
		ClearIQIfDisplayed(type,"MT")	
		ClearIQIfDisplayed(type,"ML")	
		ClearIQIfDisplayed(type,"MR")	
		ClearIQIfDisplayed(type,"MB")	
	
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_MLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_MLRTB vs qBin_qxqy_MLRTB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_MLRTB)=(65535,0,0)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
			Label/W=V_1D_Data left "Intensity (1/cm)"
			Label/W=V_1D_Data bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - Mt, ML, MR, MB are averaged
		ClearIQIfDisplayed(type,"MLRTB")
		ClearIQIfDisplayed(type,"MLR")
		ClearIQIfDisplayed(type,"MTB")
		
//		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=V_1D_Data iBin_qxqy_ML
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_ML vs qBin_qxqy_ML
			AppendToGraph/W=V_1D_Data iBin_qxqy_MR vs qBin_qxqy_MR
			AppendToGraph/W=V_1D_Data iBin_qxqy_MT vs qBin_qxqy_MT
			AppendToGraph/W=V_1D_Data iBin_qxqy_MB vs qBin_qxqy_MB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_ML)=(65535,0,0),rgb(iBin_qxqy_MB)=(1,16019,65535),rgb(iBin_qxqy_MR)=(65535,0,0),rgb(iBin_qxqy_MT)=(1,16019,65535)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_ML)={0,4},muloffset(iBin_qxqy_MB)={0,2},muloffset(iBin_qxqy_MR)={0,8}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif		
			
	endif
	
	SetDataFolder root:
End

//
// duplicated from Middle_IQ_Graph from VCALC
// but plotted in a standalone graph window and not the VCALC subwindow
//
// V_1D_Data
//
// TODO
// -- need to set binType
// -- currently  hard-wired == 1
//
//
Proc V_Front_IQ_Graph(type) 
	String type

	Variable binType
	
//	ControlInfo/W=VCALC popup_b
//	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	binType = 1
	SetDataFolder $("root:Packages:NIST:VSANS:"+type)

	if(binType==1)
		ClearIQIfDisplayed(type,"FLRTB")
		ClearIQIfDisplayed(type,"FLR")
		ClearIQIfDisplayed(type,"FTB")		//this returns to root:
		
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_FL
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_FL vs qBin_qxqy_FL
			AppendToGraph/W=V_1D_Data iBin_qxqy_FR vs qBin_qxqy_FR
			AppendToGraph/W=V_1D_Data iBin_qxqy_FT vs qBin_qxqy_FT
			AppendToGraph/W=V_1D_Data iBin_qxqy_FB vs qBin_qxqy_FB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_FL)=(39321,26208,1),rgb(iBin_qxqy_FB)=(2,39321,1),rgb(iBin_qxqy_FR)=(39321,26208,1),rgb(iBin_qxqy_FT)=(2,39321,1)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_FL)={0,4},muloffset(iBin_qxqy_FB)={0,2},muloffset(iBin_qxqy_FR)={0,8}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif		
	endif
	
	if(binType==2)
		ClearIQIfDisplayed(type,"FLRTB")
		ClearIQIfDisplayed(type,"FT")	
		ClearIQIfDisplayed(type,"FL")	
		ClearIQIfDisplayed(type,"FR")	
		ClearIQIfDisplayed(type,"FB")
	

		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_FLR
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_FLR vs qBin_qxqy_FLR
			AppendToGraph/W=V_1D_Data iBin_qxqy_FTB vs qBin_qxqy_FTB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_FLR)=(39321,26208,1),rgb(iBin_qxqy_FTB)=(2,39321,1)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_FLR)={0,2}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
			Label/W=V_1D_Data left "Intensity (1/cm)"
			Label/W=V_1D_Data bottom "Q (1/A)"
		endif	
			
	endif
	
	if(binType==3)
		ClearIQIfDisplayed(type,"FLR")
		ClearIQIfDisplayed(type,"FTB")	
		ClearIQIfDisplayed(type,"FT")	
		ClearIQIfDisplayed(type,"FL")	
		ClearIQIfDisplayed(type,"FR")	
		ClearIQIfDisplayed(type,"FB")	
	
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)
		CheckDisplayed/W=V_1D_Data iBin_qxqy_FLRTB
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_FLRTB vs qBin_qxqy_FLRTB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_FLRTB)=(39321,26208,1)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
			Label/W=V_1D_Data left "Intensity (1/cm)"
			Label/W=V_1D_Data bottom "Q (1/A)"
		endif	
			
	endif

	if(binType==4)		// slit aperture binning - Mt, ML, MR, MB are averaged
		ClearIQIfDisplayed(type,"FLRTB")
		ClearIQIfDisplayed(type,"FLR")
		ClearIQIfDisplayed(type,"FTB")
		
//		SetDataFolder root:Packages:NIST:VSANS:VCALC
		CheckDisplayed/W=V_1D_Data iBin_qxqy_FL
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_FL vs qBin_qxqy_FL
			AppendToGraph/W=V_1D_Data iBin_qxqy_FR vs qBin_qxqy_FR
			AppendToGraph/W=V_1D_Data iBin_qxqy_FT vs qBin_qxqy_FT
			AppendToGraph/W=V_1D_Data iBin_qxqy_FB vs qBin_qxqy_FB
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_FL)=(39321,26208,1),rgb(iBin_qxqy_FB)=(2,39321,1),rgb(iBin_qxqy_FR)=(39321,26208,1),rgb(iBin_qxqy_FT)=(2,39321,1)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data muloffset(iBin_qxqy_FL)={0,4},muloffset(iBin_qxqy_FB)={0,2},muloffset(iBin_qxqy_FR)={0,8}
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif		
			
	endif
	
	SetDataFolder root:
End


// TODO
// -- need to set binType
// -- currently  hard-wired == 1
//
////////////to plot the back panel I(q)
Proc V_Back_IQ_Graph(type)
	String type
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC:entry:instrument:detector_B

	Variable binType
	
//	ControlInfo/W=VCALC popup_b
//	binType = V_Value		// V_value counts menu items from 1, so 1=1, 2=2, 3=4

	bintype = 1
	
		SetDataFolder $("root:Packages:NIST:VSANS:"+type)	

	if(binType==1 || binType==2 || binType==3)
		
		CheckDisplayed/W=V_1D_Data iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_B vs qBin_qxqy_B
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif
	endif

	//nothing different here since there is ony a single detector to display, but for the future...
	if(binType==4)
		
		CheckDisplayed/W=V_1D_Data iBin_qxqy_B
		
		if(V_flag==0)
			AppendtoGraph/W=V_1D_Data iBin_qxqy_B vs qBin_qxqy_B
			ModifyGraph/W=V_1D_Data mode=4
			ModifyGraph/W=V_1D_Data marker=19
			ModifyGraph/W=V_1D_Data rgb(iBin_qxqy_B)=(1,52428,52428)
			ModifyGraph/W=V_1D_Data msize=2
			ModifyGraph/W=V_1D_Data grid=1
			ModifyGraph/W=V_1D_Data log=1
			ModifyGraph/W=V_1D_Data mirror=2
		endif
	endif

	
	SetDataFolder root:
End

