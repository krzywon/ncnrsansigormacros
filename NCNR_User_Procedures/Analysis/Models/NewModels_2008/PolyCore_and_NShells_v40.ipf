#pragma rtGlobals=1		// Use modern global access method.#pragma IgorVersion=6.0//////////////////////////////////////////////////// this function is for the form factor of a  with some// number of shells around a central core (currently 1-2-3-4)//// monodisperse and polydisperse (and smeared) versions are included// - for the polydisperse models, only polydispersity of the core is taken// into account, and dPolyOne numerically. for a Schulz distribution, this// should be possible to do analytically, whith a great savings in computation// time.//// It may also be useful to think of scenarios where the layers as well are// polydisperse - to break up the very regular spacing of the layers, which// is not a very natural structure.//// 03 MAR 04 SRK// 07 AUG 08 AJJ - redone for new version of software// 08 AUG 08 AJJ - bug fixed three and four shell models.////////////////////////////////////////////////#include "Core_and_NShells_v40"//this macro sets up all the necessary parameters and waves that are//needed to calculate the model function.//Proc PlotPolyOneShell(num,qmin,qmax)	Variable num=200, qmin=0.001, qmax=0.7	Prompt num "Enter number of data points for model: "	Prompt qmin "Enter minimum q-value (�^-1) for model: " 	Prompt qmax "Enter maximum q-value (�^-1) for model: "//	Make/O/D/n=(num) xwave_PolyOneShell, ywave_PolyOneShell	xwave_PolyOneShell =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	Make/O/D coef_PolyOneShell = {1.,60,0.1,6.4e-6,10,1e-6,6.4e-6,0.001}	make/o/t parameters_PolyOneShell = {"scale","core radius (A)","Core Polydispersity(0,1)","Core SLD (A-2)","Shell thickness (A)","Shell SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}	Edit parameters_PolyOneShell, coef_PolyOneShell		Variable/G root:g_PolyOneShell	g_PolyOneShell := PolyOneShell(coef_PolyOneShell, ywave_PolyOneShell, xwave_PolyOneShell)	Display ywave_PolyOneShell vs xwave_PolyOneShell	ModifyGraph marker=29, msize=2, mode=4	ModifyGraph log=1,grid=1,mirror=2	Label bottom "q (�\\S-1\\M) "	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		AddModelToStrings("PolyOneShell","coef_PolyOneShell","parameters_PolyOneShell","PolyOneShell")//EndProc PlotPolyTwoShell(num,qmin,qmax)	Variable num=200, qmin=0.001, qmax=0.7	Prompt num "Enter number of data points for model: "	Prompt qmin "Enter minimum q-value (�^-1) for model: " 	Prompt qmax "Enter maximum q-value (�^-1) for model: "//	Make/O/D/n=(num) xwave_PolyTwoShell, ywave_PolyTwoShell	xwave_PolyTwoShell =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	Make/O/D coef_PolyTwoShell = {1.,60,0.1,6.4e-6,10,1e-6,10,2e-6,6.4e-6,0.001}	make/o/t parameters_PolyTwoShell = {"scale","core radius (A)","Core Polydispersity(0,1)","Core SLD (A-2)","Shell 1 thickness","Shell 1 SLD (A-2)","Shell 2 thickness","Shell 2 SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}	Edit parameters_PolyTwoShell, coef_PolyTwoShell		Variable/G root:g_PolyTwoShell	g_PolyTwoShell := PolyTwoShell(coef_PolyTwoShell, ywave_PolyTwoShell, xwave_PolyTwoShell)	Display ywave_PolyTwoShell vs xwave_PolyTwoShell	ModifyGraph marker=29, msize=2, mode=4	ModifyGraph log=1,grid=1,mirror=2	Label bottom "q (�\\S-1\\M) "	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		AddModelToStrings("PolyTwoShell","coef_PolyTwoShell","parameters_PolyTwoShell","PolyTwoShell")//EndProc PlotPolyThreeShell(num,qmin,qmax)	Variable num=200, qmin=0.001, qmax=0.7	Prompt num "Enter number of data points for model: "	Prompt qmin "Enter minimum q-value (�^-1) for model: " 	Prompt qmax "Enter maximum q-value (�^-1) for model: "//	Make/O/D/n=(num) xwave_PolyThreeShell, ywave_PolyThreeShell	xwave_PolyThreeShell =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	Make/O/D coef_PolyThreeShell ={1.,60,0.1,6.4e-6,10,1e-6,10,2e-6,10,3e-6,6.4e-6,0.001}	make/o/t parameters_PolyThreeShell = {"scale","core radius (A)","Core Polydispersity(0,1)","Core SLD (A-2)","Shell 1 thickness","Shell 1 SLD (A-2)","Shell 2 thickness","Shell 2 SLD (A-2)","Shell 3 thickness","Shell 3 SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}	Edit parameters_PolyThreeShell, coef_PolyThreeShell		Variable/G root:g_PolyThreeShell	g_PolyThreeShell := PolyThreeShell(coef_PolyThreeShell, ywave_PolyThreeShell, xwave_PolyThreeShell)	Display ywave_PolyThreeShell vs xwave_PolyThreeShell	ModifyGraph marker=29, msize=2, mode=4	ModifyGraph log=1,grid=1,mirror=2	Label bottom "q (�\\S-1\\M) "	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		AddModelToStrings("PolyThreeShell","coef_PolyThreeShell","parameters_PolyThreeShell","PolyThreeShell")//EndProc PlotPolyFourShell(num,qmin,qmax)	Variable num=200, qmin=0.001, qmax=0.7	Prompt num "Enter number of data points for model: "	Prompt qmin "Enter minimum q-value (�^-1) for model: " 	Prompt qmax "Enter maximum q-value (�^-1) for model: "//	Make/O/D/n=(num) xwave_PolyFourShell, ywave_PolyFourShell	xwave_PolyFourShell =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	Make/O/D coef_PolyFourShell ={1.,60,0.1,6.4e-6,10,1e-6,10,2e-6,5,3e-6,10,4e-6,6.4e-6,0.001}	make/o/t parameters_PolyFourShell = {"scale","core radius (A)","Core Polydispersity(0,1)","Core SLD (A-2)","Shell 1 thickness","Shell 1 SLD (A-2)","Shell 2 thickness","Shell 2 SLD (A-2)","Shell 3 thickness","Shell 3 SLD (A-2)","Shell 4 thickness","Shell 4 SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}	Edit parameters_PolyFourShell, coef_PolyFourShell		Variable/G root:g_PolyFourShell	g_PolyFourShell := PolyFourShell(coef_PolyFourShell, ywave_PolyFourShell, xwave_PolyFourShell)	Display ywave_PolyFourShell vs xwave_PolyFourShell	ModifyGraph marker=29, msize=2, mode=4	ModifyGraph log=1,grid=1,mirror=2	Label bottom "q (�\\S-1\\M) "	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		AddModelToStrings("PolyFourShell","coef_PolyFourShell","parameters_PolyFourShell","PolyFourShell")//End////this macro sets up all the necessary parameters and waves that are//needed to calculate the  smeared model function.////no input parameters are necessary, it MUST use the experimental q-values// from the experimental data read in from an AVE/QSIG data file////////////////////////////////////////////////////// - sets up a dependency to a wrapper, not the actual SmearedModelFunctionProc PlotSmearedPolyOneShell(str)									String str	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)		// if any of the resolution waves are missing => abort	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)		Abort	endif		SetDataFolder $("root:"+str)		// Setup parameter table for model function	Make/O/D smear_coef_PolyOneShell =  {1.,60,0.1,6.4e-6,10,1e-6,6.4e-6,0.001}	make/o/t smear_parameters_PolyOneShell =  {"scale","core radius (A)","Core Polydispersity(0,1)","Core SLD (A-2)","Shell thickness (A)","Shell SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}	Edit smear_parameters_PolyOneShell,smear_coef_PolyOneShell					//display parameters in a table		// output smeared intensity wave, dimensions are identical to experimental QSIG values	// make extra copy of experimental q-values for easy plotting	Duplicate/O $(str+"_q") smeared_PolyOneShell,smeared_qvals	SetScale d,0,0,"1/cm",smeared_PolyOneShell						Variable/G gs_PolyOneShell=0	gs_PolyOneShell := fSmearedPolyOneShell(smear_coef_PolyOneShell,smeared_PolyOneShell,smeared_qvals)	//this wrapper fills the STRUCT		Display smeared_PolyOneShell vs smeared_qvals	ModifyGraph log=1,marker=29,msize=2,mode=4	Label bottom "q (�\\S-1\\M)"	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		SetDataFolder root:	AddModelToStrings("SmearedPolyOneShell","smear_coef_PolyOneShell","smear_parameters_PolyOneShell","PolyOneShell")EndProc PlotSmearedPolyTwoShell(str)									String str	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)		// if any of the resolution waves are missing => abort	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)		Abort	endif		SetDataFolder $("root:"+str)		// Setup parameter table for model function	Make/O/D smear_coef_PolyTwoShell =  {1.,60,0.1,6.4e-6,10,1e-6,10,2e-6,6.4e-6,0.001}	make/o/t smear_parameters_PolyTwoShell =  {"scale","core radius (A)","Core Polydispersity(0,1)","Core SLD (A-2)","Shell 1 thickness","Shell 1 SLD (A-2)","Shell 2 thickness","Shell 2 SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}	Edit smear_parameters_PolyTwoShell,smear_coef_PolyTwoShell					//display parameters in a table		// output smeared intensity wave, dimensions are identical to experimental QSIG values	// make extra copy of experimental q-values for easy plotting	Duplicate/O $(str+"_q") smeared_PolyTwoShell,smeared_qvals	SetScale d,0,0,"1/cm",smeared_PolyTwoShell						Variable/G gs_PolyTwoShell=0	gs_PolyTwoShell := fSmearedPolyTwoShell(smear_coef_PolyTwoShell,smeared_PolyTwoShell,smeared_qvals)	//this wrapper fills the STRUCT		Display smeared_PolyTwoShell vs smeared_qvals	ModifyGraph log=1,marker=29,msize=2,mode=4	Label bottom "q (�\\S-1\\M)"	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		SetDataFolder root:	AddModelToStrings("SmearedPolyTwoShell","smear_coef_PolyTwoShell","smear_parameters_PolyTwoShell","PolyTwoShell")EndProc PlotSmearedPolyThreeShell(str)									String str	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)		// if any of the resolution waves are missing => abort	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)		Abort	endif		SetDataFolder $("root:"+str)		// Setup parameter table for model function	Make/O/D smear_coef_PolyThreeShell =  {1.,60,0.1,6.4e-6,10,1e-6,10,2e-6,5,3e-6,6.4e-6,0.001}	make/o/t smear_parameters_PolyThreeShell =  {"scale","core radius (A)","Core Polydispersity(0,1)","Core SLD (A-2)","Shell 1 thickness","Shell 1 SLD (A-2)","Shell 2 thickness","Shell 2 SLD (A-2)","Shell 3 thickness","Shell 3 SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}	Edit smear_parameters_PolyThreeShell,smear_coef_PolyThreeShell					//display parameters in a table		// output smeared intensity wave, dimensions are identical to experimental QSIG values	// make extra copy of experimental q-values for easy plotting	Duplicate/O $(str+"_q") smeared_PolyThreeShell,smeared_qvals	SetScale d,0,0,"1/cm",smeared_PolyThreeShell						Variable/G gs_PolyThreeShell=0	gs_PolyThreeShell := fSmearedPolyThreeShell(smear_coef_PolyThreeShell,smeared_PolyThreeShell,smeared_qvals)	//this wrapper fills the STRUCT		Display smeared_PolyThreeShell vs smeared_qvals	ModifyGraph log=1,marker=29,msize=2,mode=4	Label bottom "q (�\\S-1\\M)"	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		SetDataFolder root:	AddModelToStrings("SmearedPolyThreeShell","smear_coef_PolyThreeShell","smear_parameters_PolyThreeShell","PolyThreeShell")EndProc PlotSmearedPolyFourShell(str)									String str	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)		// if any of the resolution waves are missing => abort	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)		Abort	endif		SetDataFolder $("root:"+str)		// Setup parameter table for model function	Make/O/D smear_coef_PolyFourShell = {1.,60,0.1,6.4e-6,10,1e-6,10,2e-6,5,3e-6,10,4e-6,6.4e-6,0.001}	make/o/t smear_parameters_PolyFourShell =  {"scale","core radius (A)","Core Polydispersity(0,1)","Core SLD (A-2)","Shell 1 thickness","Shell 1 SLD (A-2)","Shell 2 thickness","Shell 2 SLD (A-2)","Shell 3 thickness","Shell 3 SLD (A-2)","Shell 4 thickness","Shell 4 SLD (A-2)","Solvent SLD (A-2)","bkg (cm-1)"}	Edit smear_parameters_PolyFourShell,smear_coef_PolyFourShell					//display parameters in a table		// output smeared intensity wave, dimensions are identical to experimental QSIG values	// make extra copy of experimental q-values for easy plotting	Duplicate/O $(str+"_q") smeared_PolyFourShell,smeared_qvals	SetScale d,0,0,"1/cm",smeared_PolyFourShell						Variable/G gs_PolyFourShell=0	gs_PolyFourShell := fSmearedPolyFourShell(smear_coef_PolyFourShell,smeared_PolyFourShell,smeared_qvals)	//this wrapper fills the STRUCT		Display smeared_PolyFourShell vs smeared_qvals	ModifyGraph log=1,marker=29,msize=2,mode=4	Label bottom "q (�\\S-1\\M)"	Label left "I(q) (cm\\S-1\\M)"	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)		SetDataFolder root:	AddModelToStrings("SmearedPolyFourShell","smear_coef_PolyFourShell","smear_parameters_PolyFourShell","PolyFourShell")End// nothing to change here////AAO version, uses XOP if available// simply calls the original single point calculation with// a wave assignment (this will behave nicely if given point ranges)Function PolyOneShell(cw,yw,xw) : FitFunc	Wave cw,yw,xw	#if exists("PolyOneShellX")	yw = PolyOneShellX(cw,xw)#else	yw = fPolyOneShell(cw,xw)#endif	return(0)EndFunction PolyTwoShell(cw,yw,xw) : FitFunc	Wave cw,yw,xw	#if exists("PolyTwoShellX")	yw = PolyTwoShellX(cw,xw)#else	yw = fPolyTwoShell(cw,xw)#endif	return(0)EndFunction PolyThreeShell(cw,yw,xw) : FitFunc	Wave cw,yw,xw	#if exists("PolyThreeShellX")	yw =PolyThreeShellX(cw,xw)#else	yw = fPolyThreeShell(cw,xw)#endif	return(0)EndFunction PolyFourShell(cw,yw,xw) : FitFunc	Wave cw,yw,xw	#if exists("PolyFourShellX")	yw = PolyFourShellX(cw,xw)#else	yw = fPolyFourShell(cw,xw)#endif	return(0)End//// unsmeared model calculation//Function fPolyOneShell(w,x) : FitFunc	Wave w	Variable x	Variable scale,rcore,thick,rhocore,rhoshel,rhosolv,bkg,pd,zz	scale = w[0]	rcore = w[1]	pd = w[2]	rhocore = w[3]	thick = w[4]	rhoshel = w[5]	rhosolv = w[6]	bkg = w[7]		zz = (1/pd)^2-1		//polydispersity of the core only//// local variables	Variable nord,ii,va,vb,contr,vcyl,nden,summ,yyy,zi,qq	Variable answer,zp1,zp2,zp3,vpoly	String weightStr,zStr	//select number of gauss points by setting nord=20 or76 points	NVAR/Z gNord=gNord	if(! NVAR_Exists(gNord) )		nord=76		//use 76 pts as default	else		if( (gNord == 20) || (gNord ==76) )			nord = gNord 	// should only allow 20 or 76 points		else			abort "global value gNord in SchulzSpheres must be either 20 or 76"		endif	endif		weightStr = "gauss"+num2str(nord)+"wt"	zStr = "gauss"+num2str(nord)+"z"		if (WaveExists($weightStr) == 0) // wave reference is not valid, 		Make/D/N=(nord) $weightStr,$zStr		Wave gauWt = $weightStr		Wave gauZ = $zStr		// wave references to pass		if(nord==20)			Make20GaussPoints(gauWt,gauZ)		else			Make76GaussPoints(gauWt,gauZ)		endif		else		if(exists(weightStr) > 1) 			 Abort "wave name is already in use"		//executed only if name is in use elsewhere		endif		Wave gauWt = $weightStr		Wave gauZ = $zStr		// create the wave references	endif	// set up the integration end points and weights// limits are technically 0-inf, but wisely choose non-zero region of distribution	Variable range=8	//multiples of the std. dev. from the mean	va = rcore*(1-range*pd)	if (va<0)		va=0		//otherwise numerical error when pd >= 0.3, making a<0	endif	If(pd>0.3)		range = range + (pd-0.3)*18		//stretch upper range to account for skewed tail	Endif	vb = rcore*(1+range*pd) // is this far enough past avg radius?//temp set scale=1 and bkg=0 for quadrature calc	Make/O/D/N=7 temp_1sf	temp_1sf[0] = 1	temp_1sf[1] = w[1]		//the core radius will be changed in the loop	temp_1sf[2] = w[3]	temp_1sf[3] = w[4]	temp_1sf[4] = w[5]	temp_1sf[5] = w[6]	temp_1sf[6] = 0	// evaluate at Gauss points 	summ = 0.0		// initialize integral	for(ii=0;ii<nord;ii+=1)		zi = ( gauZ[ii]*(vb-va) + vb + va )/2.0		temp_1sf[1] = zi				yyy = gauWt[ii] * Schulz_Point_Nsf(zi,rcore,zz) *fOneShell(temp_1sf,x)		//un-normalize by volume		yyy *= 4*pi/3*(zi+thick)^3		summ += yyy	endfor// calculate value of integral to return   answer = (vb-va)/2.0*summ   	   //re-normalize by the average volume   zp1 = zz + 1.   zp2 = zz + 2.   zp3 = zz + 3.   vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(rcore+thick)^3  	answer /= vpoly//scale	answer *= scale// add in the background	answer += bkg	Return (answer)EndFunction fPolyTwoShell(w,x) : FitFunc	Wave w	Variable x	Variable scale,rcore,rhocore,rhosolv,bkg,pd,zz	Variable thick1,thick2	Variable rhoshel1,rhoshel2	scale = w[0]	rcore = w[1]	pd = w[2]	rhocore = w[3]	thick1 = w[4]	rhoshel1 = w[5]	thick2 = w[6]	rhoshel2 = w[7]	rhosolv = w[8]	bkg = w[9]		zz = (1/pd)^2-1		//polydispersity of the core only//// local variables	Variable nord,ii,va,vb,contr,vcyl,nden,summ,yyy,zi,qq	Variable answer,zp1,zp2,zp3,vpoly	String weightStr,zStr	//select number of gauss points by setting nord=20 or76 points	NVAR/Z gNord=gNord	if(! NVAR_Exists(gNord) )		nord=76		//use 76 pts as default	else		if( (gNord == 20) || (gNord ==76) )			nord = gNord 	// should only allow 20 or 76 points		else			abort "global value gNord in SchulzSpheres must be either 20 or 76"		endif	endif		weightStr = "gauss"+num2str(nord)+"wt"	zStr = "gauss"+num2str(nord)+"z"		if (WaveExists($weightStr) == 0) // wave reference is not valid, 		Make/D/N=(nord) $weightStr,$zStr		Wave gauWt = $weightStr		Wave gauZ = $zStr		// wave references to pass		if(nord==20)			Make20GaussPoints(gauWt,gauZ)		else			Make76GaussPoints(gauWt,gauZ)		endif		else		if(exists(weightStr) > 1) 			 Abort "wave name is already in use"		//executed only if name is in use elsewhere		endif		Wave gauWt = $weightStr		Wave gauZ = $zStr		// create the wave references	endif	// set up the integration end points and weights// limits are technically 0-inf, but wisely choose non-zero region of distribution	Variable range=8	//multiples of the std. dev. from the mean	va = rcore*(1-range*pd)	if (va<0)		va=0		//otherwise numerical error when pd >= 0.3, making a<0	endif	If(pd>0.3)		range = range + (pd-0.3)*18		//stretch upper range to account for skewed tail	Endif	vb = rcore*(1+range*pd) // is this far enough past avg radius?//temp set scale=1 and bkg=0 for quadrature calc	Make/O/D/N=9 temp_2sf	temp_2sf[0] = 1	temp_2sf[1] = w[1]		//the core radius will be changed in the loop	temp_2sf[2] = w[3]	temp_2sf[3] = w[4]	temp_2sf[4] = w[5]	temp_2sf[5] = w[6]	temp_2sf[6] = w[7]	temp_2sf[7] = w[8]	temp_2sf[8] = 0	// evaluate at Gauss points 	summ = 0.0		// initialize integral	for(ii=0;ii<nord;ii+=1)		zi = ( gauZ[ii]*(vb-va) + vb + va )/2.0		temp_2sf[1] = zi				yyy = gauWt[ii] * Schulz_Point_Nsf(zi,rcore,zz) * fTwoShell(temp_2sf,x)		//un-normalize by volume		yyy *= 4*pi/3*(zi+thick1+thick2)^3		summ += yyy	endfor// calculate value of integral to return   answer = (vb-va)/2.0*summ   	   //re-normalize by the average volume   zp1 = zz + 1.   zp2 = zz + 2.   zp3 = zz + 3.   vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(rcore+thick1+thick2)^3  	answer /= vpoly//scale	answer *= scale// add in the background	answer += bkg	Return (answer)EndFunction fPolyThreeShell(w,x) : FitFunc	Wave w	Variable x	Variable scale,rcore,rhocore,rhosolv,bkg,pd,zz	Variable thick1,thick2,thick3	Variable rhoshel1,rhoshel2,rhoshel3	scale = w[0]	rcore = w[1]	pd = w[2]	rhocore = w[3]	thick1 = w[4]	rhoshel1 = w[5]	thick2 = w[6]	rhoshel2 = w[7]	thick3 = w[8]	rhoshel3 = w[9]	rhosolv = w[10]	bkg = w[11]		zz = (1/pd)^2-1		//polydispersity of the core only//// local variables	Variable nord,ii,va,vb,contr,vcyl,nden,summ,yyy,zi,qq	Variable answer,zp1,zp2,zp3,vpoly	String weightStr,zStr	//select number of gauss points by setting nord=20 or76 points	NVAR/Z gNord=gNord	if(! NVAR_Exists(gNord) )		nord=76		//use 76 pts as default	else		if( (gNord == 20) || (gNord ==76) )			nord = gNord 	// should only allow 20 or 76 points		else			abort "global value gNord in SchulzSpheres must be either 20 or 76"		endif	endif		weightStr = "gauss"+num2str(nord)+"wt"	zStr = "gauss"+num2str(nord)+"z"		if (WaveExists($weightStr) == 0) // wave reference is not valid, 		Make/D/N=(nord) $weightStr,$zStr		Wave gauWt = $weightStr		Wave gauZ = $zStr		// wave references to pass		if(nord==20)			Make20GaussPoints(gauWt,gauZ)		else			Make76GaussPoints(gauWt,gauZ)		endif		else		if(exists(weightStr) > 1) 			 Abort "wave name is already in use"		//executed only if name is in use elsewhere		endif		Wave gauWt = $weightStr		Wave gauZ = $zStr		// create the wave references	endif	// set up the integration end points and weights// limits are technically 0-inf, but wisely choose non-zero region of distribution	Variable range=8	//multiples of the std. dev. from the mean	va = rcore*(1-range*pd)	if (va<0)		va=0		//otherwise numerical error when pd >= 0.3, making a<0	endif	If(pd>0.3)		range = range + (pd-0.3)*18		//stretch upper range to account for skewed tail	Endif	vb = rcore*(1+range*pd) // is this far enough past avg radius?//temp set scale=1 and bkg=0 for quadrature calc	Make/O/D/N=11 temp_3sf	temp_3sf[0] = 1	temp_3sf[1] = w[1]		//the core radius will be changed in the loop	temp_3sf[2] = w[3]	temp_3sf[3] = w[4]	temp_3sf[4] = w[5]	temp_3sf[5] = w[6]	temp_3sf[6] = w[7]	temp_3sf[7] = w[8]	temp_3sf[8] = w[9]	temp_3sf[9] = w[10]	temp_3sf[10] = 0	// evaluate at Gauss points 	summ = 0.0		// initialize integral	for(ii=0;ii<nord;ii+=1)		zi = ( gauZ[ii]*(vb-va) + vb + va )/2.0		temp_3sf[1] = zi				yyy = gauWt[ii] * Schulz_Point_Nsf(zi,rcore,zz) * fThreeShell(temp_3sf,x)		//un-normalize by volume		yyy *= 4*pi/3*(zi+thick1+thick2+thick3)^3		summ += yyy	endfor// calculate value of integral to return   answer = (vb-va)/2.0*summ   	   //re-normalize by the average volume   zp1 = zz + 1.   zp2 = zz + 2.   zp3 = zz + 3.   vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(rcore+thick1+thick2+thick3)^3  	answer /= vpoly//scale	answer *= scale// add in the background	answer += bkg	Return (answer)EndFunction fPolyFourShell(w,x) : FitFunc	Wave w	Variable x	Variable scale,rcore,rhocore,rhosolv,bkg,pd,zz	Variable thick1,thick2,thick3,thick4	Variable rhoshel1,rhoshel2,rhoshel3,rhoshel4	scale = w[0]	rcore = w[1]	pd = w[2]	rhocore = w[3]	thick1 = w[4]	rhoshel1 = w[5]	thick2 = w[6]	rhoshel2 = w[7]	thick3 = w[8]	rhoshel3 = w[9]	thick4 = w[10]	rhoshel4 = w[11]	rhosolv = w[12]	bkg = w[13]		zz = (1/pd)^2-1		//polydispersity of the core only//// local variables	Variable nord,ii,va,vb,contr,vcyl,nden,summ,yyy,zi,qq	Variable answer,zp1,zp2,zp3,vpoly	String weightStr,zStr	//select number of gauss points by setting nord=20 or76 points	NVAR/Z gNord=gNord	if(! NVAR_Exists(gNord) )		nord=76		//use 76 pts as default	else		if( (gNord == 20) || (gNord ==76) )			nord = gNord 	// should only allow 20 or 76 points		else			abort "global value gNord in SchulzSpheres must be either 20 or 76"		endif	endif		weightStr = "gauss"+num2str(nord)+"wt"	zStr = "gauss"+num2str(nord)+"z"		if (WaveExists($weightStr) == 0) // wave reference is not valid, 		Make/D/N=(nord) $weightStr,$zStr		Wave gauWt = $weightStr		Wave gauZ = $zStr		// wave references to pass		if(nord==20)			Make20GaussPoints(gauWt,gauZ)		else			Make76GaussPoints(gauWt,gauZ)		endif		else		if(exists(weightStr) > 1) 			 Abort "wave name is already in use"		//executed only if name is in use elsewhere		endif		Wave gauWt = $weightStr		Wave gauZ = $zStr		// create the wave references	endif	// set up the integration end points and weights// limits are technically 0-inf, but wisely choose non-zero region of distribution	Variable range=8	//multiples of the std. dev. from the mean	va = rcore*(1-range*pd)	if (va<0)		va=0		//otherwise numerical error when pd >= 0.3, making a<0	endif	If(pd>0.3)		range = range + (pd-0.3)*18		//stretch upper range to account for skewed tail	Endif	vb = rcore*(1+range*pd) // is this far enough past avg radius?//temp set scale=1 and bkg=0 for quadrature calc	Make/O/D/N=13 temp_4sf	temp_4sf[0] = 1	temp_4sf[1] = w[1]		//the core radius will be changed in the loop	temp_4sf[2] = w[3]	temp_4sf[3] = w[4]	temp_4sf[4] = w[5]	temp_4sf[5] = w[6]	temp_4sf[6] = w[7]	temp_4sf[7] = w[8]	temp_4sf[8] = w[9]	temp_4sf[9] = w[10]	temp_4sf[10] = w[11]	temp_4sf[11] = w[12]	temp_4sf[12] = 0	// evaluate at Gauss points 	summ = 0.0		// initialize integral	for(ii=0;ii<nord;ii+=1)		zi = ( gauZ[ii]*(vb-va) + vb + va )/2.0		temp_4sf[1] = zi				yyy = gauWt[ii] * Schulz_Point_Nsf(zi,rcore,zz) * fFourShell(temp_4sf,x)		//un-normalize by volume		yyy *= 4*pi/3*(zi+thick1+thick2+thick3+thick4)^3		summ += yyy	endfor// calculate value of integral to return   answer = (vb-va)/2.0*summ   	   //re-normalize by the average volume   zp1 = zz + 1.   zp2 = zz + 2.   zp3 = zz + 3.   vpoly = 4*Pi/3*zp3*zp2/zp1/zp1*(rcore+thick1+thick2+thick3+thick4)^3  	answer /= vpoly//scale	answer *= scale// add in the background	answer += bkg	Return (answer)End///////////////////////////////////////////////////////////////// smeared model calculation//// you don't need to do anything with this function, as long as// your PolyOneShell works correctly, you get the resolution-smeared// version for free.//// this is all there is to the smeared model calculation!Function SmearedPolyOneShell(s) : FitFunc	Struct ResSmearAAOStruct &s//	the name of your unsmeared model (AAO) is the first argument	Smear_Model_20(PolyOneShell,s.coefW,s.xW,s.yW,s.resW)	return(0)EndFunction SmearedPolyTwoShell(s) : FitFunc	Struct ResSmearAAOStruct &s//	the name of your unsmeared model (AAO) is the first argument	Smear_Model_20(PolyTwoShell,s.coefW,s.xW,s.yW,s.resW)	return(0)EndFunction SmearedPolyThreeShell(s) : FitFunc	Struct ResSmearAAOStruct &s//	the name of your unsmeared model (AAO) is the first argument	Smear_Model_20(PolyThreeShell,s.coefW,s.xW,s.yW,s.resW)	return(0)EndFunction SmearedPolyFourShell(s) : FitFunc	Struct ResSmearAAOStruct &s//	the name of your unsmeared model (AAO) is the first argument	Smear_Model_20(PolyFourShell,s.coefW,s.xW,s.yW,s.resW)	return(0)End///////////////////////////////////////////////////////////////// nothing to change here////wrapper to calculate the smeared model as an AAO-Struct// fills the struct and calls the ususal function with the STRUCT parameter//// used only for the dependency, not for fitting//Function fSmearedPolyOneShell(coefW,yW,xW)	Wave coefW,yW,xW		String str = getWavesDataFolder(yW,0)	String DF="root:"+str+":"		WAVE resW = $(DF+str+"_res")		STRUCT ResSmearAAOStruct fs	WAVE fs.coefW = coefW		WAVE fs.yW = yW	WAVE fs.xW = xW	WAVE fs.resW = resW		Variable err	err = SmearedPolyOneShell(fs)		return (0)EndFunction fSmearedPolyTwoShell(coefW,yW,xW)	Wave coefW,yW,xW		String str = getWavesDataFolder(yW,0)	String DF="root:"+str+":"		WAVE resW = $(DF+str+"_res")		STRUCT ResSmearAAOStruct fs	WAVE fs.coefW = coefW		WAVE fs.yW = yW	WAVE fs.xW = xW	WAVE fs.resW = resW		Variable err	err = SmearedPolyTwoShell(fs)		return (0)EndFunction fSmearedPolyThreeShell(coefW,yW,xW)	Wave coefW,yW,xW		String str = getWavesDataFolder(yW,0)	String DF="root:"+str+":"		WAVE resW = $(DF+str+"_res")		STRUCT ResSmearAAOStruct fs	WAVE fs.coefW = coefW		WAVE fs.yW = yW	WAVE fs.xW = xW	WAVE fs.resW = resW		Variable err	err = SmearedPolyThreeShell(fs)		return (0)EndFunction fSmearedPolyFourShell(coefW,yW,xW)	Wave coefW,yW,xW		String str = getWavesDataFolder(yW,0)	String DF="root:"+str+":"		WAVE resW = $(DF+str+"_res")		STRUCT ResSmearAAOStruct fs	WAVE fs.coefW = coefW		WAVE fs.yW = yW	WAVE fs.xW = xW	WAVE fs.resW = resW		Variable err	err = SmearedPolyFourShell(fs)		return (0)End//calculate the normalized distributionStatic Function Schulz_Point_Nsf(x,avg,zz)	Variable x,avg,zz		Variable dr		dr = zz*ln(x) - gammln(zz+1)+(zz+1)*ln((zz+1)/avg)-(x/avg*(zz+1))	return (exp(dr))End