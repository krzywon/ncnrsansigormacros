#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////////////////////
//
// Utility functions to:
//		calculate Q, Qx, Qy, Qz
//		fill the detector panels with simulated data (the model functions are here)
//		bin the 2D detector to 1D I(Q) based on Q and deltaQ (bin width)
//
/////////////////////////




// TODO: hard wired for a sphere - change this to allow minimal selections and altering of coefficients
// TODO: add the "fake" 2D simulation to fill the panels which are then later averaged as I(Q)
Function FillPanel_wModelData(det,qTot,type)
	Wave det,qTot
	String type

	SetDataFolder root:Packages:NIST:VSANS:VCALC:Front

	// q-values and detector arrays already allocated and calculated
	Duplicate/O det tmpInten,tmpSig,prob_i
		
	Variable imon,trans,thick,sdd,pixSizeX,pixSizeY,sdd_offset

	//imon = V_BeamIntensity()*CountTime
	imon = VCALC_getImon()		//TODO: currently from the panel, not calculated
	trans = 0.8
	thick = 0.1
	
	// need SDD
	// need pixel dimensions
	// nominal sdd in meters, offset in mm, want result in cm !
	sdd = VCALC_getSDD(type)*100	+  VCALC_getTopBottomSDDOffset(type) / 10		// result is sdd in [cm]

	pixSizeX = VCALC_getPixSizeX(type)		// cm
	pixSizeY = VCALC_getPixSizeY(type)
	
	
	//?? pick the function from a popup on the panel? (bypass the analysis panel, or maybe it's better to 
	//  keep the panel to keep people used to using it.)
	// peak @ 0.1 ~ AgBeh
	//	Make/O/D coef_BroadPeak = {1e-9, 3, 20, 100.0, 0.1,3,0.1}		
	//
	// peak @ 0.015 in middle of middle detector, maybe not "real" vycor, but that is to be resolved
	//	Make/O/D coef_BroadPeak = {1e-9, 3, 20, 500.0, 0.015,3,0.1}		
	String funcStr = VCALC_getModelFunctionStr()
	strswitch(funcStr)
		case "Big Debye":
			tmpInten = V_Debye(10,3000,0.0001,qTot[p][q])
			break
		case "Big Sphere":
			tmpInten = V_SphereForm(1,900,1e-6,0.01,qTot[p][q])	
			break
		case "Debye":
			tmpInten = V_Debye(10,300,0.0001,qTot[p][q])
			break
		case "Sphere":
			tmpInten = V_SphereForm(1,60,1e-6,0.001,qTot[p][q])	
			break
		case "AgBeh":
			tmpInten = V_BroadPeak(1e-9,3,20,100.0,0.1,3,0.1,qTot[p][q])
			break
		case "Vycor":
			tmpInten = V_BroadPeak(1e-9,3,20,500.0,0.015,3,0.1,qTot[p][q])
			break	
		case "Empty Cell":
			tmpInten = V_EC_Empirical(2.2e-8,3.346,0.0065,9.0,0.016,qTot[p][q])
			break
		case "Blocked Beam":
			tmpInten = V_BlockedBeam(1,qTot[p][q])
			break
		default:
			tmpInten = V_Debye(10,300,0.1,qTot[p][q])
	endswitch


///////////////
//	// calculate the scattering cross section simply to be able to estimate the transmission
//	Variable sig_sas=0
//	
//	// remember that the random deviate is the coherent portion ONLY - the incoherent background is 
//	// subtracted before the calculation.
//	CalculateRandomDeviate(funcUnsmeared,$coefStr,wavelength,"root:Packages:NIST:SAS:ran_dev",sig_sas)
//
//	if(sig_sas > 100)
//		DoAlert 0,"SAS cross section > 100. Estimates of multiple scattering are unreliable. Choosing a model with a well-defined Rg may help"
//	endif		
//
//	// calculate the multiple scattering fraction for display (10/2009)
//	Variable ii,nMax=10,tau
//	mScat=0
//	tau = thick*sig_sas
//	// this sums the normalized scattering P', so the result is the fraction of multiply coherently scattered
//	// neutrons out of those that were scattered
//	for(ii=2;ii<nMax;ii+=1)
//		mScat += tau^(ii)/factorial(ii)
////		print tau^(ii)/factorial(ii)
//	endfor
//	estTrans = exp(-1*thick*sig_sas)		//thickness and sigma both in units of cm
//	mscat *= (estTrans)/(1-estTrans)
//
////	if(mScat > 0.1)		//  Display warning
//
//	Print "Sig_sas = ",sig_sas
////////////////////
	
	prob_i = trans*thick*pixSizeX*pixSizeY/(sdd)^2*tmpInten			//probability of a neutron in q-bin(i) 
		
	tmpInten = (imon)*prob_i		//tmpInten is not the model calculation anymore!!


/// **** can I safely assume a Gaussian error in the count rate??
	tmpSig = sqrt(tmpInten)		// corrected based on John's memo, from 8/9/99

	tmpInten += gnoise(tmpSig)
	tmpInten = (tmpInten[p][q] < 0) ? 0 : tmpInten[p][q]			// MAR 2013 -- is this the right thing to do
	tmpInten = trunc(tmpInten)
		
	
	det = tmpInten

// if I want "absolute" scale -- then I lose the integer nature of the detector (but keep the random)
//	det /= trans*thick*pixSizeX*pixSizeY/(sdd)^2*imon

	
	KillWaves/Z tmpInten,tmpSig,prob_i	
	SetDataFolder root:

	return(0)
End


// For a given detector panel, calculate the q-values
// -work with everything as arrays
// Input needed:
// detector data
// detector type (LRTB?)
// beam center (may be off the detector)
// SDD
// lambda
// 
// pixel dimensions for detector type (global constants)
// - data dimensions read directly from array
//
// --What is calculated:
// array of Q
// array of qx,qy,qz
// array of error already exists
//
//
// -- sdd in meters
// -- lambda in Angstroms
Function V_Detector_2Q(data,qTot,qx,qy,qz,xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY)
	Wave data,qTot,qx,qy,qz
	Variable xCtr,yCtr,sdd,lam,pixSizeX,pixSizeY
		
	// loop over the array and calculate the values - this is done as a wave assignment
// TODO -- be sure that it's p,q -- or maybe p+1,q+1 as used in WriteQIS.ipf	
	qTot = V_CalcQval(p,q,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	qx = V_CalcQX(p,q,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	qy = V_CalcQY(p,q,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	qz = V_CalcQZ(p,q,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	
	return(0)
End


//////////////////////
// NOTE: The Q calculations are different than what is in GaussUtils in that they take into 
// accout the different x/y pixel sizes and the beam center not being on the detector - 
// off a different edge for each LRTB type
/////////////////////

//function to calculate the overall q-value, given all of the necesary trig inputs
//and are in detector coordinates (1,128) rather than axis values
//the pixel locations need not be integers, reals are ok inputs
//sdd is in meters
//wavelength is in Angstroms
//
//returned magnitude of Q is in 1/Angstroms
//
Function V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY
	
	Variable dx,dy,qval,two_theta,dist
		
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	dist = sqrt(dx^2 + dy^2)
	
	two_theta = atan(dist/sdd)

	qval = 4*Pi/lam*sin(two_theta/2)
	
	return qval
End

//calculates just the q-value in the x-direction on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//
//sdd is in meters
//wavelength is in Angstroms
//
// repaired incorrect qx and qy calculation 3 dec 08 SRK (Lionel and C. Dewhurst)
// now properly accounts for qz
//
Function V_CalcQX(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY

	Variable qx,qval,phi,dx,dy,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	phi = V_FindPhi(dx,dy)
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)

	qx = qval*cos(two_theta/2)*cos(phi)
	
	return qx
End

//calculates just the q-value in the y-direction on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//sdd is in meters
//wavelength is in Angstroms
//
// repaired incorrect qx and qy calculation 3 dec 08 SRK (Lionel and C. Dewhurst)
// now properly accounts for qz
//
Function V_CalcQY(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY
	
	Variable dy,qval,dx,phi,qy,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	
	sdd *=100		//convert to cm
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	phi = V_FindPhi(dx,dy)
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)
	
	qy = qval*cos(two_theta/2)*sin(phi)
	
	return qy
End

//calculates just the z-component of the q-vector, not measured on the detector
//input/output is the same as CalcQval()
//ALL inputs are in detector coordinates
//sdd is in meters
//wavelength is in Angstroms
//
// not actually used, but here for completeness if anyone asks
//
Function V_CalcQZ(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	Variable xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY
	
	Variable dy,qval,dx,phi,qz,dist,two_theta
	
	qval = V_CalcQval(xaxval,yaxval,xctr,yctr,sdd,lam,pixSizeX,pixSizeY)
	
	sdd *=100		//convert to cm
	
	//get scattering angle to project onto flat detector => Qr = qval*cos(theta)
	dx = (xaxval - xctr)*pixSizeX		//delta x in cm
	dy = (yaxval - yctr)*pixSizeY		//delta y in cm
	dist = sqrt(dx^2 + dy^2)
	two_theta = atan(dist/sdd)
	
	qz = qval*sin(two_theta/2)
	
	return qz
End

//phi is defined from +x axis, proceeding CCW around [0,2Pi]
Threadsafe Function V_FindPhi(vx,vy)
	variable vx,vy
	
	variable phi
	
	phi = atan(vy/vx)		//returns a value from -pi/2 to pi/2
	
	// special cases
	if(vx==0 && vy > 0)
		return(pi/2)
	endif
	if(vx==0 && vy < 0)
		return(3*pi/2)
	endif
	if(vx >= 0 && vy == 0)
		return(0)
	endif
	if(vx < 0 && vy == 0)
		return(pi)
	endif
	
	
	if(vx > 0 && vy > 0)
		return(phi)
	endif
	if(vx < 0 && vy > 0)
		return(phi + pi)
	endif
	if(vx < 0 && vy < 0)
		return(phi + pi)
	endif
	if( vx > 0 && vy < 0)
		return(phi + 2*pi)
	endif
	
	return(phi)
end

Function V_SphereForm(scale,radius,delrho,bkg,x)				
	Variable scale,radius,delrho,bkg
	Variable x
	
	// variables are:							
	//[0] scale
	//[1] radius (A)
	//[2] delrho (A-2)
	//[3] background (cm-1)
	
//	Variable scale,radius,delrho,bkg				
//	scale = w[0]
//	radius = w[1]
//	delrho = w[2]
//	bkg = w[3]
	
	
	// calculates scale * f^2/Vol where f=Vol*3*delrho*((sin(qr)-qrcos(qr))/qr^3
	// and is rescaled to give [=] cm^-1
	
	Variable bes,f,vol,f2
	//
	//handle q==0 separately
	If(x==0)
		f = 4/3*pi*radius^3*delrho*delrho*scale*1e8 + bkg
		return(f)
	Endif
	
//	bes = 3*(sin(x*radius)-x*radius*cos(x*radius))/x^3/radius^3
	
	bes = 3*sqrt(pi/(2*x*radius))*BesselJ(1.5,x*radius)/(x*radius)
	
	vol = 4*pi/3*radius^3
	f = vol*bes*delrho		// [=] A
	// normalize to single particle volume, convert to 1/cm
	f2 = f * f / vol * 1.0e8		// [=] 1/cm
	
	return (scale*f2+bkg)	// Scale, then add in the background
	
End

Function V_Debye(scale,rg,bkg,x)
	Variable scale,rg,bkg
	Variable x
	
	// variables are:
	//[0] scale factor
	//[1] radius of gyration [A]
	//[2] background	[cm-1]
	
	// calculates (scale*debye)+bkg
	Variable Pq,qr2
	
	qr2=(x*rg)^2
	Pq = 2*(exp(-(qr2))-1+qr2)/qr2^2
	
	//scale
	Pq *= scale
	// then add in the background
	return (Pq+bkg)
End

// a sum of a power law and debye to approximate the scattering from a real empty cell
//
// 	make/O/D coef_ECEmp = {2.2e-8,3.346,0.0065,9.0,0.016}
//
Function V_EC_Empirical(aa,mm,scale,rg,bkg,x)
	Variable aa,mm,scale,rg,bkg
	Variable x
	
	// variables are:
	//[0] = A
	//[1] = power m
	//[2] scale factor
	//[3] radius of gyration [A]
	//[4] background	[cm-1]
	
	Variable Iq
	
	// calculates (scale*debye)+bkg
	Variable Pq,qr2
	
//	if(x*Rg < 1e-3)		//added Oct 2008 to avoid numerical errors at low arg values
//		return(scale+bkg)
//	endif
	
	Iq = aa*x^-mm
	
	qr2=(x*rg)^2
	Pq = 2*(exp(-(qr2))-1+qr2)/qr2^2
	
	//scale
	Pq *= scale
	// then add the terms up
	return (Iq + Pq + bkg)
End

// blocked beam
//
Function V_BlockedBeam(bkg,x)
	Variable bkg
	Variable x
	
	return (bkg)
End


//
// a broad peak to simulate silver behenate or vycor
//
// peak @ 0.1 ~ AgBeh
//	Make/O/D coef_BroadPeak = {1e-9, 3, 20, 100.0, 0.1,3,0.1}		
//
//
// peak @ 0.015 in middle of middle detector, maybe not "real" vycor, but that is to be resolved
//	Make/O/D coef_BroadPeak = {1e-9, 3, 20, 500.0, 0.015,3,0.1}		
//
//
Function V_BroadPeak(aa,nn,cc,LL,Qzero,mm,bgd,x)
	Variable aa,nn,cc,LL,Qzero,mm,bgd
	Variable x
	
	// variables are:							
	//[0] Porod term scaling
	//[1] Porod exponent
	//[2] Lorentzian term scaling
	//[3] Lorentzian screening length [A]
	//[4] peak location [1/A]
	//[5] Lorentzian exponent
	//[6] background
	
//	local variables
	Variable inten, qval
//	x is the q-value for the calculation
	qval = x
//	do the calculation and return the function value
	
	inten = aa/(qval)^nn + cc/(1 + (abs(qval-Qzero)*LL)^mm) + bgd

	Return (inten)
	
End



Function SetDeltaQ(folderStr,type)
	String folderStr,type

	WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + folderStr + ":det_"+type)		// 2D detector data
	
	Variable xDim,yDim,delQ
	
	xDim=DimSize(inten,0)
	yDim=DimSize(inten,1)
	
	if(xDim<yDim)
		WAVE qx = $("root:Packages:NIST:VSANS:VCALC:" + folderStr + ":qx_"+type)
		delQ = abs(qx[0][0] - qx[1][0])/2
	else
		WAVE qy = $("root:Packages:NIST:VSANS:VCALC:" + folderStr + ":qy_"+type)
		delQ = abs(qy[0][1] - qy[0][0])/2
	endif
	
	// set the global
	Variable/G $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_"+type) = delQ
//	Print "SET delQ = ",delQ," for ",type
	
	return(0)
end


//TODO -- need a switch here to dispatch to the averaging type
Proc V_BinQxQy_to_1D(folderStr,type)
	String folderStr
	String type
//	Prompt folderStr,"Pick the data folder containing 2D data",popup,getAList(4)
//	Prompt type,"detector identifier"


	V_fDoBinning_QxQy2D(folderStr, type)


/// this is for a tall, narrow slit mode	
//	V_fBinDetector_byRows(folderStr,type)
	
End


Proc V_Graph_1D_detType(folderStr,type)
	String folderStr,type
	
	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
	Display $("iBin_qxqy"+"_"+type) vs $("qBin_qxqy"+"_"+type)
	ModifyGraph mirror=2,grid=1,log=1
	ModifyGraph mode=4,marker=19,msize=2
//	ErrorBars/T=0 iBin_qxqy Y,wave=(eBin2D_qxqy,eBin2D_qxqy)		// for simulations, I don't have 2D uncertainty
	ErrorBars/T=0 $("iBin_qxqy"+"_"+type) Y,wave=($("eBin_qxqy"+"_"+type),$("eBin_qxqy"+"_"+type))
	legend
	
	SetDataFolder root:

End



//////////
//
//		Function that bins a 2D detctor panel into I(q) based on the q-value of the pixel
//		- each pixel QxQyQz has been calculated beforehand
//		- if multiple panels are selected to be combined, it is done here during the binning
//		- the setting of deltaQ step is still a little suspect (TODO)
//
//
// see the equivalent function in PlotUtils2D_v40.ipf
//
//Function fDoBinning_QxQy2D(inten,qx,qy,qz)
//
// this has been modified to accept different detector panels and to take arrays
// -- type = FL or FR or...other panel identifiers
//
// TODO "iErr" is not always defined correctly since it doesn't really apply here for data that is not 2D simulation
//
Function V_fDoBinning_QxQy2D(folderStr,type)
	String folderStr,type
	
	Variable nSets = 0
	Variable xDim,yDim
	Variable ii,jj
	Variable qVal,nq,var,avesq,aveisq
	Variable binIndex,val

	
	SetDataFolder root:Packages:NIST:VSANS:VCALC
	
// now switch on the type to determine which waves to declare and create
// since there may be more than one panel to step through. There may be two, there may be four
//

	strswitch(type)	// string switch
		case "FL":		// execute if case matches expression
		case "FR":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_FL")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+type)			// 2D q-values
			nSets = 1
			break	
								
		case "FT":		
		case "FB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_FT")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+type)			// 2D q-values
			nSets = 1
			break
			
		case "ML":		
		case "MR":		
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_ML")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+type)			// 2D q-values
			nSets = 1
			break	
					
		case "MT":		
		case "MB":		
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_MT")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+type)			// 2D q-values
			nSets = 1
			break	
					
		case "B":		
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_B")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Back" + ":det_"+type)		// 2D detector data
			WAVE/Z iErr = $("iErr_"+type)			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Back" +":qTot_"+type)			// 2D q-values
			nSets = 1
			break	
			
		case "FLR":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_FL")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+"FL")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"FL")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+"FL")			// 2D q-values
			WAVE inten2 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+"FR")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"FR")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+"FR")			// 2D q-values
			nSets = 2
			break			
		
		case "FTB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_FT")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+"FT")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"FT")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+"FT")			// 2D q-values
			WAVE inten2 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+"FB")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"FB")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+"FB")			// 2D q-values
			nSets = 2
			break		
		
		case "FLRTB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_FL")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+"FL")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"FL")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+"FL")			// 2D q-values
			WAVE inten2 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+"FR")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"FR")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+"FR")			// 2D q-values
			WAVE inten3 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+"FT")		// 2D detector data
			WAVE/Z iErr3 = $("iErr_"+"FT")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal3 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+"FT")			// 2D q-values
			WAVE inten4 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" + ":det_"+"FB")		// 2D detector data
			WAVE/Z iErr4 = $("iErr_"+"FB")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal4 = $("root:Packages:NIST:VSANS:VCALC:" + "Front" +":qTot_"+"FB")			// 2D q-values
			nSets = 4
			break		
			

		case "MLR":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_ML")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+"ML")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"ML")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+"ML")			// 2D q-values
			WAVE inten2 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+"MR")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"MR")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+"MR")			// 2D q-values
			nSets = 2
			break			
		
		case "MTB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_MT")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+"MT")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"MT")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+"MT")			// 2D q-values
			WAVE inten2 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+"MB")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"MB")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+"MB")			// 2D q-values
			nSets = 2
			break				
		
		case "MLRTB":
			NVAR delQ = $("root:Packages:NIST:VSANS:VCALC:" + "gDelQ_ML")
			WAVE inten = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+"ML")		// 2D detector data
			WAVE/Z iErr = $("iErr_"+"ML")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+"ML")			// 2D q-values
			WAVE inten2 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+"MR")		// 2D detector data
			WAVE/Z iErr2 = $("iErr_"+"MR")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal2 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+"MR")			// 2D q-values
			WAVE inten3 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+"MT")		// 2D detector data
			WAVE/Z iErr3 = $("iErr_"+"MT")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal3 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+"MT")			// 2D q-values
			WAVE inten4 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" + ":det_"+"MB")		// 2D detector data
			WAVE/Z iErr4 = $("iErr_"+"MB")			// 2D errors -- may not exist, especially for simulation
			Wave qTotal4 = $("root:Packages:NIST:VSANS:VCALC:" + "Middle" +":qTot_"+"MB")			// 2D q-values
			nSets = 4
			break									
					
		default:
			nSets = 0							// optional default expression executed
			Print "ERROR   ---- type is not recognized "
	endswitch

//	Print "delQ = ",delQ," for ",type

	if(nSets == 0)
		return(0)
	endif


//TODO: properly define the errors here - I'll have this if I do the simulation
	if(WaveExists(iErr)==0  && WaveExists(inten) != 0)
		Duplicate/O inten,iErr
		Wave iErr=iErr
//		iErr = 1+sqrt(inten+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr = sqrt(inten+0.75)			// TODO -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr2)==0 && WaveExists(inten2) != 0)
		Duplicate/O inten2,iErr2
		Wave iErr2=iErr2
//		iErr2 = 1+sqrt(inten2+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr2 = sqrt(inten2+0.75)			// TODO -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr3)==0  && WaveExists(inten3) != 0)
		Duplicate/O inten3,iErr3
		Wave iErr3=iErr3
//		iErr3 = 1+sqrt(inten3+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr3 = sqrt(inten3+0.75)			// TODO -- here I'm just using some fictional value
	endif
	if(WaveExists(iErr4)==0  && WaveExists(inten4) != 0)
		Duplicate/O inten4,iErr4
		Wave iErr4=iErr4
//		iErr4 = 1+sqrt(inten4+0.75)			// can't use this -- it applies to counts, not intensity (already a count rate...)
		iErr4 = sqrt(inten4+0.75)			// TODO -- here I'm just using some fictional value
	endif

	nq = 600

	// note that the back panel of 320x320 (1mm res) results in 447 data points!
	// - so I upped nq to 600

//******TODO****** -- where to put the averaged data -- right now, folderStr is forced to ""	
//	SetDataFolder $("root:"+folderStr)		//should already be here, but make sure...	
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"iBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"qBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"nBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"iBin2_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"eBin_qxqy"+"_"+type)
	Make/O/D/N=(nq)  $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"eBin2D_qxqy"+"_"+type)
	
	Wave iBin_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"iBin_qxqy_"+type)
	Wave qBin_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"qBin_qxqy"+"_"+type)
	Wave nBin_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"nBin_qxqy"+"_"+type)
	Wave iBin2_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"iBin2_qxqy"+"_"+type)
	Wave eBin_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"eBin_qxqy"+"_"+type)
	Wave eBin2D_qxqy = $("root:Packages:NIST:VSANS:VCALC:"+folderStr+"eBin2D_qxqy"+"_"+type)
	
	
//	delQ = abs(sqrt(qx[2]^2+qy[2]^2+qz[2]^2) - sqrt(qx[1]^2+qy[1]^2+qz[1]^2))		//use bins of 1 pixel width 
// TODO: not sure if I want to set dQ in x or y direction...
	// the short dimension is the 8mm tubes, use this direction as dQ?
	// but don't use the corner of the detector, since dQ will be very different on T/B or L/R due to the location of [0,0]
	// WRT the beam center. use qx or qy directly. Still not happy with this way...


	qBin_qxqy[] =  p*delQ	
	SetScale/P x,0,delQ,"",qBin_qxqy		//allows easy binning

	iBin_qxqy = 0
	iBin2_qxqy = 0
	eBin_qxqy = 0
	eBin2D_qxqy = 0
	nBin_qxqy = 0	//number of intensities added to each bin

// now there are situations of:
// 1 panel
// 2 panels
// 4 panels
//
// this needs to be a double loop now...

// use set 1 (no number) only
	if(nSets >= 1)
		xDim=DimSize(inten,0)
		yDim=DimSize(inten,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val = inten[ii][jj]
				if (numType(val)==0)		//count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex] += val
					iBin2_qxqy[binIndex] += val*val
					eBin2D_qxqy[binIndex] += iErr[ii][jj]*iErr[ii][jj]
					nBin_qxqy[binIndex] += 1
				endif
			endfor
		endfor
		
	endif

// add in set 2 (set 1 already done)
	if(nSets >= 2)
		xDim=DimSize(inten2,0)
		yDim=DimSize(inten2,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal2[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val = inten2[ii][jj]
				if (numType(val)==0)		//count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex] += val
					iBin2_qxqy[binIndex] += val*val
					eBin2D_qxqy[binIndex] += iErr2[ii][jj]*iErr2[ii][jj]
					nBin_qxqy[binIndex] += 1
				endif
			endfor
		endfor
		
	endif

// add in set 3 and 4 (set 1 and 2already done)
	if(nSets == 4)
		xDim=DimSize(inten3,0)
		yDim=DimSize(inten3,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal3[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val = inten3[ii][jj]
				if (numType(val)==0)		//count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex] += val
					iBin2_qxqy[binIndex] += val*val
					eBin2D_qxqy[binIndex] += iErr3[ii][jj]*iErr3[ii][jj]
					nBin_qxqy[binIndex] += 1
				endif
			endfor
		endfor
		
		
		xDim=DimSize(inten4,0)
		yDim=DimSize(inten4,1)
	
		for(ii=0;ii<xDim;ii+=1)
			for(jj=0;jj<yDim;jj+=1)
				//qTot = sqrt(qx[ii]^2 + qy[ii]^2+ qz[ii]^2)
				qVal = qTotal4[ii][jj]
				binIndex = trunc(x2pnt(qBin_qxqy, qVal))
				val = inten4[ii][jj]
				if (numType(val)==0)		//count only the good points, ignore Nan or Inf
					iBin_qxqy[binIndex] += val
					iBin2_qxqy[binIndex] += val*val
					eBin2D_qxqy[binIndex] += iErr4[ii][jj]*iErr4[ii][jj]
					nBin_qxqy[binIndex] += 1
				endif
			endfor
		endfor
		
	endif


// after looping through all of the data on the panels, calculate errors on I(q),
// just like in CircSectAve.ipf
	for(ii=0;ii<nq;ii+=1)
		if(nBin_qxqy[ii] == 0)
			//no pixels in annuli, data unknown
			iBin_qxqy[ii] = 0
			eBin_qxqy[ii] = 1
			eBin2D_qxqy[ii] = NaN
		else
			if(nBin_qxqy[ii] <= 1)
				//need more than one pixel to determine error
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				eBin_qxqy[ii] = 1
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			else
				//assume that the intensity in each pixel in annuli is normally distributed about mean...
				iBin_qxqy[ii] /= nBin_qxqy[ii]
				avesq = iBin_qxqy[ii]^2
				aveisq = iBin2_qxqy[ii]/nBin_qxqy[ii]
				var = aveisq-avesq
				if(var<=0)
					eBin_qxqy[ii] = 1e-6
				else
					eBin_qxqy[ii] = sqrt(var/(nBin_qxqy[ii] - 1))
				endif
				// and calculate as it is propagated pixel-by-pixel
				eBin2D_qxqy[ii] /= (nBin_qxqy[ii])^2
			endif
		endif
	endfor
	
	eBin2D_qxqy = sqrt(eBin2D_qxqy)		// as equation (3) of John's memo
	
	// find the last non-zero point, working backwards
	val=nq
	do
		val -= 1
	while((nBin_qxqy[val] == 0) && val > 0)
	
//	print val, nBin_qxqy[val]
	DeletePoints val, nq-val, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy

	if(val == 0)
		// all the points were deleted
		return(0)
	endif
	
	
	// since the beam center is not always on the detector, many of the low Q bins will have zero pixels
	// find the first non-zero point, working forwards
	val = -1
	do
		val += 1
	while(nBin_qxqy[val] == 0)	
	DeletePoints 0, val, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy

	// ?? there still may be a point in the q-range that gets zero pixel contribution - so search this out and get rid of it
	val = numpnts(nBin_qxqy)-1
	do
		if(nBin_qxqy[val] == 0)
			DeletePoints val, 1, iBin_qxqy,qBin_qxqy,nBin_qxqy,iBin2_qxqy,eBin_qxqy,eBin2D_qxqy
		endif
		val -= 1
	while(val>0)
	
	SetDataFolder root:
	
	return(0)
End

