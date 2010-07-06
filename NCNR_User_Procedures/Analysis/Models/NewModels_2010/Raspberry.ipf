#pragma rtGlobals=1		// Use modern global access method.#pragma IgorVersion=6.0////////////////////////////////////////////////////// Raspberry model - Pozzo & Larson// Default parameters are for a 5000A hexadecane drop stabilized by 100A silica particles// in D2O. The particles are 50% inserted into the interface (delta = 0) and surface coverage is 50%//////////////////////////////////////////////////////this macro sets up all the necessary parameters and waves that are//needed to calculate the model function.//Macro PlotRaspberry(num,qmin,qmax)	Variable num=500, qmin=1e-5, qmax=0.7	Prompt num "Enter number of data points for model: "	Prompt qmin "Enter minimum q-value (�^-1) for model: " 	Prompt qmax "Enter maximum q-value (�^-1) for model: "//	Make/O/D/n=(num) xwave_Raspberry, ywave_Raspberry	xwave_Raspberry =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	Make/O/D coef_Raspberry = {0.05,5000,-4e-7,0.005,100,0.4,3.5e-6,0,6.3e-6,0.0}				make/o/t parameters_Raspberry =  {"vf Large","Radius Large (A)","SLD Large sphere (A-2)","vf Small", "Radius Small (A)","surface coverage","SLD Small sphere (A-2)","delta","SLD solvent (A-2)","bkgd (cm-1)"}	Edit parameters_Raspberry, coef_Raspberry		Variable/G root:g_Raspberry	g_Raspberry := Raspberry(coef_Raspberry, ywave_Raspberry, xwave_Raspberry)	Display ywave_Raspberry vs xwave_Raspberry	ModifyGraph marker=29, msize=2, mode=4	ModifyGraph log=1,grid=1,mirror=2	Label bottom "q (�\\S-1\\M) "	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		AddModelToStrings("Raspberry","coef_Raspberry","parameters_Raspberry","Raspberry")//End////this macro sets up all the necessary parameters and waves that are//needed to calculate the  smeared model function.////no input parameters are necessary, it MUST use the experimental q-values// from the experimental data read in from an AVE/QSIG data file////////////////////////////////////////////////////// - sets up a dependency to a wrapper, not the actual SmearedModelFunctionMacro PlotSmearedRaspberry(str)									String str	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)		// if any of the resolution waves are missing => abort	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)		Abort	endif		SetDataFolder $("root:"+str)		// Setup parameter table for model function	Make/O/D smear_coef_Raspberry = {0.05,5000,-4e-7,0.005,100,0.4,3.5e-6,0,6.3e-6,0.0}	make/o/t smear_parameters_Raspberry = {"vf Large","Radius Large (A)","SLD Large sphere (A-2)","vf Small", "Radius Small (A)","surface coverage","SLD Small sphere (A-2)","delta","SLD solvent (A-2)","bkgd (cm-1)"}	Edit smear_parameters_Raspberry,smear_coef_Raspberry					//display parameters in a table		// output smeared intensity wave, dimensions are identical to experimental QSIG values	// make extra copy of experimental q-values for easy plotting	Duplicate/O $(str+"_q") smeared_Raspberry,smeared_qvals	SetScale d,0,0,"1/cm",smeared_Raspberry						Variable/G gs_Raspberry=0	gs_Raspberry := fSmearedRaspberry(smear_coef_Raspberry,smeared_Raspberry,smeared_qvals)	//this wrapper fills the STRUCT		Display smeared_Raspberry vs smeared_qvals	ModifyGraph log=1,marker=29,msize=2,mode=4	Label bottom "q (�\\S-1\\M)"	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		SetDataFolder root:	AddModelToStrings("SmearedRaspberry","smear_coef_Raspberry","smear_parameters_Raspberry","Raspberry")EndMacro CalcRaspberryStats()	Variable vfL,rL,sldL,vfS,rS,sldS,deltaS,delrhoL,delrhoS,bkg,sldSolv,qval	,aSs		vfL = coef_Raspberry[0]	rL = coef_Raspberry[1]	sldL = coef_Raspberry[2]	vfS = coef_Raspberry[3]	rS = coef_Raspberry[4]	aSs = coef_Raspberry[5]	sldS = coef_Raspberry[6]	deltaS = coef_Raspberry[7]	sldSolv = coef_Raspberry[8]	bkg = coef_Raspberry[9]	Variable fractionsmall,Np,VL,VS	VL = 4*pi/3*rL^3	VS = 4*pi/3*rS^3		//Np = aSs*0.04*(rS/(rL+deltaS))*(VL/VS)	Np = aSs*4*((rL+deltaS)/rS)^2	fractionsmall = Np*vfL*VS/vfS/VL	print "Fraction small on large = "+num2str(fractionsmall)+"\r"	print "Number of small particles on large = "+num2str(Np)+"\r"EndMacro PlotRaspberrySq()	setdatafolder root:	Variable vfL,rL,sldL,vfS,rS,sldS,deltaS,delrhoL,delrhoS,bkg,sldSolv,qval	,aSs	vfL = coef_Raspberry[0]	rL = coef_Raspberry[1]	delrhoL = coef_Raspberry[2]	vfS = coef_Raspberry[3]	rS = coef_Raspberry[4]	aSs = coef_Raspberry[5]	delrhoS = coef_Raspberry[6]	deltaS = coef_Raspberry[7]					Duplicate/O xwave_Raspberry ywave_sfLS_Rasp		Duplicate/O xwave_Raspberry ywave_sfSS_Rasp		Variable psiL,psiS,vol,f2	Variable VL,VS,slT,Np,fSs	VL = 4*pi/3*rL^3	VS = 4*pi/3*rS^3	Np = aSs*4*((rL+deltaS)/rS)^2	ywave_sfLS_Rasp = fRaspBes(xwave_Raspberry,rL)*fRaspBes(xwave_Raspberry,rS)*(sin(xwave_Raspberry*(rL+deltaS*rS))/xwave_Raspberry/(rL+deltaS*rS))	ywave_sfSS_Rasp = fRaspBes(xwave_Raspberry,rS)*fRaspBes(xwave_Raspberry,rS)*(sin(xwave_Raspberry*(rL+deltaS*rS))/xwave_Raspberry/(rL+deltaS*rS))^2	Display ywave_sfLS_Rasp vs xwave_Raspberry	AppendToGraph ywave_sfSS_Rasp vs xwave_Raspberry	ModifyGraph log(bottom)=1End// nothing to change here////AAO version, uses XOP if available// simply calls the original single point calculation with// a wave assignment (this will behave nicely if given point ranges)Function Raspberry(cw,yw,xw) : FitFunc	Wave cw,yw,xw	#if exists("RaspberryX")	yw = RaspberryX(cw,xw)#else	yw = fRaspberry(cw,xw)#endif	return(0)End// you should write your function to calculate the intensity// for a single q-value (that's the input parameter x)// based on the wave (array) of parameters that you send it (w)//// unsmeared model calculation//Function fRaspberry(w,x) : FitFunc	Wave w	Variable x		// variables are:								//[0] volume fraction large spheres	//[1] radius large sphere (�)	//[2] sld large sphere (�-2)	//[3] volume fraction small spheres	//[4] fraction of small spheres at surface	//[5] radius small sphere (A)	//[6] sld small sphere	//[7] small sphere penetration (A) 	//[8] sld solvent	//[9] background (cm-1)		Variable vfL,rL,sldL,vfS,rS,sldS,deltaS,delrhoL,delrhoS,bkg,sldSolv,qval	,aSs		vfL = w[0]	rL = w[1]	sldL = w[2]	vfS = w[3]	rS = w[4]	aSs = w[5]	sldS = w[6]	deltaS = w[7]	sldSolv = w[8]	bkg = w[9]		delrhoL = abs(sldL - sldSolv)	delrhoS = abs(sldS - sldSolv)			Variable VL,VS,Np,f2,fSs		VL = 4*pi/3*rL^3	VS = 4*pi/3*rS^3		//Np = vfS*fSs*VL/vfL/VS	//Np = aSs*4*(rS/(rL+deltaS))*(VL/VS)	Np = aSs*4*((rL+deltaS)/rS)^2		fSs = Np*vfL*VS/vfS/VL		Make/O/N=9 rasp_temp	rasp_temp[0] = w[0]	rasp_temp[1] = w[1]	rasp_temp[2] = delrhoL	rasp_temp[3] = w[3]	rasp_temp[4] = w[4]	rasp_temp[5] = w[5]	rasp_temp[6] = delrhoS	rasp_temp[7] = w[7]		//f2 = (vfL*delrhoL^2*VL + vfS*fSs*Np*delrhoS^2*VS)*fRaspberryKernel(rasp_temp,x) 	f2 = fRaspberryKernel(rasp_temp,x)	f2+= vfS*(1-fSs)*delrhoS^2*VS*fRaspBes(x,rS)*fRaspBes(x,rS)		// normalize to single particle volume and convert to 1/cm	f2 *= 1e8		// [=] 1/cm		return (f2+bkg)	// Scale, then add in the background	EndFunction fRaspberryKernel(w,x)	Wave w	Variable x	// variables are:								//[0] volume fraction large spheres	//[1] radius large sphere (�)	//[2] sld large sphere (�-2)	//[3] volume fraction small spheres	//[4] fraction of small spheres at surface	//[5] radius small sphere (A)	//[6] sld small sphere	//[7] small sphere penetration (A) 	//[8] sld solvent		Variable vfL,rL,sldL,vfS,rS,sldS,deltaS,delrhoL,delrhoS,bkg,sldSolv,qval	,aSs	vfL = w[0]	rL = w[1]	delrhoL = w[2]	vfS = w[3]	rS = w[4]	aSs = w[5]	delrhoS = w[6]	deltaS = w[7]				qval = x		//rename the input q-value, purely for readability			Variable psiL,psiS,vol,f2	Variable sfLS,sfSS	Variable VL,VS,slT,Np,fSs	VL = 4*pi/3*rL^3	VS = 4*pi/3*rS^3	Np = aSs*4*(rS/(rL+deltaS))*VL/VS 	//Np = aSs*4*((rL+deltaS)/rS)^2	fSs = Np*vfL*VS/vfS/VL	slT = delrhoL*VL + Np*delrhoS*VS	psiL = fRaspBes(qval,rL)	psiS = fRaspBes(qval,rS)	sfLS = psiL*psiS*(sin(qval*(rL+deltaS*rS))/qval/(rL+deltaS*rS))	sfSS = psiS*psiS*(sin(qval*(rL+deltaS*rS))/qval/(rL+deltaS*rS))^2			f2 = delrhoL^2*VL^2*psiL^2 	f2 += Np*delrhoS^2*VS^2*psiS^2 	f2 += Np*(Np-1)*delrhoS^2*VS^2*sfSS 	f2 += 2*Np*delrhoL*delrhoS*VL*VS*sfLS	if (f2 != 0)		f2 = f2/slT/slT	endif		f2 = f2*(vfL*delrhoL^2*VL + vfS*fSs*Np*delrhoS^2*VS)		return f2EndFunction fRaspBes(Qval,Rad)	Variable Qval,Rad		Variable retval		retval = 3*(sin(qval*rad)-qval*rad*cos(qval*rad))/qval^3/rad^3	return retvalEnd///////////////////////////////////////////////////////////////// smeared model calculation//// you don't need to do anything with this function, as long as// your Raspberry works correctly, you get the resolution-smeared// version for free.//// this is all there is to the smeared model calculation!Function SmearedRaspberry(s) : FitFunc	Struct ResSmearAAOStruct &s//	the name of your unsmeared model (AAO) is the first argument	Smear_Model_20(Raspberry,s.coefW,s.xW,s.yW,s.resW)	return(0)End///////////////////////////////////////////////////////////////// nothing to change here////wrapper to calculate the smeared model as an AAO-Struct// fills the struct and calls the ususal function with the STRUCT parameter//// used only for the dependency, not for fitting//Function fSmearedRaspberry(coefW,yW,xW)	Wave coefW,yW,xW		String str = getWavesDataFolder(yW,0)	String DF="root:"+str+":"		WAVE resW = $(DF+str+"_res")		STRUCT ResSmearAAOStruct fs	WAVE fs.coefW = coefW		WAVE fs.yW = yW	WAVE fs.xW = xW	WAVE fs.resW = resW		Variable err	err = SmearedRaspberry(fs)		return (0)End