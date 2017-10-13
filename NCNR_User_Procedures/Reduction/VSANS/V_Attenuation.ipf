#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// functions to calculate attenuator values from the tables
//
// V_CalculateAttenuationFactor(fname)
// V_CalculateAttenuationError(fname)
//
// interpolate if necessary


//
// patch entire tables if necessary
//
//
//


// attenuator tables are currently /N=(8,17)


Proc V_LoadCSVAttenTable()

	// this load command will:
	// load CSV data into a matrix
	// skip a one-line header
	// name it "atten0"
	// prompt for file
	LoadWave/J/M/D/A=atten/E=1/K=1/L={0,1,0,0,0}				//will prompt for the file, auto name
	
	Rename atten0, atten_values

End

Proc V_LoadCSVAttenErrTable()

	// this load command will:
	// load CSV data into a matrix
	// skip a one-line header
	// name it "atten0"
	// prompt for file
	LoadWave/J/M/D/A=atten/E=1/K=1/L={0,1,0,0,0}				//will prompt for the file, auto name
	
	Rename atten0, atten_err

End

// V_writeAttenIndex_table(fname,inW)
//
// V_writeAttenIndex_table_err(fname,inW)
//

Proc V_WriteCSVAttenTable(lo,hi,atten_values)
	Variable lo,hi
	String atten_values

	V_fPatchAttenValueTable(lo,hi,$atten_values)
End

Proc V_WriteCSVAttenErrTable(lo,hi,atten_err)
	Variable lo,hi
	String atten_err

	V_fPatchAttenErrTable(lo,hi,$atten_err)
End


// simple utility to patch the attenuator table wave in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchAttenValueTable(lo,hi,attenW)
	Variable lo,hi
	Wave attenW
	
	Variable ii
	String fname
	
	// check the dimensions of the attenW (8,17)
	if (DimSize(attenW, 0) != 8 || DimSize(attenW, 1) != 17 )
		Abort "attenuator wave is not of proper dimension (8,17)"
	endif
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		fname = V_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			V_writeAttenIndex_table(fname,attenW)			
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End

// simple utility to patch the attenuator error (std dev) wave in the file headers
// lo is the first file number
// hi is the last file number (inclusive)
//
Function V_fPatchAttenErrTable(lo,hi,attenW)
	Variable lo,hi
	Wave attenW
	
	Variable ii
	String fname
	
	// check the dimensions of the attenW (8,17)
	if (DimSize(attenW, 0) != 8 || DimSize(attenW, 1) != 17 )
		Abort "attenuator wave is not of proper dimension (8,17)"
	endif
	
	//loop over all files
	for(ii=lo;ii<=hi;ii+=1)
		fname = V_FindFileFromRunNumber(ii)
		if(strlen(fname) != 0)
			V_writeAttenIndex_table_err(fname,attenW)			
		else
			printf "run number %d not found\r",ii
		endif
	endfor
	
	return(0)
End



//////////////////////
//
// function to calculate the attenuation factor from the table in the file
//
// fill in a "dummy" wavelength for White Beam and graphite
// == 100 for White Beam
// == 1000 for graphite
// use these dummy values just for the lookup table
//
// TODO -- need the enumerated values for the monochromator type
// TODO -- V_getMonochromatorType(fname) is NOT written correctly by NICE
//
//
Function V_CalculateAttenuationFactor(fname)
	String fname
	
	Variable val,lambda,numAtt
	String monoType
	
	numAtt = V_getAtten_number(fname)
	lambda = V_getWavelength(fname)
	
	// TODO -- need to switch on "type"
	//  == velocity_selector || ?? for white beam || graphite
//	monoType = V_getMonochromatorType(fname)

	monoType = V_DeduceMonochromatorType(fname)
	print monoType

	// set a fake wavelength for the interpolation or get out
	strswitch(monoType)	// string switch
		case "velocity_selector":	// execute if case matches expression
			// use lambda as-is
			break		// exit from switch
		case "white_beam":	// execute if case matches expression
			lambda = 100
			break
		case "crystal":
			lambda = 1000
			break
		default:			// optional default expression executed
			Abort "Monochromator type could not be determined in V_CalculateAttenuationFactor"		// when no case matches
	endswitch
	
	
	Wave w = V_getAttenIndex_table(fname)		// N=(8,17)
	Make/O/D/N=8 tmpVal,tmpLam
	
	tmpVal = w[p][numAtt+1]		// offset by one, 1st column is wavelength
	tmpLam = w[p][0]
	val = interp(lambda, tmpLam, tmpVal )
	
	//killwaves/Z tmpVal,tmpLam
	return(val)
	
End

//////////////////////
//
// function to calculate the attenuation error from the table in the file
//
// fill in a "dummy" wavelength for White Beam and graphite
// == 100 for White Beam
// == 1000 for graphite
// use these dummy values just for the lookup table
//
// TODO -- need the enumerated values for the monochromator type
// TODO -- V_getMonochromatorType(fname) is NOT written correctly by NICE
//
Function V_CalculateAttenuationError(fname)
	String fname
	
	Variable val,lambda,numAtt
	String monoType
	
	numAtt = V_getAtten_number(fname)
	lambda = V_getWavelength(fname)
	
	// TODO -- need to switch on "type"
	//  == velocity_selector || ?? for white beam || graphite
//	monoType = V_getMonochromatorType(fname)
	
	monoType = V_DeduceMonochromatorType(fname)
	print monoType
	// set a fake wavelength for the interpolation or get out
	strswitch(monoType)	// string switch
		case "velocity_selector":	// execute if case matches expression
			// use lambda as-is
			break		// exit from switch
		case "white_beam":	// execute if case matches expression
			lambda = 100
			break
		case "crystal":
			lambda = 1000
			break
		default:			// optional default expression executed
			Abort "Monochromator type could not be determined in V_CalculateAttenuationError"		// when no case matches
	endswitch	
	
	Wave w = V_getAttenIndex_error_table(fname)		// N=(8,17)
	Make/O/D/N=8 tmpVal,tmpLam
	
	tmpVal = w[p][numAtt+1]		// offset by one, 1st column is wavelength
	tmpLam = w[p][0]
	val = interp(lambda, tmpLam, tmpVal )
	
	//killwaves/Z tmpVal,tmpLam
	return(val)
	
End

// TODO -- this may not correctly mimic the enumerated type of the file
//  but I need to fudge this somehow
//
// returns null string if the type cannot be deduced, calling procedure is responsible
//  for properly handling this error condition
//
Function/S V_DeduceMonochromatorType(fname)
	String fname
	
	String typeStr=""

	if(cmpstr(V_getVelSelStatus(fname),"IN") == 0)
		typeStr = "velocity_selector"
	endif
	
	if(cmpstr(V_getWhiteBeamStatus(fname),"IN") == 0)
		typeStr = "white_beam"
	endif
	
	if(cmpstr(V_getCrystalStatus(fname),"IN") == 0)
		typeStr = "crystal"
	endif	
	
	return(typeStr)
End