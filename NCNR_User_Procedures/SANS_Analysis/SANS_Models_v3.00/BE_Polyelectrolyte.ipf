#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////
// Template: 
// 06 NOV 98 SRK
////////////////////////////////////////////////
// Giovanni Nisato 30 Nov 1998
// Borue-Erukhimovich RPA for linear polyelectrolytes
// references:	Borue, V. Y.; Erukhimovich, I. Y. Macromolecules 1988, 21, 3240.
//			Joanny, J.-F.; Leibler, L. Journal de Physique 1990, 51, 545.
//			Moussaid, A.; Schosseler, F.; Munch, J.-P.; Candau, S. J. Journal de Physique II France 1993, 3, 573.
////////////////////////////////////////////////

Proc PlotBE_Polyelectrolyte(num,qmin,qmax)
	Variable num=512,qmin=0.001,qmax=0.2
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (^-1) for model: "
	Prompt qmax "Enter maximum q-value (^-1) for model: "	

	make/o/n=(num) xwave_BE,ywave_BE
	xwave_BE =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))	
	make/o coef_BE = {10,7.1,12,10,0.00,0.05,0.7,0.001}
	make/o/t parameters_BE = {"K (barns)","Lb ()","h (-3)","b ()","Cs (mol/L)","alpha","C (mol/L)","Background"}	
	Edit parameters_BE,coef_BE
	ywave_BE := BEPolyelectrolyte(coef_BE,xwave_BE)
	Display ywave_BE vs xwave_BE
	ModifyGraph log=0,marker=29,msize=2,mode=4			//**** log=0 if linear scale desired
	Label bottom "q (\\S-1\\M)"
	Label left "S(q) BE , cm\\S-1\\M"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////

Proc PlotSmearedBE_Polyelectrolyte()								//**** name of your function
	//no input parameters necessary, it MUST use the experimental q-values
	// from the experimental data read in from an AVE/QSIG data file
	// if no gQvals wave, data must not have been loaded => abort
	if(ResolutionWavesMissing())
		Abort
	endif
	
	// Setup parameter table for model function
	make/o smear_coef_BE = {10,7.1,12,10,0.00,0.05,0.7,0.001}					//**** mod, coef values to match unsmeared model above
	make/o/t smear_parameters_BE= {"K (barns)","Lb ()","h (-3)","b ()","Cs (mol/L)","alpha","C (mol/L)","Background"}	
	Edit smear_parameters_BE,smear_coef_BE					//**** mod
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $gQvals smeared_BE,smeared_qvals				//**** mod
	SetScale d,0,0,"1/cm",smeared_BE						//**** mod

	smeared_BE := SmearedBEPolyelec(smear_coef_BE,$gQvals)		//**** mod, your SMEARED function name
	Display smeared_BE vs smeared_qvals									//**** mod
	ModifyGraph log=0,marker=29,msize=2,mode=4
	Label bottom "q (\\S-1\\M)"
	Label left "I  sBE (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
End

///////////////////////////////////////////////////////////////
// unsmeared model calculation
///////////////////////////
// Borue-Erukhimovich RPA model for linear polyelectrolytes
///////////////////////////


Function BEPolyelectrolyte(w,q) : FitFunc
	Wave w
	Variable q
// Input (fitting) variables are:
	//[0] K  = contrast factor  (barns = 10-24 cm^2=10-4 ^2)
	//[1] Lb = Bjerrum length ; this parameter needs to be kept constant for a given solvent and temperature!  ()
	//[2]  h = virial parameter (3)
	//[3]  b = monomer length  ()
	//[4]  Cs = concentration of monovalent salt (mol/L)
	//[5]  alpha = ionization degree : ratio of charged monomers  to total number of monomers
	//[6]  C  = polymer molar concentration (mol/L)
	//[7]  Bkd = Background	
//  local variables
	Variable K,Lb,h,b,alpha,C,Ca,Cs,Csa,r02,K2,q2,Sq,Bkd
	K = w[0]  
	Lb = w[1]
	h = w[2]  
	b = w[3]
	Cs = w[4]
	alpha = w[5]
	C  = w[6]
	Bkd =w[7]
       
       	Ca = C *6.022136e-4 			//   polymer number concentration in angstroms-3
       	Csa = Cs * 6.022136e-4 		//  1:1 salt concentration, angstroms-3
	k2= 4*Pi*Lb*(2*Cs+alpha*Ca)     //    inverse Debye length, squared; classical definition

// alternative definitionfor ANNEALED (weak) polyelectrolytes (e.g. : polyacrylic acid): 
// k2= 4*Pi*Lb*(2*Cs+2*alpha*Ca)   	
// reference:  Raphal, E.; Joanny, J.-F. Europhysics Letters 1990, 11, 179.													
								
	r02 = 1./alpha / Ca^0.5*( b / (48*Pi*Lb) ^0.5 )
	q2 = q^2	
	

//   K = a^2  with:  a = (bp - vp/vsolvent * bsolvent)
// where : b = Sum(batom) ; batom = scattering length in cm-12 
//		vp = partial molar volume of the polymer ; vsolvent= partial molar volume of the solvent
// NB :K in  Barns = 10^-24 cm2 ; the rest of the expression is in -3 = 10^24 cm3
//  -> there is no multiplication factor to get the result in cm-1 . 
// Returns S(q) in cm-1

	Sq = K*1./(4*Pi*Lb*alpha^2)  * (q2 + k2)  /  (1+(r02^2) * (q2+k2) * (q2- (12*h*Ca/b^2)) ) + Bkd
 	
 	Return (Sq)
End
//End of function BE()
///////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////
// smeared model calculation
///////////////////////////

	// this is all there is to the smeared calculation!
Function SmearedBEPolyelec(w,x) :FitFunc
	Wave w
	Variable x
	
	Variable ans
	SVAR sq = gSig_Q
	SVAR qb = gQ_bar
	SVAR sh = gShadow
	SVAR gQ = gQVals
	
	//the name of your unsmeared model is the first argument
	ans = Smear_Model_20(BEPolyelectrolyte,$sq,$qb,$sh,$gQ,w,x)

	return(ans)
End



