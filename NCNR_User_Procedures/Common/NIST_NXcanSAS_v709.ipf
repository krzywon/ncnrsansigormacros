#pragma rtGlobals=3		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.1

#include <HDF5 Browser>

//************************
// Vers 1.15 20171003
//
//************************


///////////////////////////////////////////////////////////////////////////
// - WriteNxCanSAS1D - Method for writing 1D NXcanSAS data
// Creates an HDF5 file, with reduced 1D data and stores all meta data
// If dialog and fullpath are left blank (0 and ""), fake data will be used

Function WriteNxCanSAS1D(type,fullpath,dialog)
	// Define input variables
	String type // data location, in memory, relative to root:Packages:NIST:
	String fullpath // file path and name where data will be saved
	Variable dialog // if 1, prompt user for file path, otherwise, use fullpath
	
	// Define local function variables
	Variable fileID
	String destStr="", parentBase, nxcansasBase
	String/G base = "root:NXcanSAS_file"
	
	// Define local waves
	Wave/T vals,attr,attrVals
	
	// Define folder for data heirarchy
	NewDataFolder/O/S root:NXcanSAS_file
	
	// Check fullpath and dialog
	if(dialog || stringmatch(fullpath, ""))
		fileID = NxCansas_DoSaveFileDialog()
	else
		fileID = NxCansas_CreateFile(fullpath)
	Endif
	if(!fileID)
		abort "Unable to create file at " + fullpath + "."
	else
		Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
		sPrintf parentBase,"%s:sasentry%d",base,sasentry // Igor memory base path for all
		sPrintf nxcansasBase,"/sasentry%d/",sasentry // HDF5 base path for all

		destStr = "root:Packages:NIST:"+type
		//*****these waves MUST EXIST, or IGOR Pro will crash, with a type 2 error****
		WAVE intw = $(destStr + ":integersRead")
		WAVE rw = $(destStr + ":realsRead")
		WAVE/T textw=$(destStr + ":textRead")
		WAVE qvals =$(destStr + ":qval")
		WAVE inten=$(destStr + ":aveint")
		WAVE sig=$(destStr + ":sigave")
 		WAVE qbar = $(destStr + ":QBar")
  		WAVE sigmaq = $(destStr + ":SigmaQ")
 		WAVE fsubs = $(destStr + ":fSubS")
	endif

	///////////////////////////////////////////////////////////////////////////
	// Write all data
	
	// Define common attribute waves
	Make/T/O/N=1 empty = {""}
	Make/T/O/N=1 units = {"units"}
	Make/T/O/N=1 inv_cm = {"1/cm"}
	Make/T/O/N=1 inv_angstrom = {"1/A"}
	
	// Run Name and title
	NewDataFolder/O/S $(parentBase)
	Make/O/T/N=1 $(parentBase + ":title") = {textw[6]}
	CreateStrNxCansas(fileID,nxcansasBase,"","title",$(parentBase + ":title"),empty,empty)
	Make/O/T/N=1 $(parentBase + ":run") = {textw[0]}
	CreateStrNxCansas(fileID,nxcansasBase,"","run",$(parentBase + ":run"),empty,empty)
	
	// SASData
	String dataParent = nxcansasBase + "sasdata/"
	// Create SASdata entry
	String dataBase = parentBase + ":sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q","NXdata","0",textw[1]}
	CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
	// Create q entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/T/N=2 $(dataBase + ":q:attr") = {"units","resolutions"}
	Make/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom","Qdev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Q",qvals,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/O/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
	Make/O/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","I",inten,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))
	// Create idev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",sig,units,inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qdev",sigmaq,units,inv_angstrom)
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qmean",qbar,units,inv_angstrom)
	
	// Write all meta data
	WriteMetaData(fileID,parentBase,nxcansasBase,rw,textw)
	
	//
	///////////////////////////////////////////////////////////////////////////
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
	KillDataFolder/Z $base
	
End

//
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////
// - WriteNxCanSAS2D - Method for writing 2D NXcanSAS data
// Creates an HDF5 file, generates reduced 2D data and stores all meta data
// If dialog and fullpath are left blank (0 and ""), fake data will be used

Function WriteNxCanSAS2D(type,fullpath,dialog)
	// Define input variables
	String type // data location, in memory, relative to root:Packages:NIST:
	String fullpath // file path and name where data will be saved
	Variable dialog // if 1, prompt user for file path, otherwise, use fullpath
	
	// Define local function variables
	Variable fileID
	String destStr="",typeStr="", parentBase, nxcansasBase
	String/G base = "root:NXcanSAS_file"
	
	// Define local waves
	Wave/T vals,attr,attrVals
	
	// Define folder for data heirarchy
	NewDataFolder/O/S root:NXcanSAS_file
	
	// Check fullpath and dialog
	if(dialog || stringmatch(fullpath, ""))
		fileID = NxCansas_DoSaveFileDialog()
	else
		fileID = NxCansas_CreateFile(fullpath)
	Endif
	if(!fileID)
		abort "Unable to create file at " + fullpath + "."
	else
		Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
		sPrintf parentBase,"%s:sasentry%d",base,sasentry // Igor memory base path for all
		sPrintf nxcansasBase,"/sasentry%d/",sasentry // HDF5 base path for all
		
		destStr = "root:Packages:NIST:"+type

		//must select the linear_data to export
		NVAR isLog = $(destStr+":gIsLogScale")
		if(isLog==1)
			typeStr = ":linear_data"
		else
			typeStr = ":data"
		endif
		NVAR pixelsX = root:myGlobals:gNPixelsX
		NVAR pixelsY = root:myGlobals:gNPixelsY
		Wave data=$(destStr+typeStr)
		Wave data_err=$(destStr+":linear_data_error")
		WAVE intw=$(destStr + ":integersRead")
		WAVE rw=$(destStr + ":realsRead")
		WAVE/T textw=$(destStr + ":textRead")
	endif
	
	///////////////////////////////////////////////////////////////////////////
	// Compute Qx, Qy data from pixel space
	
	Duplicate/O data,qx_val,qy_val,z_val,qval,qz_val,phi,r_dist
	
	Variable xctr,yctr,sdd,lambda,pixSize
	xctr = rw[16]
	yctr = rw[17]
	sdd = rw[18]
	lambda = rw[26]
	pixSize = rw[13]/10		//convert mm to cm (x and y are the same size pixels)
	
	qx_val = CalcQx(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)		//+1 converts to detector coordinate system
	qy_val = CalcQy(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	
	Redimension/N=(pixelsX*pixelsY) qx_val,qy_val,z_val

	Variable L2 = rw[18]
	Variable BS = rw[21]
	Variable S1 = rw[23]
	Variable S2 = rw[24]
	Variable L1 = rw[25]
	Variable lambdaWidth = rw[27]	
	Variable usingLenses = rw[28]		//new 2007

	Variable vz_1 = 3.956e5		//velocity [cm/s] of 1 A neutron
	Variable g = 981.0				//gravity acceleration [cm/s^2]
	Variable m_h	= 252.8			// m/h [=] s/cm^2

	Variable acc,ssd,lambda0,yg_d,qstar
		
	G = 981.  //!	ACCELERATION OF GRAVITY, CM/SEC^2
	acc = vz_1 		//	3.956E5 //!	CONVERT WAVELENGTH TO VELOCITY CM/SEC
	SDD = L2	*100	//1317
	SSD = L1	*100	//1627 		//cm
	lambda0 = lambda		//		15
	YG_d = -0.5*G*SDD*(SSD+SDD)*(LAMBDA0/acc)^2
	qstar = -2*pi/lambda0*2*yg_d/sdd

	// the gravity center is not the resolution center
	// gravity center = beam center
	// resolution center = offset y = dy + (2)*yg_d
	///************
	// do everything to write out the resolution too
	// un-comment these if you want to write out qz_val and qval too, then use the proper save command
	qval = CalcQval(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	qz_val = CalcQz(p+1,q+1,rw[16],rw[17],rw[18],rw[26],rw[13]/10)
	//	phi = FindPhi( pixSize*((p+1)-xctr) , pixSize*((q+1)-yctr))		//(dx,dy)
	//	r_dist = sqrt(  (pixSize*((p+1)-xctr))^2 +  (pixSize*((q+1)-yctr))^2 )		//radial distance from ctr to pt
	phi = FindPhi( pixSize*((p+1)-xctr) , pixSize*((q+1)-yctr)+(2)*yg_d)		//(dx,dy+yg_d)
	r_dist = sqrt(  (pixSize*((p+1)-xctr))^2 +  (pixSize*((q+1)-yctr)+(2)*yg_d)^2 )		//radial distance from ctr to pt
	Redimension/N=(pixelsX*pixelsY) qz_val,qval,phi,r_dist
	Make/O/N=(2,pixelsX,pixelsY) qxy_vals
	//everything in 1D now
	Duplicate/O qval SigmaQX,SigmaQY
	Make/O/N=(pixelsX,pixelsY) shadow
	Make/O/N=(2,pixelsX,pixelsY) SigmaQ_combined

	//Two parameters DDET and APOFF are instrument dependent.  Determine
	//these from the instrument name in the header.
	//From conversation with JB on 01.06.99 these are the current good values
	Variable DDet
	NVAR apOff = root:myGlobals:apOff		//in cm
	DDet = rw[10]/10			// header value (X) is in mm, want cm here

	Variable ret1,ret2,ret3,jj
	Variable nq = 0
	Variable ii = 0
	
	do
		jj = 0
		do
			nq = ii * pixelsX + jj
			get2DResolution(qval[nq],phi[nq],lambda,lambdaWidth,DDet,apOff,S1,S2,L1,L2,BS,pixSize,usingLenses,r_dist[nq],ret1,ret2,ret3)
			qxy_vals[0][ii][jj] = qx_val[nq]
			qxy_vals[1][ii][jj] = qy_val[nq]
			SigmaQ_combined[0][ii][jj] = ret1	
			SigmaQ_combined[1][ii][jj] = ret2
			shadow[ii][jj] = ret3	
			jj+=1
		while(jj<pixelsX)
		ii+=1
	while(ii<pixelsY)
	//
	///////////////////////////////////////////////////////////////////////////

	
	///////////////////////////////////////////////////////////////////////////
	// Write all data
	
	// Define common attribute waves
	Make/O/T/N=1 empty = {""}
	Make/O/T/N=1 units = {"units"}
	Make/O/T/N=1 inv_cm = {"1/cm"}
	Make/O/T/N=1 inv_angstrom = {"1/A"}
	
	// Run Name and title
	NewDataFolder/O/S $(base + parentBase)
	Make/O/T/N=1 $(base + parentBase + ":title") = {textw[6]}
	CreateStrNxCansas(fileID,parentBase,"","title",$(base + parentBase + ":title"),empty,empty)
	Make/O/T/N=1 $(base + parentBase + ":run") = {textw[0]}
	CreateStrNxCansas(fileID,nxcansasBase,"","run",$(base + parentBase + ":run"),empty,empty)
	
	// SASData
	String dataParent = nxcansasBase + "sasdata/"
	// Create SASdata entry
	String dataBase = base + parentBase + ":sasdata"
	NewDataFolder/O/S $(dataBase)
	Make/O/T/N=5 $(dataBase + ":attr") = {"canSAS_class","signal","I_axes","NX_class","Q_indices", "timestamp"}
	Make/O/T/N=5 $(dataBase + ":attrVals") = {"SASdata","I","Q,Q","NXdata","0,1",textw[1]}
	CreateStrNxCansas(fileID,dataParent,"","",empty,$(dataBase + ":attr"),$(dataBase + ":attrVals"))
	// Create i entry
	NewDataFolder/O/S $(dataBase + ":i")
	Make/O/T/N=2 $(dataBase + ":i:attr") = {"units","uncertainties"}
	Make/O/T/N=2 $(dataBase + ":i:attrVals") = {"1/cm","Idev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","I",data,$(dataBase + ":i:attr"),$(dataBase + ":i:attrVals"))

	//
	// TODO: Reinstate Qdev/resolutions when I can fix the reader issue
	//
	

	// Create qx and qy entry
	NewDataFolder/O/S $(dataBase + ":q")
	Make/O/T/N=2 $(dataBase + ":q:attr") = {"units"}//,"resolutions"}
	Make/O/T/N=2 $(dataBase + ":q:attrVals") = {"1/angstrom"}//,"Qdev"}
	CreateVarNxCansas(fileID,dataParent,"sasdata","Q",qxy_vals,$(dataBase + ":q:attr"),$(dataBase + ":q:attrVals"))
	
	// Create idev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Idev",data_err,units,inv_cm)
	// Create qdev entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","Qdev",SigmaQ_combined,units,inv_angstrom)
	// Create shadwfactor entry
	CreateVarNxCansas(fileID,dataParent,"sasdata","ShadowFactor",shadow,empty,empty)
	
	// Write all meta data
	WriteMetaData(fileID,parentBase,nxcansasBase,rw,textw)
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif
	
	KillDataFolder/Z $base
	
End

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// - WriteMetaData - Method used to write non data elements into NXcanSAS
// format. This is common between 1D and 2D data sets.

Function WriteMetaData(fileID,base,parentBase,rw,textw)
	String base,parentBase
	Variable fileID
	Wave rw
	Wave/T textw
	
	// Define common attribute waves
	Make/T/O/N=1 empty = {""}
	Make/T/O/N=1 units = {"units"}
	Make/T/O/N=1 m = {"m"}
	Make/T/O/N=1 mm = {"mm"}
	Make/T/O/N=1 cm = {"cm"}
	Make/T/O/N=1 pixel = {"pixel"}
	Make/T/O/N=1 angstrom = {"A"}
	
	// SASinstrument
	String instrParent = parentBase + "sasinstrument/"
	// Create SASinstrument entry
	String instrumentBase = base + ":sasinstrument"
	NewDataFolder/O/S $(instrumentBase)
	Make/O/T/N=5 $(instrumentBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(instrumentBase + ":attrVals") = {"SASinstrument","NXinstrument"}
	CreateStrNxCansas(fileID,instrParent,"","",empty,$(instrumentBase + ":attr"),$(instrumentBase + ":attrVals"))
	
	// SASaperture
	String apertureParent = instrParent + "sasaperture/"
	// Create SASaperture entry
	String apertureBase = instrumentBase + ":sasaperture"
	NewDataFolder/O/S $(apertureBase)
	Make/O/T/N=5 $(apertureBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(apertureBase + ":attrVals") = {"SASaperture","NXaperture"}
	CreateStrNxCansas(fileID,apertureParent,"","",empty,$(apertureBase + ":attr"),$(apertureBase + ":attrVals"))
	
	//
	// TODO: Where do I get rectangular dimensions from?
	//
	
	// Create SASaperture shape entry
	Make/O/T/N=1 $(apertureBase + ":shape") = {"pinhole"} 
	CreateStrNxCansas(fileID,apertureParent,"sasaperture","shape",$(apertureBase + ":shape"),empty,empty)
	// Create SASaperture x_gap entry
	Make/O/N=1 $(apertureBase + ":x_gap") = {rw[24]}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","x_gap",$(apertureBase + ":x_gap"),units,mm)
	// Create SASaperture y_gap entry
	Make/O/N=1 $(apertureBase + ":y_gap") = {rw[24]}
	CreateVarNxCansas(fileID,apertureParent,"sasaperture","y_gap",$(apertureBase + ":y_gap"),units,mm)
	
	// SAScollimation
	String collimationParent = instrParent + "sascollimation/"
	// Create SAScollimation entry
	String collimationBase = instrumentBase + ":sascollimation"
	NewDataFolder/O/S $(collimationBase)
	Make/O/T/N=5 $(collimationBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(collimationBase + ":attrVals") = {"SAScollimation","NXcollimator"}
	CreateStrNxCansas(fileID,collimationParent,"","",empty,$(collimationBase + ":attr"),$(collimationBase + ":attrVals"))
	// Create SAScollimation distance entry
	Make/O/N=1 $(collimationBase + ":distance") = {rw[25]}
	CreateVarNxCansas(fileID,collimationParent,"sasaperture","distance",$(collimationBase + ":distance"),units,m)
	
	// SASdetector
	String detectorParent = instrParent + "sasdetector/"
	// Create SASdetector entry
	String detectorBase = instrumentBase + ":sasdetector"
	NewDataFolder/O/S $(detectorBase)
	Make/O/T/N=5 $(detectorBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(detectorBase + ":attrVals") = {"SASdetector","NXdetector"}
	CreateStrNxCansas(fileID,detectorParent,"","",empty,$(detectorBase + ":attr"),$(detectorBase + ":attrVals"))
	// Create SASdetector name entry
	Make/O/T/N=1 $(detectorBase + ":name") = {textw[9]}
	CreateStrNxCansas(fileID,detectorParent,"","name",$(detectorBase + ":name"),empty,empty)
	// Create SASdetector distance entry
	Make/O/N=1 $(detectorBase + ":SDD") = {rw[18]}
	CreateVarNxCansas(fileID,detectorParent,"","SDD",$(detectorBase + ":SDD"),units,m)
	// Create SASdetector beam_center_x entry
	Make/O/N=1 $(detectorBase + ":beam_center_x") = {rw[16]}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_x",$(detectorBase + ":beam_center_x"),units,pixel)
	// Create SASdetector beam_center_y entry
	Make/O/N=1 $(detectorBase + ":beam_center_y") = {rw[17]}
	CreateVarNxCansas(fileID,detectorParent,"","beam_center_y",$(detectorBase + ":beam_center_y"),units,pixel)
	// Create SASdetector x_pixel_size entry
	Make/O/N=1 $(detectorBase + ":x_pixel_size") = {rw[10]}
	CreateVarNxCansas(fileID,detectorParent,"","x_pixel_size",$(detectorBase + ":x_pixel_size"),units,mm)
	// Create SASdetector y_pixel_size entry
	Make/O/N=1 $(detectorBase + ":y_pixel_size") = {rw[13]}
	CreateVarNxCansas(fileID,detectorParent,"","y_pixel_size",$(detectorBase + ":y_pixel_size"),units,mm)
	
	// SASsource
	String sourceParent = instrParent + "sassource/"
	// Create SASdetector entry
	String sourceBase = instrumentBase + ":sassource"
	NewDataFolder/O/S $(sourceBase)
	Make/O/T/N=5 $(sourceBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(sourceBase + ":attrVals") = {"SASsource","NXsource"}
	CreateStrNxCansas(fileID,sourceParent,"","",empty,$(sourceBase + ":attr"),$(sourceBase + ":attrVals"))
	// Create SASsource radiation entry
	Make/O/T/N=1 $(sourceBase + ":radiation") = {"Reactor Neutron Source"}
	CreateStrNxCansas(fileID,sourceParent,"","radiation",$(sourceBase + ":radiation"),empty,empty)
	// Create SASsource incident_wavelength entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength") = {rw[26]}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength",$(sourceBase + ":incident_wavelength"),units,angstrom)
	// Create SASsource incident_wavelength_spread entry
	Make/O/N=1 $(sourceBase + ":incident_wavelength_spread") = {rw[27]}
	CreateVarNxCansas(fileID,sourceParent,"","incident_wavelength_spread",$(sourceBase + ":incident_wavelength_spread"),units,angstrom)
	
	// SASsample
	String sampleParent = parentBase + "sassample/"
	// Create SASsample entry
	String sampleBase = base + ":sassample"
	NewDataFolder/O/S $(sampleBase)
	Make/O/T/N=5 $(sampleBase + ":attr") = {"canSAS_class","NX_class"}
	Make/O/T/N=5 $(sampleBase + ":attrVals") = {"SASsample","NXsample"}
	CreateStrNxCansas(fileID,sampleParent,"","",empty,$(sampleBase + ":attr"),$(sampleBase + ":attrVals"))
	// Create SASsample name entry
	Make/O/T/N=1 $(sampleBase + ":name") = {textw[6]}
	CreateStrNxCansas(fileID,sampleParent,"","name",$(sampleBase + ":name"),empty,empty)
	// Create SASsample thickness entry
	Make/O/N=1 $(sampleBase + ":thickness") = {rw[5]}
	CreateVarNxCansas(fileID,sampleParent,"","thickness",$(sampleBase + ":thickness"),units,cm)
	// Create SASsample transmission entry
	Make/O/N=1 $(sampleBase + ":transmission") = {rw[4]}
	CreateVarNxCansas(fileID,sampleParent,"","transmission",$(sampleBase + ":transmission"),empty,empty)
End
	
//
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////
//
// Basic file open/create and file initialization routines

// Select/create file through prompt
Function NxCansas_DoSaveFileDialog()
	Variable refNum, fileID
	String message = "Save a file"
	String outputPath
	String fileFilters = "Data Files (*.h5):.h5;"
	fileFilters += "All Files:.*;"
	Open /D /F=fileFilters /M=message refNum
	outputPath = S_fileName
	fileID = NxCansas_CreateFile(outputPath)
	return fileID
End

// Create file with a known path
Function NxCansas_CreateFile(fullpath)
	String fullpath
	Variable fileID
	Make/T/O/N=1 $("root:file_name") = fullpath
	fullpath = ReplaceString(":\\", fullpath, ":")
	fullpath = ReplaceString("\\", fullpath, ":")
	HDF5CreateFile /Z fileID as fullpath
	NXCansas_InitializeFile(fileID)
	return fileID
End

// Open\ file with a known path
Function NxCansas_OpenFile(fullpath)
	String fullpath
	String fileName
	Variable fileID
	fileName = ParseFilePath(3,fullpath,":",0,0)
	Make/T/O/N=1 $("root:file_name") = fileName
	fullpath = ReplaceString(":\\", fullpath, ":")
	fullpath = ReplaceString("\\", fullpath, ":")
	HDF5OpenFile /Z fileID as fullpath
	return fileID
End

// Select/create file through prompt
Function NxCansas_DoOpenFileDialog()
	Variable refNum,fileID
	String message = "Select a file"
	String inputPath,fileName
	String fileFilters = "Data Files (*.h5):.h5;"
	STRUCT HDF5BrowserData bd
	fileFilters += "All Files:.*;"
	Open /D /F=fileFilters /M=message refNum as fileName
	inputPath = S_fileName
	fileID = NxCansas_OpenFile(inputPath)
	return fileID
End

// Initialize the file to a base state
Function NxCansas_InitializeFile(fileID)
	Variable fileID
	String parent,nxParent
	String/G base = "root:NXcanSAS_file"
	Variable sasentry = NumVarOrDefault("root:Packages:NIST:gSASEntryNumber", 1)
	sPrintf parent,":sasentry%d",sasentry
	String location = base + parent
	sPrintf nxParent,"/sasentry%d/",sasentry
	NewDataFolder/O/S $(location)
	Make/T/N=1 $(location + ":vals") = {""}
	Make/T/N=3 $(location + ":attr") = {"NX_class", "canSAS_class", "version"}
	Make/T/N=3 $(location + ":attrVals") = {"NXentry", "SASentry", "1.0"}
	CreateStrNxCansas(fileID,nxParent,"","",$(location + ":vals"),$(location + ":attr"),$(location + ":attrVals"))
	Make/T/N=1 $(location + ":entryAttr") = {""}
	Make/T/N=1 $(location + ":entryAttrVals") = {""}
	CreateStrNxCansas(fileID,nxParent,"","definition",{"NXcanSAS"},$(location + ":entryAttr"),$(location + ":entryAttrVals"))
End

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Functions used to save data to file

// Intermediate error handler for saving variable waves - this function should be called instead of saveNxCansas
Function CreateVarNxCansas(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave valueWave
	Wave /T attr,attrValues
	Variable err
	err = saveNxCansasVars(fileID,parent,group,var,valueWave,attr,attrValues)
	if(err)
		Print "NxCansas write err = ",err
	endif
End
// Intermediate error handler for saving string waves - this function should be called instead of saveNxCansas
Function CreateStrNxCansas(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave /T valueWave,attr,attrValues
	Variable err
	err = saveNxCansasStrs(fileID,parent,group,var,valueWave,attr,attrValues)
	if(err)
		Print "NxCansas write err = ",err
	endif
End

Function NxCansas_writeAttributes(fileID,path,attrNames,attrVals)
	Variable fileID
	String path
	Wave/T attrNames, attrVals
	int numAttrs,i
	numAttrs = numpnts(attrNames)
	Duplicate/O/T attrNames, names
	Duplicate/O/T attrVals, vals
	
	for(i=0; i < numAttrs; i += 1)
		String name_i = names[i]
		String vals_i = vals[i]
		Make/T/N=1 vals_i_wave
		vals_i_wave[0] = vals_i
		if(!stringmatch(name_i,""))
			HDF5SaveData /A=name_i vals_i_wave, fileID, path
		endif
	endfor
	
End

Function NxCansas_CreateGroup(fileID,parent)
	Variable fileID
	String parent
	Variable groupID
	try	
		if(!fileID)
			abort "HDF5 file does not exist"
		endif
		
		// Create the group if it doesn't already exist
		HDF5CreateGroup /Z fileID, parent, groupID
			
	catch
		// DO something if error is thrown
		Print "NxCansas write err in saveNxCansas = ",V_AbortCode
	endtry
	return groupID
End

// Write in a single NxCansas element (from the STRUCTURE)
// This method should only be called by CreateVarNxCansas
Function saveNxCansasVars(fileID,parent,group,var,valueWave,attr,attrValues)

	Variable fileID
	String parent,group,var
	Wave valueWave
	Wave /T attr,attrValues
	int i, numAttrs
	
	variable err=0, groupID
	String NXentry_name
	
	groupID = NxCansas_CreateGroup(fileID,parent)

	// Save data to disk
	if(!stringmatch(var,""))
		HDF5SaveData /O /Z /IGOR=0 valueWave, groupID, var
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + var + " with V_flag of " + num2str(V_flag)
		endif
	endif
		
	NxCansas_writeAttributes(fileID,parent+var,attr,attrValues)
	
	// Close group and file to release resources
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif

	return err
end

// Write in a single NxCansas element
// This method should only be called by CreateStrNxCansas
Function saveNxCansasStrs(fileID,parent,group,var,valueWave,attr,attrValues)
	Variable fileID
	String parent,group,var
	Wave /T attr,attrValues, valueWave
	int i, numAttrs
	
	variable err=0, groupID
	String NXentry_name
	
	groupID = NxCansas_CreateGroup(fileID,parent)

	// Save data to disk
	if(!stringmatch(var,""))
		HDF5SaveData /O /Z /IGOR=0 valueWave, groupID, var
		if (V_flag != 0)
			err = 1
			abort "Cannot save wave to HDF5 dataset " + var + " with V_flag of " + num2str(V_flag)
		endif
	endif
		
	NxCansas_writeAttributes(fileID,parent+var,attr,attrValues)
	
	// Close group and file to release resources
	if(groupID)
		HDF5CloseGroup /Z groupID
	endif

	return err
end

//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
// NXcanSAS Reader and Utilities

Function LoadNXcanSASData(fileStr,outstr,doPlot,forceOverwrite)
	String fileStr, outstr
	Variable doPlot,forceOverwrite
	
	Variable refnum,fileID
	Variable rr,gg,bb
	SetDataFolder root:		//build sub-folders for each data set under root
	
	String filename
	String angst = StrVarOrDefault("root:Packages:NIST:gAngstStr", "A")
	
	// Check fullpath and dialog
	if(stringmatch(fileStr, ""))
		fileID = NxCansas_DoOpenFileDialog()
	else
		fileID = NxCansas_OpenFile(fileStr)
	Endif
	
	filename = ParseFilePath(3,fileStr,":",0,0)
	String basestr
	if (!cmpstr(outstr, ""))		//Outstr = "", cmpstr returns 0
		baseStr = ShortFileNameString(CleanupName(filename,0))
		baseStr = CleanupName(baseStr,0)		//in case the user added odd characters
	else
		baseStr = outstr			//for output, hopefully correct length as passed in
	endif
	String/G loadDir = "root:" + baseStr
	
	String I_dataStore = baseStr + "_i"
	String Q_dataStore = baseStr + "_q"
	String dQ_dataStore = baseStr + "_dq"
	String dQl_dataStore = baseStr + "_dql"
	String dQw_dataStore = baseStr + "_dqw"
	String dI_dataStore = baseStr + "_s"
	
	//go back to the root folder and clean up before leaving
	NewDataFolder/O/S $loadDir
	Make/O/N=52 $(loadDir + ":realsRead")
	Make/O/T/N=11 $(loadDir + ":textRead")
	
	if(fileID)
		HDF5ListGroup /F/R/Type=1/Z fileID,"/"
		String groupList = S_HDF5ListGroup
		
		//
		// TODO: Differentiate between 1D, 2D, and USANS data (resolutions) (DO I NEED TO?)
		//
	
		Variable groupID
		Variable inc = 1
		String entryUnformatted = "/sasentry%d/"
		String entryBase
		sPrintf entryBase,entryUnformatted,inc
		// Open first group
		HDF5OpenGroup /Z fileID, entryBase + "sasdata/", groupID
		do
			// Load in data
			HDF5LoadData /O/Z/N=$I_dataStore fileID, entryBase + "sasdata/I"
			HDF5LoadData /O/Z/N=$Q_dataStore fileID, entryBase + "sasdata/Q"
			HDF5LoadData /O/Z/N=$dQ_dataStore fileID, entryBase + "sasdata/dQ"
			HDF5LoadData /O/Z/N=$dQl_dataStore fileID, entryBase + "sasdata/dQl"
			HDF5LoadData /O/Z/N=$dQw_dataStore fileID, entryBase + "sasdata/dQw"
			HDF5LoadData /O/Z/N=$dI_dataStore fileID, entryBase + "sasdata/Idev"
			// Load in Meta Data
			LoadMetaData(fileID,loadDir,entryBase)
			// Open next group to see if it exists
			inc += 1
			sPrintf entryBase,entryUnformatted,inc
			HDF5OpenGroup /Z fileID, entryBase + "sasdata/", groupID
		while(groupID != 0)
		
		//plot if desired
		if(doPlot)
			Print GetDataFolder(1)
			
			String w0 = Q_dataStore
			String w1 = I_dataStore
			String w2 = dI_dataStore
			
			// assign colors randomly
			rr = abs(trunc(enoise(65535)))
			gg = abs(trunc(enoise(65535)))
			bb = abs(trunc(enoise(65535)))
			
			// if target window is a graph, and user wants to append, do so
		   DoWindow/B Plot_Manager
			if(WinType("") == 1)
				DoAlert 1,"Do you want to append this data to the current graph?"
				
				if(V_Flag == 1)
					AppendToGraph $w1 vs $w0
					ModifyGraph mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
					ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
					ModifyGraph tickUnit(left)=1
				else
				//new graph
					Display $w1 vs $w0
					ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
					ModifyGraph grid=1,mirror=2,standoff=0
					ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
					ModifyGraph tickUnit(left)=1
					Label left "I(q)"
					Label bottom "q ("+angst+"\\S-1\\M)"
					Legend
				endif
			else
			// graph window was not target, make new one
				Display $w1 vs $w0
				ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
				ModifyGraph grid=1,mirror=2,standoff=0
				ErrorBars/T=0 $w1 Y,wave=($w2,$w2)
				ModifyGraph tickUnit(left)=1
				Label left "I(q)"
				Label bottom "q ("+angst+"\\S-1\\M)"
				Legend
			endif
		endif
		
	endif
	
	// Close the file
	if(fileID)
		HDF5CloseFile /Z fileID
	endif

end

Function LoadMetaData(fileID,loadDir,parentBase)
	String parentBase,loadDir
	Variable fileID
	Variable groupID
	SetDataFolder $(loadDir)
	Wave rw = $(loadDir + ":realsRead")
	Wave/T textw = $(loadDir + ":textRead")
	
	// Title
	HDF5OpenGroup /Z fileID, parentBase, groupID
	HDF5LoadData /O/Z/N=title fileID, parentBase + "title"
	Wave/T title = $(loadDir + ":title")
	
	// SASinstrument
	String instrParent = parentBase + "sasinstrument/"
	
	// SASaperture
	String apertureParent = instrParent + "sasaperture/"
	HDF5OpenGroup /Z fileID, apertureParent, groupID
	HDF5LoadData /O/Z/N=xg fileID, apertureParent + "x_gap"
	Wave xg = $(loadDir + ":xg")
	
	// SAScollimation
	String collimationParent = instrParent + "sascollimation/"
	HDF5OpenGroup /Z fileID, collimationParent, groupID
	HDF5LoadData /O/Z/N=cdis fileID, collimationParent + "distance"
	Wave cdis = $(loadDir + ":cdis")
	
	// SASdetector
	String detectorParent = instrParent + "sasdetector/"
	HDF5OpenGroup /Z fileID, detectorParent, groupID
	HDF5LoadData /O/Z/N=detname fileID, detectorParent + "name"
	HDF5LoadData /O/Z/N=sdd fileID, detectorParent + "SDD"
	HDF5LoadData /O/Z/N=bcx fileID, detectorParent + "beam_center_x"
	HDF5LoadData /O/Z/N=bcy fileID, detectorParent + "beam_center_y"
	HDF5LoadData /O/Z/N=xps fileID, detectorParent + "x_pixel_size"
	HDF5LoadData /O/Z/N=xpy fileID, detectorParent + "y_pixel_size"
	Wave/T detname = $(loadDir + ":detname")
	Wave sdd = $(loadDir + ":sdd")
	Wave bcx = $(loadDir + ":bcx")
	Wave bcy = $(loadDir + ":bcy")
	Wave xps = $(loadDir + ":xps")
	Wave xpy = $(loadDir + ":xpy")
	
	// SASsource
	String sourceParent = instrParent + "sassource/"
	HDF5OpenGroup /Z fileID, sourceParent, groupID
	HDF5LoadData /O/Z/N=wvel fileID, sourceParent + "incident_wavelength"
	HDF5LoadData /O/Z/N=wvels fileID, sourceParent + "incident_wavelength_spread"
	Wave wvel = $(loadDir + ":wvel")
	Wave wvels = $(loadDir + ":wvels")
	
	// SASsample
	String sampleParent = parentBase + "sassample/"
	HDF5OpenGroup /Z fileID, sampleParent, groupID
	HDF5LoadData /O/Z/N=smplname fileID, sampleParent + "name"
	HDF5LoadData /O/Z/N=smplthick fileID, sampleParent + "thickness"
	HDF5LoadData /O/Z/N=smpltrans fileID, sampleParent + "transmission"
	Wave/T smplname = $(loadDir + ":smplname")
	Wave smplthick = $(loadDir + ":smplthick")
	Wave smpltrans = $(loadDir + ":smpltrans")
	
	textw[0] = title[0]
	textw[6] = smplname[0]
	textw[9] = detname[0]
	rw[4] = smplthick[0]
	rw[5] = smpltrans[0]
	rw[10] = xps[0]
	rw[13] = xpy[0]
	rw[16] = bcx[0]
	rw[17] = bcy[0]
	rw[18] = sdd[0]
	rw[24] = xg[0]
	rw[25] = cdis[0]
	rw[26] = wvel[0]
	rw[27] = wvels[0]
	
	KillWaves title,smplname,detname,smplthick,smpltrans,xps,xpy,bcx,bcy,sdd,xg,cdis,wvel,wvels
	
End

//
///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////
//
// Generic Read/Write operations.

//Needed to test whether file is NXcanSAS. The load routine will then either give an error if HDF5 XOP is not present or load the file if it is.
Function isNXcanSAS(filestr)
	String filestr
	
	Variable fileID=0,groupID=0
	Int isHDF5File = 0
	
	fileID = NxCansas_OpenFile(filestr)
	HDF5ListGroup /F/R/Type=1/Z fileID,"/"
	Variable length = strlen(S_HDF5ListGroup)
	
	if (numtype(length) != 2)
		isHDF5File = 1
	endif
	
	if (fileID != 0)
		// Close the file
		HDF5CloseFile /Z fileID
	endif
	
	return isHDF5File

end

//
///////////////////////////////////////////////////////////////////////////