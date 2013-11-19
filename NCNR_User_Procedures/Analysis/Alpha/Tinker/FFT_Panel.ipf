#pragma rtGlobals=1		// Use modern global access method.

//
// utility functions and procedures for displaying information
// setting the matrix, and doing the calculations
//


//
// TO DO:
// x- I need to change a lot of routines (most notably Gizmo) to take "10" as the default SLD
//		 rather than "1"
//
//
// -- incorporate utility function that reads the wave note from a binary file 
//			Function/S LoadNoteFunc(PName,FName[,FileRef]) - use this as an "inspector?"
////////////

//

//***********
//For a 3D slicer view of dmat:
//
//Duplicate/O dmat dmatView
//
//Open a New 3D voxelgram. Don't set any of the levels
//Open the 3D Slicer under the Gizmo menu
//Make the X, Y, and Z slices
//(Yellow Hot seems to be the best)
//
//// for a better view
//dmatView = log(dmat)
//
//// if it all goes blank after the log transform get rid of the INF
//dmatView = numtype(dmatView)== 0 ? dmatView : 0
//
//*************


///PANEL
///// panel procedures

Proc Init_FFT()
	DoWindow/F FFT_Panel
	if(V_flag==0)
		SetDataFolder root:
		//init the globals
		Variable/G root:FFT_N=128
		Variable/G root:FFT_T=5
		Variable/G root:FFT_Qmax = 0
		Variable/G root:FFT_QmaxReal = 0
		Variable/G root:FFT_DQ=0
		Variable/G root:FFT_estTime = 0
		
		Variable/G root:FFT_SolventSLD = 0
		Variable/G root:FFT_delRho = 1e-7			//multiplier for SLD (other value is 1e-7)
		
		FFT_Qmax :=2*pi/FFT_T
		FFT_QmaxReal := FFT_Qmax/2
		FFT_DQ := pi/(FFT_N*FFT_T)
		//empirical fit (cubic) of time vs N=50 to N=256
		FFT_estTime := 0.56 - 0.0156*FFT_N + 0.000116*FFT_N^2 + 8e-7*FFT_N^3
//		FFT_estTime := FFT_N/128
		
		FFT_Panel()
	endif
End


Proc FFT_Panel() 
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1452,44,1768,531)/K=1 as "FFT_Panel"
	DoWindow/C FFT_Panel
	SetDrawLayer UserBack
	DrawLine 5,68,311,68
	DrawLine 5,142,311,142
	DrawLine 5,250,311,250
	SetVariable FFTSetVar_0,pos={7,7},size={150,15},title="Cells per edge (N)"
	SetVariable FFTSetVar_0,limits={50,512,2},value= FFT_N,live= 1
	SetVariable FFTSetVar_1,pos={7,33},size={150,15},title="Length per Cell (T)"
	SetVariable FFTSetVar_1,limits={1,5000,0.2},value= FFT_T,live= 1
	SetVariable FFTSetVar_2,pos={183,26},size={120,15},title="Real Qmax"
	SetVariable FFTSetVar_2,limits={0,0,0},value= FFT_QmaxReal,noedit= 1,live= 1
	SetVariable FFTSetVar_3,pos={183,48},size={120,15},title="delta Q (A)"
	SetVariable FFTSetVar_3,limits={0,0,0},value= FFT_DQ,noedit= 1,live= 1
	Button FFTButton_0,pos={15,79},size={90,20},proc=FFT_MakeMatrixButtonProc,title="Make Matrix"
	Button FFTButton_1,pos={14,157},size={90,20},proc=FFTMakeGizmoButtonProc,title="Make Gizmo"
	Button FFTButton_2,pos={14,187},size={100,20},proc=FFTDrawSphereButtonProc,title="Draw Sphere"
	Button FFTButton_3,pos={14,265},size={70,20},proc=DoTheFFT_ButtonProc,title="Do FFT"
	Button FFTButton_4,pos={180,264},size={130,20},proc=FFT_PlotResultsButtonProc,title="Plot FFT Results"
	Button FFTButton_5,pos={13,218},size={120,20},proc=FFTDrawZCylinderButtonProc,title="Draw Cylinder"
//	Button FFTButton_6,pos={134,79},size={90,20},proc=FFTEraseMatrixButtonProc,title="Erase Matrix"
	Button FFTButton_6a,pos={160,79},size={60,20},proc=FFTSaveMatrixButtonProc,title="Save"
	Button FFTButton_6b,pos={240,79},size={60,20},proc=FFTLoadMatrixButtonProc,title="Load"
	Button FFTButton_7,pos={13,329},size={130,20},proc=FFT_BinnedSpheresButtonProc,title="Do Binned Debye"
	Button FFTButton_7a,pos={180,329},size={130,20},proc=FFT_PlotResultsButtonProc,title="Plot Binned Results"

	Button FFTButton_8,pos={13,297},size={130,20},proc=FFT_AltiSpheresButtonProc,title="Do Debye Spheres"
	Button FFTButton_8a,pos={180,297},size={130,20},proc=FFT_PlotResultsButtonProc,title="Plot Debye Results"

	Button FFTButton_14,pos={13,360},size={130,20},proc=FFT_BinnedSLDButtonProc,title="Do Binned SLD"
	Button FFTButton_14a,pos={180,360},size={130,20},proc=FFT_PlotResultsButtonProc,title="Plot SLD Results"

	SetVariable FFTSetVar_4,pos={201,4},size={100,15},title="FFT time(s)"
	SetVariable FFTSetVar_4,limits={0,0,0},value= FFT_estTime,noedit= 1,live= 1,format="%d"
	Button FFTButton_9,pos={200,400},size={100,20},proc=FFT_Get2DSlice,title="Get 2D Slice"
	Button FFTButton_10,pos={169,156},size={130,20},proc=FFT_TransposeMat,title="Transpose Matrix"
	Button FFTButton_11,pos={169,189},size={130,20},proc=FFT_RotateMat,title="Rotate Matrix"
	Button FFTButton_12,pos={168,219},size={130,20},proc=FFT_AddRotatedObject,title="Add Rotated Obj"
	Button FFTButton_12,disable=2		// hide this button
	Button FFTButton_13,pos={14,109},size={120,20},proc=FFTFillSolventMatrixProc,title="Solvent Matrix"
	SetVariable FFTSetVar_5,pos={155,111},size={150,15},title="Solvent SLD (10^-7)"
	SetVariable FFTSetVar_5,limits={-99,99,1},value= FFT_SolventSLD,live= 1
	Button FFTButton_15,pos={209,430},size={90,20},proc=Interp2DSliceButton,title="Interp 2D"
	Button FFTButton_16,pos={14,460},size={70,20},proc=FFTHelpButton,title="Help"
EndMacro

// Save a matrix wave, plus the N, T, and solvent values in the wave note for reloading
Function FFTSaveMatrixButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			// click code here
			String fileStr=""
			SaveMyMatrix(fileStr)
			
			break
	endswitch

	return 0
End

// this will wave as Igor Binary, so be sure to use the ".ibw extension.
// - this could possibly be enforced, but that's maybe not necessary at this stage.
//
Function SaveMyMatrix(fileStr)
	String fileStr
	
	WAVE mat=root:mat
	NVAR FFT_T = root:FFT_T
	NVAR FFT_N = root:FFT_N
	NVAR FFT_SolventSLD = root:FFT_SolventSLD
	String str=""
	sprintf str,"FFT_T=%g;FFT_N=%d;FFT_SolventSLD=%d;",FFT_T,FFT_N,FFT_SolventSLD
	Note mat,str
	Save/C/P=home mat as fileStr	//will ask for a file name, save as Igor Binary
	Note/K mat			//kill wave note on exiting since I don't properly update this anywhere else
			
	return(0)
end


// load in a previously saved matrix, and reset FFT_N, FFT_T and solvent
// from the wave note when saved
Function FFTLoadMatrixButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			// click code here
			String fileStr=""
			ReloadMatrix(fileStr)
			
			break
	endswitch

	return 0
End


Function ReloadMatrix(fileStr)
	String fileStr
	
		LoadWave/M/O/W/P=home		fileStr		//will ask for a file, Igor Binary format is assumed here
		if(V_flag == 0)
			return(0)		//user cancel
		endif
		
		String str
		str=note(mat)
		NVAR FFT_T = root:FFT_T
		NVAR FFT_N = root:FFT_N
		NVAR FFT_SolventSLD = root:FFT_SolventSLD
		
		FFT_T = NumberByKey("FFT_T", str, "=" ,";")
		FFT_N = NumberByKey("FFT_N", str, "=" ,";")
		FFT_SolventSLD = NumberByKey("FFT_SolventSLD", str, "=" ,";")

// if I got bad values, put in default values			
		if(numtype(FFT_T) != 0 )
			FFT_T = 5
		endif
		if(numtype(FFT_N) != 0 )
			FFT_N = DimSize(mat,0)
		endif
		if(numtype(FFT_SolventSLD) != 0 )
			FFT_SolventSLD = 0
		endif			
		
		Print "Loaded matrix parameters = ",str
		Execute "NumberOfPoints()"
			
	return(0)
end

// utility function that reads the wave note from a binary file
// where did I get this from? Igor Exchange? I didn't write this myself...
//
Function/S LoadNoteFunc(PName,FName[,FileRef])
	String PName, FName
	Variable FileRef
	
	Variable noteStart, noteLength, version, dependLength
	String noteStr, typeStr = ".ibw"
	if (ParamIsDefault(FileRef))
		Open/R/P=$PName/T=typeStr fileRef, as FName	//open the file
	endif
	FSetPos fileRef, 0
	FBinRead/F=2 fileRef, version
	
	
	if (version == 5)
	
		FSetPos fileRef, 4
		Make/N=(3)/I/Free SizeWave
		FBinRead FileRef,SizeWave
		noteStart = SizeWave[0]
		DependLength = SizeWave[1]
		NoteLength = SizeWave[2]
		noteStart += dependLength+64
		
	elseif (version == 2)
	
		FBinRead/F=3 fileRef, noteStart
//		FBinRead/F=4 fileRef, dependLength
		FBinRead/F=3 fileRef, noteLength
		noteStart += 16
		
	else
	
		if (ParamIsDefault(FileRef))
			Close(FileRef)		//close the file
		endif
		return ""
	
	endif
	if (!NoteLength)
		if (ParamIsDefault(FileRef))
			Close(FileRef)		//close the file
		endif
		return("")
	endif
	FSetPos fileRef, noteStart
	NoteStr = PadString("",NoteLength,0)
	FBinRead FileRef,NoteStr
	
	if (ParamIsDefault(FileRef))
		Close(FileRef)		//close the file
	endif
	return noteStr
	
End //LoadNoteFunc


Function FFTHelpButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String win = ba.win

	switch (ba.eventCode)
		case 2:
			// click code here
			DisplayHelpTopic/Z/K=1 "Real-Space Modeling of SANS Data"
			if(V_flag !=0)
				DoAlert 0,"The Real-Space Modeling Help file could not be found"
			endif
			break
	endswitch

	return 0
End


Function Interp2DSliceButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String folderStr=""
			Prompt folderStr, "Pick a 2D data folder",popup,W_DataSetPopupList()		// Set prompt for x param
			DoPrompt "Enter data folder", folderStr
			if (V_Flag || strlen(folderStr) == 0)
				return -1								// User canceled, null string entered
			endif			
	
			Interpolate2DSliceToData(folderStr)
			
			//display the 2D plane
			DoWindow FFT_Interp2D_log
			if(V_flag == 0)
				Execute "Display2DInterpSlice_log()"
			endif
			
			break
	endswitch

	return 0
End



Function FFT_Get2DSlice(ctrlName) : ButtonControl
	String ctrlName
		
	WAVE/Z dmat = root:dmat
	if(WaveExists(dmat)==1)
		get2DSlice(dmat)
	endif
	
	//display the 2D plane
	DoWindow FFT_Slice2D
	if(V_flag == 0)
		Execute "Display2DSlice()"
	endif
	
	//display the 2D plane
	DoWindow FFT_Slice2D_log
	if(V_flag == 0)
		Execute "Display2DSlice_log()"
	endif
	
	//display the 1D binning of the 2D plane
	DoWindow FFT_Slice1D
	if(V_flag == 0)
		Execute "Slice2_1D()"
	endif
	
	return(0)	
End

Proc Display2DSlice()
	PauseUpdate; Silent 1		// building window...
	Display /W=(1038,44,1404,403)
	DoWindow/C FFT_Slice2D
	AppendImage/T detPlane
	ModifyImage detPlane ctab= {*,*,YellowHot,0}
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetAxis/A/R left
End

Proc Display2DInterpSlice_log()
	PauseUpdate; Silent 1		// building window...
	Display /W=(1038,44,1404,403)
	DoWindow/C FFT_Interp2D_log
	AppendImage/T interp2DSlice_log
	ModifyImage interp2DSlice_log ctab= {*,*,YellowHot,0}
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetAxis/A/R left
End

Proc Display2DSlice_log()
	PauseUpdate; Silent 1		// building window...
	Display /W=(1038,44,1404,403)
	DoWindow/C FFT_Slice2D_log
	AppendImage/T logP
	ModifyImage logP ctab= {*,*,YellowHot,0}
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
	ModifyGraph mirror=2
	ModifyGraph nticks=4
	ModifyGraph minor=1
	ModifyGraph fSize=9
	ModifyGraph standoff=0
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	SetAxis/A/R left
End
Proc Slice2_1D()
	PauseUpdate; Silent 1		// building window...
	Display /W=(1034,425,1406,763) iBin_2d vs qBin_2d
	DoWindow/C FFT_Slice1D
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph msize=2
	ModifyGraph grid=1
	ModifyGraph log=1
	ModifyGraph mirror=2
	Legend
EndMacro


Function FFT_TransposeMat(ctrlName) : ButtonControl
	String ctrlName

	Variable mode=1
	Prompt mode,"Transform XYZ to:",popup,"XZY;ZXY;ZYX;YZX;YXZ;"
	DoPrompt "Transform mode",mode
	if (V_Flag)
		return 0									// user canceled
	endif
	
	fFFT_TransposeMat(mode)
	
	return (0)
End

// starting in XYZ
// mode 1;2;3;4;5;
//correspond to
// "XZY;ZXY;ZYX;YZX;YXZ;"
//
Function fFFT_TransposeMat(mode)
	Variable mode

	WAVE/Z mat=mat
	ImageTransform /G=(mode) transposeVol mat
	WAVE M_VolumeTranspose=M_VolumeTranspose
	Duplicate/O M_VolumeTranspose mat
	
	return(0)	
End

Function FFT_RotateMat(ctrlName) : ButtonControl
	String ctrlName
	
	Variable degree=45,sense=1
	Prompt degree, "Degrees of rotation around Z-axis:"
//	Prompt sense, "Direction of rotation:",popup,"CW;CCW;"
	DoPrompt "Enter parameters for rotation", degree
	
	if (V_Flag)
		return 0									// user canceled
	endif
	
	fFFT_RotateMat(degree)
	return(0)
End

// note that the rotation is not perfect. if the rotation produces an
// odd number of pixels, then the object will "walk" one pixel. Also, some
// small artifacts are introduced, simply due to the voxelization of the object
// as it is rotated. rotating a cylinder 10 then 350 shows a few extra "bumps" on
// the surface, but the calculated scattering is virtually identical.
//
// these issues, may be correctable, if needed
//
Function fFFT_RotateMat(degree)
	Variable degree
	
	Variable fill=0
	NVAR solventSLD = root:FFT_SolventSLD
	fill = solventSLD
	
	WAVE mat = mat
	Variable dx,dy,dz,nx,ny,nz
	dx = DimSize(mat,0)
	dy = DimSize(mat,1)
	dz = DimSize(mat,2)
		
	//? the /W and /C flags seem to be special cases for 90 deg rotations
	ImageRotate /A=(degree)/E=(fill) mat		//mat is not overwritten, unless /O
	
	nx = DimSize(M_RotatedImage,0)
	ny = DimSize(M_RotatedImage,1)
	nz = DimSize(M_RotatedImage,2)
//	Print "rotated dims = ",dx,dy,dz,nx,ny,nz
	Variable delx,dely,odd=0
	delx = nx-dx
	dely = ny-dy
	
	if(mod(delx,2) != 0)		//sometimes the new x,y dims are odd!
		odd = 1
	endif
//	delx = (delx + odd)/2
//	dely = (dely + odd)/2
	delx = trunc(delx/2)
	dely = trunc(dely/2)

	//+odd removes an extra point if there is one
	Duplicate/O/R=[delx+odd,nx-delx-1][dely+odd,ny-dely-1][0,nz-1] M_RotatedImage mat

// - not sure why the duplicate operation changes the start and delta of mat, but I
// need to reset the start and delta to be sure that the display is correct, and that the scaling
// is read correctly later
	SetScale/P x 0,1,"", mat
	SetScale/P y 0,1,"", mat
	
	nx = DimSize(mat,0)
	ny = DimSize(mat,1)
	nz = DimSize(mat,2)
//	Print "redim = ",dx,dy,dz,nx,ny,nz
	
	KillWaves/Z M_RotatedImage
	
End

// also look for ImageTransform operations that will allow translation of the objects.
// then simple objects could be oriented @0,0,0, and translated to the correct position (and added)
//
Function FFT_AddRotatedObject(ctrlName) : ButtonControl
	String ctrlName

	Print "Not yet implemented"
End


Function FFT_MakeMatrixButtonProc(ctrlName) : ButtonControl
	String ctrlName

	NVAR nn=root:FFT_N
	if(mod(nn, 2 ) ==1)		//force an even number for FFT
		nn +=1
	endif
	MakeMatrix("mat",nn,nn,nn)
End

Function FFTMakeGizmoButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/F Gizmo_VoxelMat
	if(V_flag==0)
		Execute "Gizmo_VoxelMat()"
	endif
	ColorizeGizmo()
End

Function FFTDrawSphereButtonProc(ctrlName)  : ButtonControl
	String ctrlName
	
	Execute "FFTDrawSphereProc()"
End

Proc FFTDrawSphereProc(matStr,rad,xc,yc,zc,fill) 
	String matStr="mat"
	Variable rad=25,xc=50,yc=50,zc=50,fill=10
	Prompt matStr,"the wave"		//,popup,WaveList("*",";","")
	Prompt rad,"enter real radius (A)"
	Prompt xc,"enter the X-center"
	Prompt yc,"enter the Y-center"
	Prompt zc,"enter the Z-center"
	Prompt fill,"fill SLD value"
	
	Variable grid=root:FFT_T
	
	FillSphereRadius($matStr,grid,rad,xc,yc,zc,fill)
	
End

Function FFTDrawZCylinderButtonProc(ctrlName)  : ButtonControl
	String ctrlName
	
	Execute "FFTDrawCylinder()"
End

Proc FFTDrawCylinder(direction,matStr,rad,len,xc,yc,zc,fill)
	String direction
	String matStr="mat"
	Variable rad=25,len=300,xc=50,yc=50,zc=50,fill=10
	Prompt direction, "Direction", popup "X;Y;Z;"
	Prompt matStr,"the wave"		//,popup,WaveList("*",";","")
	Prompt rad,"enter real radius (A)"
	Prompt len,"enter length (A)"
	Prompt xc,"enter the X-center"
	Prompt yc,"enter the Y-center"
	Prompt zc,"enter the Z-center"
	Prompt fill,"fill SLD value"
	
	
	Variable grid=root:FFT_T
	
	if(cmpstr(direction,"X")==0)
		FillXCylinder($matStr,grid,rad,xc,yc,zc,len,fill)
	endif
	if(cmpstr(direction,"Y")==0)
		FillYCylinder($matStr,grid,rad,xc,yc,zc,len,fill)
	endif
	if(cmpstr(direction,"Z")==0)
		FillZCylinder($matStr,grid,rad,xc,yc,zc,len,fill)
	endif
	
End


Function DoTheFFT_ButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "DoFFT()"
End

Function FFT_PlotResultsButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Variable first=0
	DoWindow/F FFT_IQ
	if(V_flag==0)
		first = 1
		Display /W=(295,44,627,302)
		DoWindow/C FFT_IQ
	Endif
	
	// append the desired data, if it's not already there
	// FFTButton_4 = FFT		= iBin
	// FFTButton_7a = binned = _XOP
	// FFTButton_8a = Debye = _full
	// FFTButton_14a = SLD = _SLD
	strswitch(ctrlName)	
		case "FFTButton_4":
			if(!isTraceOnGraph("iBin","FFT_IQ") && exists("iBin")==1)		//only append if it's not already there
				AppendToGraph /W=FFT_IQ iBin vs qBin
				ModifyGraph mode=4,marker=19,msize=2,rgb(iBin)=(65535,0,0)
			endif
			break
		case "FFTButton_7a":
			if(!isTraceOnGraph("ival_XOP","FFT_IQ") && exists("ival_XOP")==1)		//only append if it's not already there
				AppendToGraph /W=FFT_IQ ival_XOP vs qval_XOP
				ModifyGraph mode=4,marker=19,msize=2,rgb(ival_XOP)=(1,12815,52428)
			endif		
			break
		case "FFTButton_8a":
			if(!isTraceOnGraph("ival_full","FFT_IQ") && exists("ival_full")==1)		//only append if it's not already there
				AppendToGraph /W=FFT_IQ ival_full vs qval_full
				ModifyGraph mode=4,marker=19,msize=2,rgb(ival_full)=(0,0,0)
			endif		
			break
		case "FFTButton_14a":
			if(!isTraceOnGraph("ival_SLD","FFT_IQ") && exists("ival_SLD")==1)		//only append if it's not already there
				AppendToGraph /W=FFT_IQ ival_SLD vs qval_SLD
				ModifyGraph mode=4,marker=19,msize=2,rgb(ival_SLD)=(2,39321,1)
			endif		
			break
	endswitch
	
	if(first)
		ModifyGraph mode=4
		ModifyGraph marker=19
		ModifyGraph msize=2
		ModifyGraph gaps=0
		ModifyGraph grid=1
		ModifyGraph log=1
		ModifyGraph mirror=2
		Legend
	endif
	
	return(0)
End

Function isTraceOnGraph(traceStr,winStr)
	String traceStr,winStr
	
	Variable isOn=0
	String str
	str = TraceNameList(winStr,";",1)		//only normal traces
	isOn = strsearch(str,traceStr,0)		//is the trace there?
	isOn = isOn == -1 ? 0 : 1			// return 0 if not there, 1 if there

	return(isOn)
End

Function FFTEraseMatrixButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	Wave mat=root:mat
	FastOp mat=0
	return(0)
End

Function FFTFillSolventMatrixProc(ctrlName) : ButtonControl
	String ctrlName
	
	Wave mat=root:mat
	NVAR val=root:FFT_SolventSLD
	mat=val
	return(0)
End

Function FFT_AltiSpheresButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "DoSpheresCalcFFTPanel()"
End

Function FFT_BinnedSpheresButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "DoBinnedSpheresCalcFFTPanel()"
End

Function FFT_BinnedSLDButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Execute "DoBinnedSLDCalcFFTPanel()"
End





/////UTILITIES

// inverts the values in the matrix 0<->1
Function InvertMatrixFill(mat)
	Wave mat
	
	mat = (mat==1) ? 0 : 1
End

//overwrites any existing matrix
// matrix is byte, to save space
//forces the name to be "mat"
//
// switched to signed byte
//
Function MakeMatrix(nam,xd,yd,zd)
	String nam
	Variable xd,yd,zd
	
	nam="mat"
	Print "Matrix has been created and named \"mat\""
//	Make/O/U/B/N=(xd,yd,zd) $nam
	Make/O/B/N=(xd,yd,zd) $nam
End


// calculate the average center-to-center distance between points
// assumes evenly spaced on a cubic grid
//
Proc Center_to_Center(np)
	Variable np = 100
	
	Variable Nedge = root:FFT_N
	Variable Tscale = root:FFT_T
	
	Variable davg
	
	davg = (Nedge*Tscale)^3 / np
	davg = davg^(1/3)
	Print "Average separation (A) = ",davg
	
End

// calculate the number of points required on a grid
// to yield a given average center-to-center distance between points
// assumes evenly spaced on a cubic grid
//
// davg and Tscale are the same units, Angstroms
//
Proc Davg_to_Np(davg)
	Variable davg = 400
	
	Variable Nedge = root:FFT_N
	Variable Tscale = root:FFT_T
	
	Variable np
	
	np = (Nedge*Tscale)^3 / davg^3
	Print "Number of points required = ",np
	
End






// The matrix is not necessarily 0|1, this reports the number of filled voxels
// - needed to estimate the time required for the AltiVec_Spheres calculation
Proc NumberOfPoints()
	
	Print "Number of points = ",NumberOfPoints_Occ(root:mat)
	Print "Fraction occupied = ",VolumeFraction_Occ(root:mat)
	Print "Overall Cube Edge [A] = ",root:FFT_T * root:FFT_N
	Print "Found values in matrix = ",ListOfValues(root:mat)
	
End

Function NumberOfPoints_Occ(m)
	Wave m
	
	Variable num = NonZeroValues(m)

	return(num)
End


Function VolumeFraction_Occ(m)
	Wave m
	
	Variable num = NonZeroValues(m)
	Variable dim = DimSize(m,0)

	return(num/dim^3)
End

//it's a byte wave, so I can't use the trick of setting the zero values to NaN
// since NaN can't be expressed as byte. So make it binary 0|1
//
// - the assumption here is that the defined solvent value is not part of the 
// particle volume. 
//
Function NonZeroValues(m)
	Wave m
	
	Variable num
	NVAR val = root:FFT_SolventSLD
	
//	Variable t1=ticks,dim
//	dim = DimSize(m, 0 )		//assume NxNxN
	Duplicate/O m,mz
	
	MultiThread mz = (m[p][q] != val) ? 1 : 0
	
	WaveStats/Q/M=1 mz		// NaN and Inf are not reported in V_npnts
	
	num = V_npnts*V_avg
	
	KillWaves/Z mz
//	Print "Number of points = ",num
//	Print "Fraction occupied = ",num/V_npnts
	
//	Print "time = ",(ticks-t1)/60.15
	return(num)
End

//
// return a list of the different values of the voxels in the matrix
//
Function/S ListOfValues(m)
	Wave m
	
	String list=""
	Variable done

	Duplicate/O m,mz
	
	done=0
	do
		WaveStats/Q/M=1 mz		// NaN and Inf are not reported in V_npnts
		if(V_max == V_min)
			list += num2str(V_min) + ";"
			done = 1
		else
			list += num2str(V_max) + ";"
			MultiThread mz = mz[p][q] == V_max ? V_min : mz[p][q]		// replace the max with min			
		endif
	while(!done)	
	
//	Print "Found values in matrix = ",list
	KillWaves/Z mz

	return(list)
End



// returns estimate in seconds
//
//		updated for quad-core iMac, 2010
//
// type 3 = binned distances and SLD
// type 2 = binned distances
// type 1 is rather meaningless
// type 0 = is the Debye, double sum (multithreaded)
//
//
// - types 2 and 3, the binned methods are inherently AAO, so there is no significant
// dependence on the number of q-values (unless it's  >> 1000). So values reported are 
// for 100 q-values.
//
// There is a function Timing_Method(type) in FFT_ConcentratedSpheres.ipf to automate some of this
//
Function EstimatedTime(nx,nq,type)
	Variable nx,nq,type
	
	Variable est=0
	
	if(type==0)		// "full" XOP 
		est = 0.4 + 1.622e-5*nx+4.86e-7*nx^2
		est /= 100
		est *= nq
	endif
	
	if(type==1)		//Igor function (much slower, 9x)
		est = (nx^2)*0.0000517		//empirical values (seconds) for igor code, 100 q-values
		est /= 100					// per q now...
		est *= nq
	endif
	
	if(type==2)		//binned distances, slow parts XOPed
		est = 0.0680 + 2.94e-6*nx+4.51e-9*nx^2			//with threading
		
//		est /= 100					// per q now...
//		est *= nq
	endif
	
	if(type==3)		//binned distances AND sld, slow parts XOPed
		est = 0.576 + 4.22e-7*nx+1.76e-8*nx^2		//with threading
		
//		est /= 100					// per q now...
//		est *= nq
	endif
	
	return(est)
End


