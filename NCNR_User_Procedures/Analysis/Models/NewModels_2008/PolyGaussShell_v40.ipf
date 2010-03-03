#pragma rtGlobals=1		// Use modern global access method.#pragma IgorVersion=6.1////////////////////////////////////////////////////// calculates the scattering from a polydisperse spherical shell with a diffuse interface//// - the radius of the shell has a gaussian polydispersity// - the shell has a Gaussian SLD profile, rather than a slab// - currently normalized by the total sphere excluded volume//// M. Gradzielski, D. Langevin, L. Magid, R. Strey, JPC 99 (1995) 13232 //// keep polydispersity < 0.35 for approximations to be valid////////////////////////////////////////////////////////Proc PlotGaussianShell(num,qmin,qmax)	Variable num=200, qmin=0.001, qmax=0.7	Prompt num "Enter number of data points for model: "	Prompt qmin "Enter minimum q-value (�^-1) for model: " 	Prompt qmax "Enter maximum q-value (�^-1) for model: "//	Make/O/D/n=(num) xwave_GaussianShell, ywave_GaussianShell	xwave_GaussianShell =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	Make/O/D coef_GaussianShell = {1.,100,5,0.2,1e-6,6.34e-6,0}			make/o/t parameters_GaussianShell = {"scale","Radius (A)","Shell thickness Std. Dev. (A)","radius polydispersity","SLD Shell (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}	Edit parameters_GaussianShell, coef_GaussianShell		Variable/G root:g_GaussianShell	g_GaussianShell := GaussianShell(coef_GaussianShell, ywave_GaussianShell, xwave_GaussianShell)	Display ywave_GaussianShell vs xwave_GaussianShell	ModifyGraph marker=29, msize=2, mode=4	ModifyGraph log=1,grid=1,mirror=2	Label bottom "q (�\\S-1\\M) "	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		AddModelToStrings("GaussianShell","coef_GaussianShell","parameters_GaussianShell","GaussianShell")//End////no input parameters are necessary, it MUST use the experimental q-values// from the experimental data read in from an AVE/QSIG data file////////////////////////////////////////////////////// - sets up a dependency to a wrapper, not the actual SmearedModelFunctionProc PlotSmearedGaussianShell(str)									String str	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)		// if any of the resolution waves are missing => abort	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)		Abort	endif		SetDataFolder $("root:"+str)		// Setup parameter table for model function	Make/O/D smear_coef_GaussianShell = {1.,100,5,0.2,1e-6,6.34e-6,0}			make/o/t smear_parameters_GaussianShell = {"scale","Radius (A)","Shell thickness Std. Dev. (A)","radius polydispersity","SLD Shell (A-2)","SLD solvent (A-2)","bkgd (cm-1)"}	Edit smear_parameters_GaussianShell,smear_coef_GaussianShell					//display parameters in a table		// output smeared intensity wave, dimensions are identical to experimental QSIG values	// make extra copy of experimental q-values for easy plotting	Duplicate/O $(str+"_q") smeared_GaussianShell,smeared_qvals	SetScale d,0,0,"1/cm",smeared_GaussianShell						Variable/G gs_GaussianShell=0	gs_GaussianShell := fSmearedGaussianShell(smear_coef_GaussianShell,smeared_GaussianShell,smeared_qvals)	//this wrapper fills the STRUCT		Display smeared_GaussianShell vs smeared_qvals	ModifyGraph log=1,marker=29,msize=2,mode=4	Label bottom "q (�\\S-1\\M)"	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		SetDataFolder root:	AddModelToStrings("SmearedGaussianShell","smear_coef_GaussianShell","smear_parameters_GaussianShell","GaussianShell")End////AAO version, uses XOP if available// simply calls the original single point calculation with// a wave assignment (this will behave nicely if given point ranges)Function GaussianShell(cw,yw,xw) : FitFunc	Wave cw,yw,xw	#if exists("GaussianShellX")	yw = GaussianShellX(cw,xw)#else	yw = fGaussianShell(cw,xw)#endif	return(0)End//// unsmeared model calculation//Function fGaussianShell(w,x) : FitFunc	Wave w	Variable x		// variables are:								//[0] scale	//[1] radius (�)	//[2] thick (�) (thickness parameter - this is the std. dev. of the Gaussian width of the shell)	//[3] polydispersity of the radius	//[4] sld shell (�-2)	//[5] sld solvent	//[6] background (cm-1)		Variable scale,rad,delrho,bkg,del,thick,pd,sig,zf	Variable t1,t2,t3,t4,retval,exfact,vshell,vexcl,sldShell,sldSolvent	scale = w[0]	rad = w[1]	thick = w[2]	pd = w[3]	sldShell = w[4]	sldSolvent = w[5]	bkg = w[6]		delrho = w[4] - w[5]	sig = pd*rad		///APPROXIMATION (see eqn 4 - but not a bad approximation)	// del is the equivalent shell thickness with sharp boundaries, centered at mean radius	del = thick*sqrt(2*pi)		// calculate the polydisperse shell volume and the excluded volume	vshell=4*pi/3*( (rad+del/2)^3 - (rad-del/2)^3 ) *(1+pd^2)	vexcl=4*pi/3*( (rad+del/2)^3 ) *(1+pd^2)		//intensity, eqn 9(a-d)	exfact = exp(-2*sig^2*x^2)		t1 = 0.5*x^2*thick^4*(1+cos(2*x*rad)*exfact)	t2 = x*thick^2*(rad*sin(2*x*rad) + 2*x*sig^2*cos(2*x*rad))*exfact	t3 = 0.5*rad^2*(1-cos(2*x*rad)*exfact)	t4 = 0.5*sig^2*(1+4*x*rad*sin(2*x*rad)*exfact+cos(2*x*rad)*(4*sig^2*x^2-1)*exfact)		retval = t1+t2+t3+t4	retval *= exp(-1*x*x*thick*thick)	retval *= (del*del/x/x)	retval *= 16*pi*pi*delrho*delrho*scale	retval *= 1e8		//NORMALIZED by the AVERAGE shell volume, since scale is the volume fraction of material//	retval /= vshell	retval /= vexcl	//re-normalize by polydisperse sphere volume, Gaussian distribution	retval /= (1+3*pd^2)		retval += bkg			return(retval)	End//CH#4	///////////////////////////////////////////////////////////////// smeared model calculation//// you don't need to do anything with this function, as long as// your GaussianShell works correctly, you get the resolution-smeared// version for free.//// this is all there is to the smeared model calculation!Function SmearedGaussianShell(s) : FitFunc	Struct ResSmearAAOStruct &s//	the name of your unsmeared model (AAO) is the first argument	Smear_Model_20(GaussianShell,s.coefW,s.xW,s.yW,s.resW)	return(0)End///////////////////////////////////////////////////////////////// nothing to change here////wrapper to calculate the smeared model as an AAO-Struct// fills the struct and calls the ususal function with the STRUCT parameter//// used only for the dependency, not for fitting//Function fSmearedGaussianShell(coefW,yW,xW)	Wave coefW,yW,xW		String str = getWavesDataFolder(yW,0)	String DF="root:"+str+":"		WAVE resW = $(DF+str+"_res")		STRUCT ResSmearAAOStruct fs	WAVE fs.coefW = coefW		WAVE fs.yW = yW	WAVE fs.xW = xW	WAVE fs.resW = resW		Variable err	err = SmearedGaussianShell(fs)		return (0)End