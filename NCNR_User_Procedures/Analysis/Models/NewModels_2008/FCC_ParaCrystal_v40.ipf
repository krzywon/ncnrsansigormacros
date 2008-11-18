#pragma rtGlobals=1		// Use modern global access method.#pragma IgorVersion=6.0////// FCC paracrystal, powder average//// VERY slow, since the function is so ill-behaved and needs LOTS of quadrature// points. Adaptive methods were even slower and troublesom to converge,// although in theory they should be a better choice than blindly increasing the number of points.//// using 150 points for the quadrature// 76 points for the smearing is untested////// Original implementation - Danilo Pozzo//		modified and modernized for more efficient integration SRK Nov 2008////REFERENCE //Hideki Matsuoka etal. Physical Review B, Vol 36 Num 3, p1754 1987   ORIGINAL PAPER//Hideki Matsuoka etal. Physical Review B, Vol 41 Num 6, p3854 1990   CORRECTIONS TO PAPER//////////////////////////////////////////////////////Proc PlotFCC_ParaCrystal(num,qmin,qmax)	Variable num=100, qmin=0.001, qmax=0.7	Prompt num "Enter number of data points for model: "	Prompt qmin "Enter minimum q-value (�^-1) for model: " 	Prompt qmax "Enter maximum q-value (�^-1) for model: "//	Make/O/D/n=(num) xwave_FCC_ParaCrystal, ywave_FCC_ParaCrystal	xwave_FCC_ParaCrystal =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	Make/O/D coef_FCC_ParaCrystal = {1,220,0.06,40,3e-6,6.3e-6,0.0}	make/o/t parameters_FCC_ParaCrystal = {"scale","Nearest Neighbor (A)","distortion, g","Sphere Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)", "Background (cm-1)"}		Edit parameters_FCC_ParaCrystal, coef_FCC_ParaCrystal		Variable/G root:gNordFCC=150		Variable/G root:g_FCC_ParaCrystal	g_FCC_ParaCrystal := FCC_ParaCrystal(coef_FCC_ParaCrystal, ywave_FCC_ParaCrystal, xwave_FCC_ParaCrystal)	Display ywave_FCC_ParaCrystal vs xwave_FCC_ParaCrystal	ModifyGraph marker=29, msize=2, mode=4	ModifyGraph grid=1,mirror=2	ModifyGraph log=0	Label bottom "q (�\\S-1\\M) "	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		AddModelToStrings("FCC_ParaCrystal","coef_FCC_ParaCrystal","FCC_ParaCrystal")//End////this macro sets up all the necessary parameters and waves that are//needed to calculate the  smeared model function.////no input parameters are necessary, it MUST use the experimental q-values// from the experimental data read in from an AVE/QSIG data file////////////////////////////////////////////////////// - sets up a dependency to a wrapper, not the actual SmearedModelFunctionProc PlotSmearedFCC_ParaCrystal(str)									String str	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)		// if any of the resolution waves are missing => abort	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)		Abort	endif		SetDataFolder $("root:"+str)		// Setup parameter table for model function	Make/O/D smear_coef_FCC_ParaCrystal = {1,220,0.06,40,3e-6,6.3e-6,0.0}	make/o/t smear_parameters_FCC_ParaCrystal = {"scale","Nearest Neighbor (A)","distortion, g","Sphere Radius (A)","SLD sphere (A-2)","SLD solvent (A-2)", "Background (cm-1)"}	Edit smear_parameters_FCC_ParaCrystal,smear_coef_FCC_ParaCrystal					//display parameters in a table		// output smeared intensity wave, dimensions are identical to experimental QSIG values	// make extra copy of experimental q-values for easy plotting	Duplicate/O $(str+"_q") smeared_FCC_ParaCrystal,smeared_qvals	SetScale d,0,0,"1/cm",smeared_FCC_ParaCrystal		Variable/G gNordFCC = 150			Variable/G gs_FCC_ParaCrystal=0	gs_FCC_ParaCrystal := fSmearedFCC_ParaCrystal(smear_coef_FCC_ParaCrystal,smeared_FCC_ParaCrystal,smeared_qvals)	//this wrapper fills the STRUCT		Display smeared_FCC_ParaCrystal vs smeared_qvals	ModifyGraph marker=29,msize=2,mode=4	ModifyGraph log=0	Label bottom "q (�\\S-1\\M)"	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		SetDataFolder root:	AddModelToStrings("SmearedFCC_ParaCrystal","smear_coef_FCC_ParaCrystal","FCC_ParaCrystal")End// nothing to change here////AAO version, uses XOP if available// simply calls the original single point calculation with// a wave assignment (this will behave nicely if given point ranges)Function FCC_ParaCrystal(cw,yw,xw) : FitFunc	Wave cw,yw,xw	#if exists("FCC_ParaCrystalX")	yw = FCC_ParaCrystalX(cw,xw)#else	yw = fFCC_ParaCrystal(cw,xw)#endif	return(0)End//// unsmeared model calculation//Function fFCC_ParaCrystal(w,x) : FitFunc	Wave w	Variable x	//	 Input (fitting) variables are not used//	you would give them nice names	Variable integral,loLim,upLim	loLim = 0	upLim = 2*Pi		Variable/G root:gDumY=0		//root:gDumX=0		Variable scale,Dnn,gg,Rad,contrast,background,yy,latticeScale,sld,sldSolv	scale = w[0]	Dnn = w[1] //Nearest neighbor distance A	gg = w[2] //Paracrystal distortion factor	Rad = w[3] //Sphere radius	sld = w[4]	sldSolv = w[5]	background = w[6] 			contrast = sld - sldSolv		latticeScale = 4*(4/3)*pi*(Rad^3)/((Dnn*(2^0.5))^3)	NVAR/Z nord=root:gNordFCC	if(NVAR_Exists(nord)!=1)		nord=20	endif		integral = IntegrateFn_N(Integrand_FCC_Outer,loLim,upLim,w,x,nord)			integral *= SphereForm_FCC(Rad,contrast,x)*scale*latticeScale//	integral *= scale		//for testing, returns Z(q) only	integral += background			Return (integral)	End// the outer integral is also an integralFunction Integrand_FCC_Outer(w,x,dum)	Wave w	Variable x,dum			NVAR yy = root:gDumY			yy = dum					// save the current dummy yy for use in the inner loop	Variable retVal,loLim,upLim	//	loLim = 0	upLim = Pi	NVAR/Z nord=root:gNordFCC	if(NVAR_Exists(nord)!=1)		nord=20	endif		retVal = IntegrateFn_N(Integrand_FCC_Inner,loLim,upLim,w,x,nord)		return(retVal)End//returns the value of the integrand of the inner integralFunction Integrand_FCC_Inner(w,qq,dum)	Wave w	Variable qq,dum		NVAR yy = root:gDumY		//use the yy value from the outer loop	Variable xx,retVal	xx = dum	retVal = FCC_Integrand(w,qq,xx,yy)		return(retVal)EndFunction FCC_Integrand(w,qq,xx,yy)	Wave w	Variable qq,xx,yy		Variable retVal,temp1,temp3,aa,Da,Dnn,gg	Dnn = w[1] //Nearest neighbor distance A	gg = w[2] //Paracrystal distortion factor//	aa = Dnn*(2^0.5)		//Danilo's version. As defined in paper, |bi| = a	aa = Dnn	Da = gg*aa		temp1 = qq*qq*Da*Da	temp3 = qq*aa		retVal = FCCeval(xx,yy,temp1,temp3)	retVal /=4*Pi		return(retVal)endFunction FCCeval(Theta,Phi,temp1,temp3)	Variable Theta,Phi,temp1,temp3	Variable temp6,temp7,temp8,temp9,temp10	Variable result		temp6 = sin(Theta)	temp7 = sin(Theta)*sin(Phi)+cos(Theta)	temp8 = -1*sin(Theta)*cos(Phi)+cos(Theta)	temp9 = -1*sin(Theta)*cos(Phi)+sin(Theta)*sin(Phi)	temp10 = exp((-1/8)*temp1*((temp7^2)+(temp8^2)+(temp9^2)))	result = ((1-(temp10^2))^3)*temp6/((1-2*temp10*cos(0.5*temp3*(temp7))+(temp10^2))*(1-2*temp10*cos(0.5*temp3*(temp8))+(temp10^2))*(1-2*temp10*cos(0.5*temp3*(temp9))+(temp10^2)))		return (result)endFunction SphereForm_FCC(radius,delrho,x)						Variable radius,delrho,x		// variables are:								//[2] radius (�)	//[3] delrho (�-2)	//[4] background (cm-1)		// calculates scale * f^2/Vol where f=Vol*3*delrho*(sin(qr)-qrcos(qr))/qr^3	// and is rescaled to give [=] cm^-1		Variable bes,f,vol,f2	////handle q==0 separately	If(x==0)		f = 4/3*pi*radius^3*delrho*delrho*1e8		return(f)	Endif		bes = 3*(sin(x*radius)-x*radius*cos(x*radius))/x^3/radius^3	vol = 4*pi/3*radius^3	f = vol*bes*delrho		// [=] �	// normalize to single particle volume, convert to 1/cm	f2 = f * f / vol * 1.0e8		// [=] 1/cm		return (f2)		End///////////////////////////////////////////////////////////////// smeared model calculation//Function SmearedFCC_ParaCrystal(s) : FitFunc	Struct ResSmearAAOStruct &s//	the name of your unsmeared model (AAO) is the first argument	Smear_Model_76(FCC_ParaCrystal,s.coefW,s.xW,s.yW,s.resW)	return(0)End///////////////////////////////////////////////////////////////////wrapper to calculate the smeared model as an AAO-Struct// fills the struct and calls the ususal function with the STRUCT parameter//// used only for the dependency, not for fitting//Function fSmearedFCC_ParaCrystal(coefW,yW,xW)	Wave coefW,yW,xW		String str = getWavesDataFolder(yW,0)	String DF="root:"+str+":"		WAVE resW = $(DF+str+"_res")		STRUCT ResSmearAAOStruct fs	WAVE fs.coefW = coefW		WAVE fs.yW = yW	WAVE fs.xW = xW	WAVE fs.resW = resW		Variable err	err = SmearedFCC_ParaCrystal(fs)		return (0)End