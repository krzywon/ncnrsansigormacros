#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// turn the White Beam resolution smearing into a fitting function
// so that the wavelength smeared function can then be smeared by
// a gaussian resolution function that has geometry only.
//
// The geometry only resolution is generated by passing dl/l=0 to the resolution
// calculation.
//
// This representation uses the "middle" of the distribution

//
//

//#include "sphere_v40"
// plots the form factor of  spheres with a Gaussian radius distribution
//
// also can plot the distribution itself, based on the current model parameters
//
// integration is currently done using 20-pt quadrature, but may benefit from 
//switching to an adaptive integration.
//

Proc PlotGaussSpheresSWB(num,qmin,qmax)
	Variable num=128,qmin=0.001,qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (A^-1) for model: "
	Prompt qmax "Enter maximum q-value (A^-1) for model: "
	
	Make/O/D/N=(num) xwave_pgsSWB,ywave_pgsSWB
	xwave_pgsSWB = alog( log(qmin) + x*((log(qmax)-log(qmin))/num) )
	Make/O/D coef_pgsSWB = {0.01,60,0.2,1e-6,3e-6,0.001}
	make/O/T parameters_pgsSWB = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}
	Edit parameters_pgsSWB,coef_pgsSWB
	
	Variable/G root:g_pgsSWB
	g_pgsSWB := GaussSpheresSWB(coef_pgsSWB,ywave_pgsSWB,xwave_pgsSWB)
	Display ywave_pgsSWB vs xwave_pgsSWB
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("GaussSpheresSWB","coef_pgsSWB","parameters_pgsSWB","pgsSWB")
End

// - sets up a dependency to a wrapper, not the actual SmearedModelFunction
Proc PlotSmearedGaussSpheresSWB(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_pgsSWB = {0.01,60,0.2,1e-6,3e-6,0.001}					
	make/o/t smear_parameters_pgsSWB = {"Volume Fraction (scale)","mean radius (A)","polydisp (sig/avg)","SLD sphere (A-2)","SLD solvent (A-2)","bkg (cm-1 sr-1)"}	
	Edit smear_parameters_pgsSWB,smear_coef_pgsSWB					
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_pgsSWB,smeared_qvals				
	SetScale d,0,0,"1/cm",smeared_pgsSWB							
					
	Variable/G gs_pgsSWB=0
	gs_pgsSWB := fSmearedGaussSpheresSWB(smear_coef_pgsSWB,smeared_pgsSWB,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_pgsSWB vs smeared_qvals									
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (A\\S-1\\M)"
	Label left "Intensity (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedGaussSpheresSWB","smear_coef_pgsSWB","smear_parameters_pgsSWB","pgsSWB")
End
	



//AAO version, uses XOP if available
// simply calls the original single point calculation with
// a wave assignment (this will behave nicely if given point ranges)
Function GaussSpheresSWB(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("GaussSpheresX")
//	MultiThread yw = GaussSpheresX(cw,xw)
	yw = V_fGaussSpheresSWB(cw,xw)

#else
//	yw = fGaussSpheresSWB(cw,xw)
	yw = 1
#endif
	return(0)
End

Function V_fGaussSpheresSWB(w,xx) : FitFunc
	wave w
	variable xx
	
	Variable scale,rad,pd,sig,rho,rhos,bkg,delrho,inten,loLim,upLim
	
	//the coefficient values
//	scale=w[0]
//	rad=w[1]
//	pd=w[2]
//	sig=pd*rad
//	rho=w[3]
//	rhos=w[4]
//	delrho=rho-rhos
//	bkg=w[5]
	
	
	// define limits based on lo/mean, hi/mean of the wavelength distribution
	// using the empirical definition, "middle" of the peaks
	loLim = 3.37/5.3
	upLim = 20/5.3
	
	inten = V_IntegrGaussSphereSWB_mid(w,loLim,upLim,xx)

// why do I need this? Is this because this is defined as the mean of the distribution
//  and is needed to normalize the integral? verify this on paper.	
	inten *= 5.3

// normalize the integral	
	inten /= 30955		// "middle"  of peaks

	inten -= w[5]
// additional normalization???
	inten /= 1.05		// 
	
//	inten /= 2			// need this factor to match low q of white beam??? -- and to get invariant to work...
	
	inten += w[5]
	Return(inten)
End


// the trick here is that declaring the last qVal wave as a variable
// since this is implicitly called N times in the wave assignment of the answer wave
Function V_IntegrGaussSphereSWB_mid(cw,loLim,upLim,qVal)
	Wave cw
	Variable loLim,upLim
	Variable qVal
	
	Variable/G root:qq = qval
	Variable ans
	
//	ans = Integrate1D(V_intgrnd_top,lolim,uplim,2,0,cw)		//adaptive quadrature
	ans = Integrate1D(V_integrand_pgsSWB,lolim,uplim,1,0,cw)		// Romberg integration
	
	return ans
end

Function V_integrand_pgsSWB(cw,dum)
	Wave cw
	Variable dum		// the dummy of the integration

	Variable val
	NVAR qq = root:qq		//the q-value of the integration, not part of cw, so pass global
//	SVAR funcStr = root:gFunctionString
//	FUNCREF SANSModel_proto func = $funcStr

	val = V_SuperWhiteBeamDist_mid(dum*5.3)*GaussSpheresX(cw,qq/dum)
	
	return (val)
End

//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedGaussSpheresSWB(coefW,yW,xW)
	Wave coefW,yW,xW
	
	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW	
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = SmearedGaussSpheresSWB(fs)
	
	return (0)
End

// this is all there is to the smeared calculation!
Function SmearedGaussSpheresSWB(s) :FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(GaussSpheresSWB,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End


