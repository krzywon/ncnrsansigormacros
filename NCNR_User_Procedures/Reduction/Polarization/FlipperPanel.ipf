#pragma rtGlobals=1		// Use modern global access method.

// input panels to set and calculate polarization parameters necessary for the 
// matrix corrections to the cross sections
//
//
// -3-Flipper efficiency


//
// TODO: 
//		- add a button to "add" a new named condition (and be sure that the name is short enough)
//		- 			
//			- parsing routines
//			- write the results to a waveNote
//			--- where to store the intermediate results of trans values?
//				make a wave behind the scenes to
//
//
// Polarization parameters for each condition. Results are stored in a wave note for each condition
//
//
// str = "P_sm_f=2,err_P_sm_f=0,P_sm=0.6,err_P_sm=0,T0=asdf,Cell=asdf,"
//
// two waves per condition "Cond_Name_Cell" and "CondCalc_Name_Cell"
//
Macro ShowFlipperPanel()
	
	// init folders
	// ASK before initializing cell constants
	// open the panel
	DoWindow/F FlipperPanel
	if(V_flag == 0)
		InitPolarizationFolders()
		InitFlipperGlobals()
		DrawFlipperPanel()
	endif
end

Function InitFlipperGlobals()

	SetDataFolder root:Packages:NIST:Polarization:Cells
	
	String/G gPsmPf = "Psm*Pf"
	String/G gPsm = "Psm"
	
	SetDataFolder root:
	return(0)
End


//
// makes the panel for the calculation of flipper and supermirror efficiencies
//
Function DrawFlipperPanel()

	SetDataFolder root:Packages:NIST:Polarization:Cells
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1023,44,1832,526)/N=FlipperPanel/K=1 as "Flipper and Supermirror"
	ModifyPanel cbRGB=(1,52428,26586)
	
	PopupMenu popup_0,pos={32,18},size={49,20},title="Field Condition",proc=FlipperPanelPopMenuProc
	PopupMenu popup_0,mode=1,value= #"D_ConditionNameList()"
	
	Button button_0,pos={42,310},size={100,20},proc=FlipperAverageButtonProc,title="Do Average"
	
	GroupBox group_0,pos={39,350},size={335,103},title="AVERAGED RESULTS",fSize=10
	GroupBox group_0,fStyle=1
	SetVariable setvar_0,pos={49,385},size={250,15},title="Sam_depol*Psm*Pf"
	SetVariable setvar_0,fStyle=1
	SetVariable setvar_0,limits={0,0,0},value= root:Packages:NIST:Polarization:Cells:gPsmPf
	SetVariable setvar_1,pos={49,417},size={250,15},title="Sam_depol*Psm",fStyle=1
	SetVariable setvar_1,limits={0,0,0},value= root:Packages:NIST:Polarization:Cells:gPsm
//	SetVariable setvar_2,pos={560,518},size={200,13},title="Gamma (h)",fStyle=1
//	SetVariable setvar_2,limits={0,0,0},barmisc={0,1000}
//	SetVariable setvar_2,value= root:Packages:NIST:Polarization:Cells:gGamma
//	SetVariable setvar_3,pos={560,488},size={200,15},title="T0",fStyle=1
//	SetVariable setvar_3,limits={0,0,0},value= root:Packages:NIST:Polarization:Cells:gT0
	

	Button button_1,pos={320,17},size={120,20},proc=AddFlipperConditionButton,title="Add Condition"
	Button button_2,pos={403,295},size={110,20},proc=ClearAllFlipperWavesButton,title="Clear Table"
	Button button_3,pos={183,310},size={120,20},proc=ShowFlipperCalcButton,title="Show Calc"
	Button button_4,pos={540,295},size={110,20},proc=ClearFlipperRowButton,title="Clear Row"
	Button button_5,pos={620,18},size={30,20},proc=FlipperHelpParButtonProc,title="?"
	Button button_6,pos={488,418},size={100,20},proc=WindowSnapshotButton,title="Snapshot"

	// table
	Edit/W=(14,55,794,275)/HOST=# 
	ModifyTable format=1,width=0
	RenameWindow #,T0
	SetActiveSubwindow ##

	SetDataFolder root:
	return(0)
End

Function AddFlipperConditionButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			// get the new name for the condition and the name of the cell used
			// the cell must already be defined
			String condStr, cellStr
			Prompt condStr,"Condition, <12 characters"
			Prompt cellStr,"Cell",popup,D_CellNameList()
			DoPrompt "Add new condition",condStr, cellStr
			if(V_Flag==1)
				return 0									// user canceled
			endif
			
			if(strlen(condStr) > 12)
				condStr = condStr[0,11]
				Print "Condition String trimmed to ",condStr
			endif
			
			String popStr
			popStr = condStr+"_"+cellStr
			
			MakeFlipperResultWaves(popStr)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function FlipperPanelPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SetDataFolder root:Packages:NIST:Polarization:Cells

			// based on the selected string, display the right set of inputs
//			Print "now I need to display the right set of waves (2D text?) for ",popStr
			
			if(cmpstr(popStr,"no conditions defined") == 0)
				SetDataFolder root:
				return(0)
			endif
			
			
			// for the given cell name, if the wave(s) exist, declare them
			if(exists(popStr) == 1)
				WAVE cond = $(popStr)
			else
				// if not, report an error				
				DoAlert 0,"The Cond_ waves should exist, this is an error"
				
				SetDataFolder root:
				return(0)
				//MakeFlipperResultWaves(popStr)
				//WAVE cond = $("root:Packages:NIST:Polarization:Cells:Cond_"+popStr)
			endif			
			// append matrix, clearing the old one first
			SetDataFolder root:Packages:NIST:Polarization:Cells

			KillWindow FlipperPanel#T0
			Edit/W=(14,55,794,275)/HOST=FlipperPanel
			RenameWindow #,T0
			AppendtoTable/W=FlipperPanel#T0 cond.ld			//show the labels
			ModifyTable width(Point)=0
			ModifyTable width(cond.l)=20
			
			SetActiveSubwindow ##
	
			SetDataFolder root:
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// waves are:
// "Cond_"+popStr
// and "CondCalc_"+popStr

Function MakeFlipperResultWaves(popStr)
	String popStr

	SetDataFolder root:Packages:NIST:Polarization:Cells

	Make/O/D/N=(1,8) $("Cond_"+popStr)
	WAVE cond = $("Cond_"+popStr)
	// set the column labels
	SetDimLabel 1,0,UU_Trans,cond
	SetDimLabel 1,1,DU_Trans,cond
	SetDimLabel 1,2,DD_Trans,cond
	SetDimLabel 1,3,UD_Trans,cond
	SetDimLabel 1,4,Blocked,cond
	SetDimLabel 1,5,Pol_SM_FL,cond
	SetDimLabel 1,6,Pol_SM,cond			//for a mask wave, non-zero is used in the fit
	SetDimLabel 1,7,Include,cond
	cond[0][7] = 1			//default to include the point
	
	// generate the dummy wave note now, change as needed
	String cellStr = StringFromList(1, popStr,"_")
	String testStr = "P_sm_f=2,err_P_sm_f=0,P_sm=0.6,err_P_sm=0,T0=asdf,Cell=asdf,"
	testStr = ReplaceStringByKey("Cell", testStr, cellStr ,"=", ",", 0)
	Note cond, testStr

	// to hold the results of the calculation
	Make/O/D/N=(1,14) $("CondCalc_"+popStr)
	WAVE CondCalc = $("CondCalc_"+popStr)
	SetDimLabel 1,0,CR1,CondCalc
	SetDimLabel 1,1,err_CR1,CondCalc
	SetDimLabel 1,2,CR2,CondCalc
	SetDimLabel 1,3,err_CR2,CondCalc
	SetDimLabel 1,4,CR3,CondCalc
	SetDimLabel 1,5,err_CR3,CondCalc
	SetDimLabel 1,6,CR4,CondCalc
	SetDimLabel 1,7,err_CR4,CondCalc
	SetDimLabel 1,8,CR5,CondCalc
	SetDimLabel 1,9,err_CR5,CondCalc
	SetDimLabel 1,10,P_sm_f,CondCalc
	SetDimLabel 1,11,err_P_sm_f,CondCalc
	SetDimLabel 1,12,P_sm,CondCalc
	SetDimLabel 1,13,err_P_sm,CondCalc	

	SetDataFolder root:

	return(0)
End


// just recalculate everything, every time
//
Function FlipperAverageButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable selRow,err=0
	String fname, t0str, condStr,noteStr,t1Str,cellStr

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Variable cr1,cr2,cr3,cr4,cr5,err_cr1,err_cr2,err_cr3,err_cr4,err_cr5
			Variable PsmPf, err_PsmPf, Psm, err_Psm
				
			ControlInfo/W=FlipperPanel popup_0
			condStr = S_Value
			WAVE w=$("root:Packages:NIST:Polarization:Cells:"+condStr)		//the one that is displayed
			WAVE calc=$("root:Packages:NIST:Polarization:Cells:CondCalc_"+condStr[5,strlen(condStr)-1])		//the one that holds results
			
			Variable numRows,ncalc,diff
			numRows = DimSize(w,0)		//rows in the displayed table
			ncalc = DimSize(calc,0)
			
			// add rows to the ConcCalc_ matrix as needed
			if(numRows != ncalc)
				if(ncalc > numRows)
					DoAlert 0,"The DecayCalc_ is larger than displayed. Seek help."
					err = 1
					return(err)
				else
					diff = numRows - ncalc
					InsertPoints/M=0 ncalc, diff, calc
				endif
			endif
			
			noteStr=note(w)
			cellStr = StringByKey("Cell", noteStr, "=", ",", 0)
			Wave decay = $("root:Packages:NIST:Polarization:Cells:Decay_"+cellStr)	
			noteStr=note(decay)
			t0Str = StringByKey("T0", noteStr, "=", ",", 0)
//			Print "CellStr, T0 = ",cellStr, t0Str

			Variable sum_PsmPf, err_sum_PsmPf, sum_Psm, err_sum_Psm
			sum_PsmPf = 0
			err_sum_PsmPf = 0
			sum_Psm = 0
			err_sum_Psm = 0
			
			for(selRow=0;selRow<numRows;selRow+=1)
				Print "calculate the row ",selRow

				// parse the rows, report errors (there, not here), exit if any found
				err = ParseFlipperRow(w,selRow)
				if(err)
					return 0
				endif
				
				// do the calculations:
	
				Print "The Blocked CR is not rescaled to zero attenuators"
				cr1 = TotalCR_FromRun(w[selRow][%UU_Trans],err_cr1,0)
				cr2 = TotalCR_FromRun(w[selRow][%DU_Trans],err_cr2,0)
				cr3 = TotalCR_FromRun(w[selRow][%DD_Trans],err_cr3,0)	
				cr4 = TotalCR_FromRun(w[selRow][%UD_Trans],err_cr4,0)
				cr5 = TotalCR_FromRun(w[selRow][%Blocked],err_cr5,1)		//blocked beam is NOT normalized to zero attenuators

				calc[selRow][%cr1] = cr1
				calc[selRow][%cr2] = cr2
				calc[selRow][%cr3] = cr3
				calc[selRow][%cr4] = cr4
				calc[selRow][%cr5] = cr5
				calc[selRow][%err_cr1] = err_cr1
				calc[selRow][%err_cr2] = err_cr2
				calc[selRow][%err_cr3] = err_cr3
				calc[selRow][%err_cr4] = err_cr4
				calc[selRow][%err_cr5] = err_cr5
	
				// Calc PsmPf, and assign the values
				PsmPf = Calc_PsmPf(w,calc,noteStr,selRow,err_PsmPf)
				calc[selRow][%P_sm_f] = PsmPf
				calc[selRow][%err_P_sm_f] = err_PsmPf
				w[selRow][%Pol_SM_FL] = PsmPf
				
				// Calc Psm, and assign the values
				Psm = Calc_Psm(w,calc,noteStr,selRow,err_Psm)
				calc[selRow][%P_sm] = Psm
				calc[selRow][%err_P_sm] = err_Psm
				w[selRow][%Pol_SM] = Psm

				// running average of PsmPf and Psm
				sum_PsmPf += PsmPf
				err_sum_PsmPf += err_PsmPf^2 
				sum_Psm += Psm
				err_sum_Psm += err_Psm^2
				
			endfor		//loop over rows
			
			// now get a running average of muP, Po, and the errors
			PsmPf = sum_PsmPf/numRows
			Psm = sum_Psm/numRows
			err_PsmPf = sqrt(err_sum_PsmPf) / numRows
			err_Psm = sqrt(err_sum_Psm) / numRows
			
//	this is the format of the note that is attached to the "Cond_" wave		
//	String testStr = "P_sm_f=2,err_P_sm_f=0,P_sm=0.6,err_P_sm=0,T0=asdf,Cell=asdf,"
// the "Cell" value was filled in when the Condition was created
	
	
// Put the average values into the wave note and display on the panel
			noteStr = note(w)
			noteStr = ReplaceNumberByKey("P_sm_f", noteStr, PsmPf ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("P_sm", noteStr, Psm ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_P_sm_f", noteStr, err_PsmPf ,"=", ",", 0)
			noteStr = ReplaceNumberByKey("err_P_sm", noteStr, err_Psm ,"=", ",", 0)
			
			// replace the string
			Note/K w
			Note w, noteStr
					
			//update the global values for display	
			SVAR gPsmPf = root:Packages:NIST:Polarization:Cells:gPsmPf
			SVAR gPsm = root:Packages:NIST:Polarization:Cells:gPsm
			sprintf gPsmPf, "%g +/- %g",PsmPf,err_PsmPf
			sprintf gPsm, "%g +/- %g",Psm,err_Psm
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// gCellKW passed in has gamma, muPo, etc. needed for PCell(t) calculation
//
// these are not the equations that Kaythrn gave to me, but rather
// equations 14 and 15 from the SS handout. These replacement equations
// are in terms of relative transmissions, so I can use count rates
// otherwise, I don't know how to calculate a transmission -- I don't know what
// the "empty beam" condition is...
//
//  this is only using the measurement at t1 for the calculation!
//
Function Calc_PsmPf(w,calc,gCellKW,selRow,err_PsmPf)
	WAVE w,calc
	String gCellKW
	Variable selRow,&err_PsmPf
	
	// DD is cr3, DU is cr2, Blocked is cr5
	String t0Str,t1Str,t2Str,fname
	Variable PsmPf,t1,t2,PCell_t1,PCell_t2,err_PCell_t1,err_PCell_t2
	Variable muPo,err_muPo,gam,err_gam
	Variable crDD, crDU,err_crDD,err_crDU,crBB, err_crBB
	
	t0Str = StringByKey("T0", gCellKW, "=", ",", 0)
	muPo = NumberByKey("muP", gCellKW, "=", ",", 0)
	err_muPo = NumberByKey("err_muP", gCellKW, "=", ",", 0)
	gam = NumberByKey("gamma", gCellKW, "=", ",", 0)
	err_gam = NumberByKey("err_gamma", gCellKW, "=", ",", 0)

	fname = FindFileFromRunNumber(w[selRow][%UU_Trans])
	t1str = getFileCreationDate(fname)
	t1 = ElapsedHours(t0Str,t1Str)
	
	fname = FindFileFromRunNumber(w[selRow][%DU_Trans])
	t2str = getFileCreationDate(fname)
	t2 = ElapsedHours(t0Str,t2Str)

	PCell_t1 = Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t1,err_PCell_t1)
	PCell_t2 = Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t2,err_PCell_t2)
	
	// DD is cr3, DU is cr2, Blocked is cr5
	crDD = calc[selRow][%cr3]
	crDU = calc[selRow][%cr2]
	crBB = calc[selRow][%cr5]
	err_crDD = calc[selRow][%err_cr3]
	err_crDU = calc[selRow][%err_cr2]
	err_crBB = calc[selRow][%err_cr5]
	
	// this really needs transmissions
//	PsmPf = (crDD - crDU)/(PCell_t1 + PCell_t2)
	
	// eqn (15) from the SS handout
	Variable tmp,dfdx
	tmp = (crDD - crBB)/(crDU - crBB)
	
	PsmPf = (tmp - 1)/(Pcell_t1*(1+tmp))
	
	dfdx = 1/(Pcell_t1*(1+tmp)) - (tmp-1)*Pcell_t1/(Pcell_t1^2*(1+tmp)^2)
	
	err_PsmPf = ( (tmp-1)/((1+tmp)*Pcell_t1^2) *err_Pcell_t1 )^2
	err_PsmPf += ( dfdx / (crDU-crBB) * err_crDD)^2
	err_PsmPf += ( dfdx*(crDD-crBB)/(crDU-crBB)^2 * err_crDU)^2
	err_PsmPf += ( dfdx*(-tmp/(crDD-crBB) + tmp/(crDU-crBB)) * err_crBB)^2
	
	err_PsmPf = sqrt(err_PsmPf)
	Printf "At t1=%g  PsmPf = %g +/- %g (%g%)\r",t1,PsmPf,err_PsmPf,err_PsmPf/PsmPf*100


	return(PsmPf)
end


// gCellKW passed in has gamma, muPo, etc. needed for PCell(t) calculation
//
// these are not the equations that Kaythrn gave to me, but rather
// equations 14 and 15 from the SS handout. These replacement equations
// are in terms of relative transmissions, so I can use count rates
// otherwise, I don't know how to calculate a transmission -- I don't know what
// the "empty beam" condition is...
//
//  this is only using the measurement at t1 for the calculation!
//
Function Calc_Psm(w,calc,gCellKW,selRow,err_Psm)
	WAVE w,calc
	String gCellKW
	Variable selRow,&err_Psm
	
	// UU is cr1, UD is cr4, Blocked is cr5
	String t0Str,t1Str,t2Str,fname
	Variable Psm,t1,t2,PCell_t1,PCell_t2,err_PCell_t1,err_PCell_t2
	Variable muPo,err_muPo,gam,err_gam
	Variable crUU, crUD,err_crUU,err_crUD,crBB, err_crBB
	
	t0Str = StringByKey("T0", gCellKW, "=", ",", 0)
	muPo = NumberByKey("muP", gCellKW, "=", ",", 0)
	err_muPo = NumberByKey("err_muP", gCellKW, "=", ",", 0)
	gam = NumberByKey("gamma", gCellKW, "=", ",", 0)
	err_gam = NumberByKey("err_gamma", gCellKW, "=", ",", 0)

	fname = FindFileFromRunNumber(w[selRow][%UU_Trans])
	t1str = getFileCreationDate(fname)
	t1 = ElapsedHours(t0Str,t1Str)
	
	fname = FindFileFromRunNumber(w[selRow][%DU_Trans])
	t2str = getFileCreationDate(fname)
	t2 = ElapsedHours(t0Str,t2Str)

	PCell_t1 = Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t1,err_PCell_t1)
	PCell_t2 = Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t2,err_PCell_t2)
	
	// UU is cr1, UD is cr4, Blocked is cr5
	crUU = calc[selRow][%cr1]
	crUD = calc[selRow][%cr4]
	crBB = calc[selRow][%cr5]
	err_crUU = calc[selRow][%err_cr1]
	err_crUD = calc[selRow][%err_cr4]
	err_crBB = calc[selRow][%err_cr5]
	
	// this really needs transmissions
	
	// eqn (14) from the SS handout
	Variable tmp,dfdx
	tmp = (crUU - crBB)/(crUD - crBB)
	
	Psm = (tmp - 1)/(Pcell_t1*(1+tmp))
	
	dfdx = 1/(Pcell_t1*(1+tmp)) - (tmp-1)*Pcell_t1/(Pcell_t1^2*(1+tmp)^2)
	
	err_Psm = ( (tmp-1)/((1+tmp)*Pcell_t1^2) *err_Pcell_t1 )^2
	err_Psm += ( dfdx / (crUD-crBB) * err_crUU)^2
	err_Psm += ( dfdx*(crUU-crBB)/(crUD-crBB)^2 * err_crUD)^2
	err_Psm += ( dfdx*(-tmp/(crUU-crBB) + tmp/(crUD-crBB)) * err_crBB)^2
	
	err_Psm = sqrt(err_Psm)
	Printf "At t1=%g  Psm = %g +/- %g (%g%)\r",t1,Psm,err_Psm,err_Psm/Psm*100


	return(Psm)
end



// t2 is in hours, muP0 is at t0
//
Function Calc_PCell_atT(muPo,err_muPo,gam,err_gam,t2,err_PCell)
	Variable muPo,err_muPo,gam,err_gam,t2,&err_PCell


	Variable Pcell


	PCell = tanh(muPo * exp(-t2/gam))
	
	Variable arg,tmp2
	arg = PCell
	tmp2 = (1-tanh(arg)^2)^2
	err_PCell = tmp2 * (exp(-t2/gam) * err_muPo)^2			//dominant term (10x larger)
	err_PCell += tmp2 * (arg*t2/gam/gam * err_gam)^2
	
	err_PCell = sqrt(err_Pcell)
	
	Printf "At t=%g  Pcell = %g +/- %g (%g%)\r",t2,Pcell,err_Pcell,err_Pcell/PCell*100



	return(PCell)
End

// bring up a table with the calculation results
Function ShowFlipperCalcButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo/W=FlipperPanel popup_0
			String condStr = S_Value
			condStr = condStr[5,strlen(condStr)-1]		// trim off "Calc_" from the beginning of the string
			WAVE calc=$("root:Packages:NIST:Polarization:Cells:CondCalc_"+condStr)		
			edit calc.ld
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// clear just the row
//
Function ClearFlipperRowButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String popStr=""
	Variable selRow
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 1,"Clear the selected row?"
			if(V_flag !=1)
				return(0)
			endif
			
			SetDataFolder root:Packages:NIST:Polarization:Cells

			ControlInfo/W=FlipperPanel popup_0
			popStr = S_Value
			
			Wave decay = $("Decay_"+popStr)
			Wave calc = $("DecayCalc_"+popStr)

			// Delete just those points
						
			GetSelection table, FlipperPanel#T0, 1
			selRow = V_startRow
			DeletePoints selRow,1,decay,calc			
			
			// clear the graph and the results			
			NVAR gMuPo = root:Packages:NIST:Polarization:Cells:gMuPo
			NVAR gPo  = root:Packages:NIST:Polarization:Cells:gPo
			NVAR gGamma  = root:Packages:NIST:Polarization:Cells:gGamma
			SVAR gT0  = root:Packages:NIST:Polarization:Cells:gT0
			gMuPo = 0
			gPo = 0
			gGamma = 0
			gT0 = "recalculate"
			
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// for this, do I want to clear everything, or just a selected row??
//
//
Function ClearAllFlipperWavesButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	String popStr=""
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 1,"Clear all of the decay waves for the selected cell?"
			if(V_flag !=1)
				return(0)
			endif
			
			SetDataFolder root:Packages:NIST:Polarization:Cells

			ControlInfo/W=FlipperPanel popup_0
			popStr = S_Value
			
			Wave decay = $("Decay_"+popStr)
			Wave calc = $("DecayCalc_"+popStr)
			
//			re-initialize the decay waves, so it appears as a blank, initialized table

			MakeFlipperResultWaves(popStr)
			decay = 0
			calc = 0
	
			// clear the graph and the results?	
			
			
					
			NVAR gMuPo = root:Packages:NIST:Polarization:Cells:gMuPo
			NVAR gPo  = root:Packages:NIST:Polarization:Cells:gPo
			NVAR gGamma  = root:Packages:NIST:Polarization:Cells:gGamma
			SVAR gT0  = root:Packages:NIST:Polarization:Cells:gT0
			gMuPo = 0
			gPo = 0
			gGamma = 0
			gT0 = "recalculate"
			
			
			SetDataFolder root:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function FlipperHelpParButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			DoAlert 0,"Help for Flipper Panel not written yet"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



// null condition is not right. if the loop fails, then the 
// retStr will be ";;;;", not zero length. What's the proper test?
// Does it matter? the list of default gCell_sss should already be there.
//
Function/S D_ConditionNameList()

	String listStr=""
	
	SetDataFolder root:Packages:NIST:Polarization:Cells

	// get a list of the Condition waves
	listStr=WaveList("Cond_*",";","")
	print listStr
	
	if(strlen(listStr) == 0)
		listStr = "no conditions defined;"
	endif
	
	SetDataFolder root:		
	return(listStr)
End


// parse the row to be sure that:
//
// - files are valid numbers
// - files are all at same SDD
// - files are all with same attenuation (just print a warning to cmd)
// - files all use the same cell
// - files are all within 20 minutes of each other
//
//
//	SetDimLabel 1,0,UU_Trans,cond
//	SetDimLabel 1,1,DU_Trans,cond
//	SetDimLabel 1,2,DD_Trans,cond
//	SetDimLabel 1,3,UD_Trans,cond
//	SetDimLabel 1,4,Blocked,cond
//	SetDimLabel 1,5,Pol_SM_FL,cond
//	SetDimLabel 1,6,Pol_SM,cond			//for a mask wave, non-zero is used in the fit
//	SetDimLabel 1,7,Include,cond
//
// There are 5 separate files now
//
Function ParseFlipperRow(w,selRow)
	Wave w
	Variable selRow
	
	Variable err=0
	Variable atten1,atten2,atten3,atten4,atten5
	Variable sdd1,sdd2,sdd3,sdd4,sdd5
	Variable t1,t2,t3,t4,t5
	String cell1,cell2,cell3,cell4,cell5
	
	
	String fname=""
	
	
	// are all file numbers valid?
	fname = FindFileFromRunNumber(w[selRow][%UU_Trans])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"UU_Trans run "+num2str(w[selRow][%UU_Trans])+" is not a valid run number"
		err = 1
	else
		atten1 = getAttenNumber(fname)
		sdd1 = getSDD(fname)
	endif
	
	fname = FindFileFromRunNumber(w[selRow][%DU_Trans])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"DU_Trans run "+num2str(w[selRow][%DU_Trans])+" is not a valid run number"
		err = 1
	else
		atten2 = getAttenNumber(fname)
		sdd2 = getSDD(fname)
	endif
	
	fname = FindFileFromRunNumber(w[selRow][%DD_Trans])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"DD_Trans run "+num2str(w[selRow][%DD_Trans])+" is not a valid run number"
		err = 1
	else
		atten3 = getAttenNumber(fname)
		sdd3 = getSDD(fname)
	endif
	
	fname = FindFileFromRunNumber(w[selRow][%UD_Trans])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"UD_Trans run "+num2str(w[selRow][%UD_Trans])+" is not a valid run number"
		err = 1
	else
		atten4 = getAttenNumber(fname)
		sdd4 = getSDD(fname)
	endif
	
	fname = FindFileFromRunNumber(w[selRow][%Blocked])
	if(cmpstr(fname,"")==0)
		DoAlert 0,"Blocked run "+num2str(w[selRow][%Blocked])+" is not a valid run number"
		err = 1
	else
		atten5 = getAttenNumber(fname)
		sdd5 = getSDD(fname)
	endif
	
	
	
	// do a check of the elapsed time from start to finish
	
	
	
	
	if( (sdd1 != sdd2) || (sdd2 != sdd3) || (sdd1 != sdd3) )
		DoAlert 0,"Files in row "+num2str(selRow)+" are not all at the same detector distance"
		err = 1
	endif
	
	
	
	
	
	if( (atten1 != atten2) || (atten2 != atten3) || (atten1 != atten3) )
		DoAlert 0,"Files in row "+num2str(selRow)+" are not all collected with the same attenuation. Just so you know."
		err = 0
	endif
	
	return(err)
end


////////////////////////////////////////////