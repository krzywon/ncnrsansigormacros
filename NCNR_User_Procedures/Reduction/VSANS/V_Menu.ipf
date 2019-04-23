#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1



//
//****************************
//


Menu "VSANS"
	"Initialize",Initialize_VSANS()
	"VSANS Help"
	"-"
	"Main Control Panel",DoWindow/F Main_VSANS_Panel
	"Data Display",DoWindow/F VSANS_Data
	"VCALC",VCALC_Panel()
	"VSANS Preferences",Show_VSANSPreferences_Panel()
	"-"
	Submenu "Data Panels"
		"Patch Beam Center XY",V_PatchDet_xyCenters_Panel()
		"Patch Detector Deadtime",V_PatchDetectorDeadtimePanel()
		"Patch Detector Calibration",V_PatchDetectorCalibrationPanel()
		"-"
		"Display Temperature Sensors",V_InitSensorGrapn()
		"-"
		"Show Mask for Averaging",V_Display_Four_Panels()
//		"Annular Binning",Annular_Binning()
//		"Write Annular Data",V_Write1DAnnular()
//		"Trim I(q) points",V_CombineDataGraph()
		"-"
		"Derive Beam Centers From Reference",V_DeriveBeamCenters()
		"-"
		"Back Detector Saturation",Vm_NumberSaturated()
		"Median Filter Back Det",pV_MedianFilterBack()
		"Subtract Read Noise",pV_SubtractReadNoiseBack()
		"Median+Read Noise",pV_MedianAndReadNoiseBack()
	End
	SubMenu "Nexus File Corrections"
		"Patch GroupID using CatTable",V_Patch_GroupID_catTable()
		"Patch Purpose using CatTable",V_Patch_Purpose_catTable()
		"Patch Intent using CatTable",V_Patch_Intent_catTable()
		"-"
//		"Flip Lateral Offset",V_PatchDet_Offset()
//		"Mark Lateral Flip Done",V_MarkLeftRightFlip_Done()
//		"Mark Lateral Flip NOT Done",V_MarkLeftRightFlip_Not_Done()
//		"Patch Detector Panel Gap",V_PatchDet_Gap()
//		"Read Detetcor Panel Gap",V_ReadDet_Gap()
		"Patch Detector Distance",V_PatchDet_Distance()
		"Patch XY Pixel Size",V_Patch_XYPixelSize()
		"-"
		"Patch Back Detector Values",V_Patch_Back_Detector()
		"Patch NumberOfGuides_SSD_Aperture ",V_Patch_Guide_SSD_Aperture()
		"Patch Beam Stop",V_Patch_BeamStop()
	End
	SubMenu "File Tests"
		"Copy_VCALC_to_VSANSFile",Copy_VCALC_to_VSANSFile()
		"-"
		"Read_Nexus with attributes",Read_Nexus_Xref()		//this will read with attributes
		"Write_Nexus with attributes",Write_Nexus_Xref()				//this will write out with attributes if read in by Read_Nexus_Xref
		"-"
		"Beam Center Panel",V_FindBeamCenter()
		"Save I(Q) as ITX",Vm_Write1DData_ITX()
		//
//		"Setup_VSANS_DIV_Struct"
//		"Save_VSANS_DIV_Nexus"
//		"Setup_VSANS_MASK_Struct"
//		"Save_VSANS_MASK_Nexus"
//		"-"
//		"Dump_V_getFP"
//		"Dump_V_getFP_Det"
//		"Dump_V_getSTR"
//		"Dump_V_getSTR_Det"
//		"Fill_Nexus_V_Template"
//		"Save_Nexus_V_Template"
//		"Load_Nexus_V_Template"
//		"-"
//		"IgorOnly_Setup_VSANS_Struct"
//		"IgorOnly_Save_VSANS_Nexus"
//		"IgorOnly_Setup_SANS_Struct"
//		"IgorOnly_Save_SANS_Struct"
	End
//	Submenu "Work File Operations"
//		"Convert to WORK",V_Convert_to_Workfile()
//		"Load Fake DIV Data"
//		"DIV a work file",V_DIV_a_Workfile()
//		"Load Fake MASK Data"
//		"Correct Data",V_CorrectData()
//	End
End


//
xMenu "SANS"
	"Initialize"
	"SANS Help"
	"-"
	"Main Control Panel",DoWindow/F Main_Panel
	"SASCALC"
	"-"
	Submenu "Data Display"
		"Show 2D SANS Data",DoWindow/F SANS_Data
		"Show File Table",ShowCatWindow()
	End
	Submenu "Input Panels"
		"Calculate Transmissions",CalcTrans()
		"Build Reduction Protocols",ReductionProtocolPanel()
		"Reduce Multiple Files",ReduceMultipleFiles()
		"Patch Files",PatchFiles()
		"1D Average",ShowAveragePanel()		
	End
	Submenu "1-D Processing"
		"Load and Plot 1D Data",Show_Plot_Manager()
		"Open FIT Panel",OpenFITPanel()
		"Sort and Combine data",ShowNSORTPanel()
//		"Subtract 1D Data Sets",OpenSubtract1DPanel()
		"ReWrite Experimental Data",MakeDMPanel()		//,ReWrite1DData()	// SRK SEP10
		"1D Arithmetic Panel",MakeDAPanel()
		"ReBin 1D Data",OpenRebin()
	End
	Submenu "2-D Processing"
		"2D Work file Math",Show_WorkMath_Panel()
		"Tile Raw 2D files",Show_Tile_2D_Panel()
		"Export 2D ASCII data",Export_RAW_Ascii_Panel()
		"Bin QxQy Data to 1D",BinQxQy_to_1D()
	End
	Submenu "Event Processing"
		"Event Mode Process Panel",Show_Event_Panel()
		"Adjust Events",ShowEventCorrectionPanel()
		"Create Custom Bins",Show_CustomBinPanel()
		"-"
		"Split Large File",SplitBigFile()
		"Accumulate First Slice",AccumulateSlices(0)
		"Add Current Slice",AccumulateSlices(1)
		"Display Accumulated Slices",AccumulateSlices(2)	
	End
	"-"
	"NCNR Preferences",Show_Preferences_Panel()
	"Feedback or Bug Report",OpenTracTicketPage()
	"Open Help Movie Page",OpenHelpMoviePage()
	"Check for Updates",CheckForLatestVersion()
//	Submenu "Utility Routines"
//		"Clear Work Folders"
//		"Clear Root Folder"
//	End
End

Function VSANSHelp()
	DisplayHelpTopic/Z/K=1 "VSANS Data Reduction Tutorial"
	if(V_flag !=0)
		DoAlert 0,"The VSANS Data Reduction Tutorial Help file could not be found, because it has not yet been written"
	endif
End
