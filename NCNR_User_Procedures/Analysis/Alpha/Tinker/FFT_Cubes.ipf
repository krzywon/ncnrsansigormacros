#pragma rtGlobals=1		// Use modern global access method.// FFT and DebyeSphere calculations are now properly normalized to the conditions of:// deltaRho = 1e-7 (set as a global)// volume fraction = occupied fraction//// another thing to add - for the FFT when taking a slice. To test the rotational average, set up a loop// that does the FFT, rotates, sums the intensity (the q's are the same), and reports the average. May need to // rotate a large number of times to get a "real" average////// -- Feb 2011//	You can use N=512. The FFT takes about 140 s (first time), then 75s after that. //	The size of the whole experiment must be enormous. //	512^2 = 134 MB for the byte matrix. //	(512^3)/2*4 = 268 MB for the FFT result//// Function Interpolate2DSliceToData(folderStr)//		-- this function takes the 2D slice and interpolates the q-values to the experimental data for comparison (or a fit!)//Function Calc_IQ_FFT()//Proc DoFFT()		Variable t0=ticks,t1=ticks		fDoFFT()//	Print "FFT time (s) = ",(ticks - t1)/60.15		t1=ticks	fDoCorrection(dmat)	// dmat will exist, and be complex on input//	Print "Cube correction time (s) = ",(ticks - t1)/60.15		t1 = ticks	fGetMagnitude(tmp)		//complex on input, returns as real-valued//	Print "Magnitude Calculation time (s) = ",(ticks - t1)/60.15		t1=ticks	fDoBinning(dmat,0)	 // dmat is purely real when the binning is done, do not normalize result//	Print "Binning time (s) = ",(ticks - t1)/60.15		Print "Total FFT time (s) = ",(ticks - t0)/60.15	Print " "		//normalize the data	NVAR Tscale=root:FFT_T	NVAR FFT_N = root:FFT_N	NVAR delRho = root:FFT_delRho					//simply the units of SLD, not the absolute value	WAVE iBin = root:iBin	Variable vol,nx,phi		//	WaveStats/Q mat// must do this to get the number of non-zero voxels//	nx = NonZeroValues(mat)//	phi = nx/FFT_N^3//	vol = nx*(Tscale)^3	//	iBin *= phi//	iBin /= vol	//	iBin *= delRho*delRho//	iBin *= 1e8	////	iBin *= (Tscale)^6			//this puts units on the FFT(magnitude), Vol^2 = T^6			// iBin *= phi/vol*(1e-6)^2*(1e8)*T^6	// is equivalent to 	// iBin *= (T/N)^3 * (1e-6)^2*(1e8)		iBin *= delRho*delRho	iBin *= 1e8	iBin *= (Tscale/FFT_N)^3	end// for future speedups...// 1/2 the time is spent on the Duplicate and redimension step// other 1/2 is spent on the FFTFunction fDoFFT()		Wave mat=root:mat	Variable t0,t1	//	t1 = ticks	Duplicate/O mat dmat	Redimension/S dmat			//need single or double precision for FFT	//use single precision to use 1/2 memory space - since I'm averaging over the FFT result	// I don't need double precision.- the results are identical//	print (ticks-t1)/60.15		//Set the proper real-space dimensions for the cubes	//	NVAR Tscale=root:FFT_T//	Variable Tscale=5	SetScale/P x 0,(Tscale),"", dmat	SetScale/P y 0,(Tscale),"", dmat	SetScale/P z 0,(Tscale),"", dmat	////	t1=ticks	FFT dmat		// dmat is now COMPLEX//	print (ticks-t1)/60.15	// need to multiply the scaling of the FFT result by 2Pi to get proper q-units		SetScale/P x 0,(2*pi*DimDelta(dmat, 0)),"", dmat	// the FFT rotates zero to the center of the y and z dimensions, so use the DimOffset	SetScale/P y (2*pi*DimOffset(dmat, 1)),(2*pi*DimDelta(dmat, 1)),"", dmat	SetScale/P z (2*pi*DimOffset(dmat, 2)),(2*pi*DimDelta(dmat, 2)),"", dmat	EndFunction fDoCorrection_old(dmat)	Wave/C dmat	//  do the convolution with the cube here	// - a lengthy triple for loop	// Note that x-dimension is N/2+1 now, since it was a real input	// y,z dims are unchanged	Variable xDim=DimSize(dmat,0),yDim=DimSize(dmat,1),zDim=DimSize(dmat,2)	Variable ii,jj,kk	Variable xVal,yVal,zVal		Variable xfac,yfac,zfac	Variable dimOff0,dimOff1,dimOff2,delta0,delta1,delta2		NVAR Tscale=root:FFT_T	NVAR Nedge = root:FFT_N	if(WaveExists(SincWave) && SameDimensions(note(SincWave)) )		//just do the matrix multiplication		Wave SincWave=SincWave		MultiThread dmat *= SincWave		return(0)	else		//create the cube correction matrix		Make/O/N=(xDim,yDim,zDim) SincWave				dimOff0 = DimOffset(dmat, 0)		dimOff1 = DimOffset(dmat, 1)		dimOff2 = DimOffset(dmat, 2)		delta0 = DimDelta(dmat,0)		delta1 = DimDelta(dmat,1)		delta2 = DimDelta(dmat,2)					for(ii=0;ii<xDim;ii+=1)			xVal = dimOff0 + ii *delta0			xVal *= Tscale/2			if(ii==0)				xFac = 1			else				xFac = sinc(xVal)			endif			for(jj=0;jj<yDim;jj+=1)				yVal = dimOff1 + jj *delta1				yVal *= Tscale/2				if(jj==0)					yFac = 1				else					yFac = sinc(yVal)				endif				for(kk=0;kk<zDim;kk+=1)					zVal = dimOff2 + kk *delta2					zval *= Tscale/2					if(kk==0)						zFac = 1					else						zFac = sinc(zVal)					endif					SincWave[ii][jj][kk] = xfac*yfac*zfac					dmat[ii][jj][kk] *= (xfac*yfac*zfac)//*(xfac*yfac*zfac)				endfor			endfor		endfor		Note/K SincWave		Note SincWave, "T="+num2str(Tscale)+";N="+num2str(Nedge)+";"	endif		return(0)End//returns 1 if SincWave (the note) is the same as the matrix dimensions//  !! takes the values from the PANELFunction SameDimensions(str)	String str	NVAR Tscale=root:FFT_T	NVAR Nedge = root:FFT_N	if(NumberByKey("T", str ,"=",";") == Tscale && NumberByKey("N", str ,"=",";") == Nedge)		return(1)	else		return(0)	endifendFunction fGetMagnitude_old(dmat)	Wave/C dmat	//now get the magnitude, I(q) = |F(q)|^2	// do I want magnitude, or magnitude squared? = magsqr(z)		MultiThread dmat = r2polar(dmat)	Redimension/R dmat			//just the real part is the magnitude, throw away the complex part	MultiThread dmat *= dmat				//square it	//dmat is now a purely real matrix		End//dmat is a real matrix at this point// (1) use channel sharing (not yet implemented) - then will need to normalize by q^2 rather than nBins// --- channel sharing method does not seem to be as good...// (2) don't bin points beyond Qmax (done)//Function fDoBinning(dmat,normalize)	Wave dmat	Variable normalize		Variable xDim=DimSize(dmat,0),yDim=DimSize(dmat,1),zDim=DimSize(dmat,2)	Variable ii,jj,kk	Variable qX,qY,qZ,qTot	Variable binIndex,val	NVAR FFT_QmaxReal= root:FFT_QmaxReal		Make/O/D/N=(yDim*2) iBin,qBin,nBin	qBin[] = 0 + p*DimDelta(dmat, 1)/2		//use bins of 1/2 the width of the reciprocal lattice	SetScale/P x,0,DimDelta(dmat,1)/2,"",qBin		iBin = 0	nBin = 0	//number of intensities added to each bin		//loop through everything, and add it all up	Variable dimOff0,dimOff1,dimOff2,delta0,delta1,delta2	Variable pt,pt1,fra	dimOff0 = DimOffset(dmat, 0)	dimOff1 = DimOffset(dmat, 1)	dimOff2 = DimOffset(dmat, 2)	delta0 = DimDelta(dmat,0)	delta1 = DimDelta(dmat,1)	delta2 = DimDelta(dmat,2)			for(ii=0;ii<xDim;ii+=1)		qX = dimOff0 + ii *delta0		 		for(jj=0;jj<yDim;jj+=1)			qY = dimOff1 + jj *delta1						for(kk=0;kk<zDim;kk+=1)				qZ = dimOff2 + kk*delta2				qTot = sqrt(qX^2 + qY^2 + qZ^2)				if(qTot < FFT_QmaxReal)		//only take the time to use the good values				// binning method					binIndex = trunc(x2pnt(qBin, qTot))					val = dmat[ii][jj][kk]					if (numType(val)==0)		//count only the good points, ignore Nan or Inf						iBin[binIndex] += val						nBin[binIndex] += 1					endif				//				// channel sharing method (not as good)//					pt = (qTot - DimOffset(qBin,0))/DimDelta(qBin,0)		//fractional point//					val = dmat[ii][jj][kk]//					if (numType(val)==0)		//count only the good points, ignore Nan or Inf//						pt1 = trunc(pt)//						fra = pt - pt1//						iBin[pt1] += (1-fra)*val//						iBin[pt1+1] += fra*val//					endif				endif			endfor				endfor	endfor		iBin /= nBin	//normalize, iBin[0] will be NaN so use point[1], or the first "real" value	ii=0	do		if(nBin[ii] == 0 || nbin[ii] == 1)			DeletePoints 0,1, iBin,qBin,nBin		//keep deleting the first point if there were zero or one bins		else			val = ibin[ii]			if(numtype(val)==0)				break			endif			ii+=1		endif	while(ii<numpnts(ibin))// by channel sharing....(not as good)//	iBin /= qBin^2		//delete first two points (q=0 and q=Qmin)//	DeletePoints 0,2, iBin,qBin,nBin//	val = iBin[0]	if(normalize)		iBin /= val	//then normalize by the first point	endif			Duplicate/O iBin, iBinAll	Duplicate/O qBin, qBinAll	Duplicate/O nBin, nBinAll	//now truncate qBin at FFT_QmaxReal	FindLevel/Q/P qBin, FFT_QmaxReal		//level is reported as a point number, V_LevelX	DeletePoints  trunc(V_LevelX)+1, (numpnts(qBin) - trunc(V_LevelX)-1) , iBin,qBin,nBin		return(0)End//look for NaN in w1, delete point in w1 and w2Function DeleteNaNInf_XY(w1,w2)	Wave w1,w2		Variable num=numpnts(w1),ii		ii=0	do		if(numtype(w1[ii]) !=0)			//bad point, delete			DeletePoints ii, 1, w1,w2			//don't increment ii, but update (decrement) num			num = numpnts(w1)		else			//increment ii			ii += 1		endif			while(ii<num)EndFunction fDoCorrection(dmat)	Wave/C dmat	//  do the convolution with the cube here	// - a lengthy triple for loop	// Note that x-dimension is N/2+1 now, since it was a real input	// y,z dims are unchanged	Variable xDim=DimSize(dmat,0),yDim=DimSize(dmat,1),zDim=DimSize(dmat,2)	Variable ii,jj,kk	Variable xVal,yVal,zVal		Variable xfac,yfac,zfac	Variable dimOff0,dimOff1,dimOff2,delta0,delta1,delta2		NVAR Tscale=root:FFT_T	NVAR Nedge = root:FFT_N	if(WaveExists(SincWave) && SameDimensions(note(SincWave)) )		//just do the matrix multiplication		Wave SincWave=SincWave		MatrixOP/C tmp = dmat*SincWave				// preserve the scaling		SetScale/P x 0,DimDelta(dmat, 0),"", tmp		SetScale/P y DimOffset(dmat, 1),DimDelta(dmat, 1),"", tmp		SetScale/P z DimOffset(dmat, 2),DimDelta(dmat, 2),"", tmp				//dmat=tmp		return(0)	else		//create the cube correction matrix		Make/O/N=(xDim,yDim,zDim) SincWave				dimOff0 = DimOffset(dmat, 0)		dimOff1 = DimOffset(dmat, 1)		dimOff2 = DimOffset(dmat, 2)		delta0 = DimDelta(dmat,0)		delta1 = DimDelta(dmat,1)		delta2 = DimDelta(dmat,2)					for(ii=0;ii<xDim;ii+=1)			xVal = dimOff0 + ii *delta0			xVal *= Tscale/2			if(ii==0)				xFac = 1			else				xFac = sinc(xVal)			endif			for(jj=0;jj<yDim;jj+=1)				yVal = dimOff1 + jj *delta1				yVal *= Tscale/2				if(jj==0)					yFac = 1				else					yFac = sinc(yVal)				endif				for(kk=0;kk<zDim;kk+=1)					zVal = dimOff2 + kk *delta2					zval *= Tscale/2					if(kk==0)						zFac = 1					else						zFac = sinc(zVal)					endif					SincWave[ii][jj][kk] = xfac*yfac*zfac					dmat[ii][jj][kk] *= (xfac*yfac*zfac)//*(xfac*yfac*zfac)				endfor			endfor		endfor		Duplicate/O/C dmat,tmp		//slow the first time		Note/K SincWave		Note SincWave, "T="+num2str(Tscale)+";N="+num2str(Nedge)+";"	endif		return(0)EndFunction fGetMagnitude(tmp)	Wave/C tmp	//now get the magnitude, I(q) = |F(q)|^2	// do I want magnitude, or magnitude squared? = magsqr(z)		MatrixOP tmp2 = real(r2polar(tmp))		MatrixOP/O dmat=tmp2*tmp2	// preserve the scaling - MatrixOP does NOT	SetScale/P x 0,DimDelta(tmp, 0),"", dmat	SetScale/P y DimOffset(tmp, 1),DimDelta(tmp, 1),"", dmat	SetScale/P z DimOffset(tmp, 2),DimDelta(tmp, 2),"", dmat	Killwaves/Z tmp,tmp2	//	// clean up before exiting	//dmat is now a purely real matrix	return(0)End//	w is a real (2D) matrix at this point// -- it comes from a slice of dmat, so it has proper wave scaling// (2) don't bin points beyond Qmax (done)//Function fDoBinning_Scaled2D(w,normalize)	Wave w	Variable normalize		Variable xDim=DimSize(w,0),yDim=DimSize(w,1)	Variable ii,jj	Variable qX,qY,qTot	Variable binIndex,val	NVAR FFT_QmaxReal= root:FFT_QmaxReal		Make/O/D/N=(yDim*2) iBin_2d,qBin_2d,nBin_2d	qBin_2d[] = 0 + p*DimDelta(w, 1)/2		//use bins of 1/2 the width of the reciprocal lattice	SetScale/P x,0,DimDelta(w,1)/2,"",qBin_2d		iBin_2d = 0	nBin_2d = 0	//number of intensities added to each bin		//loop through everything, and add it all up	Variable dimOff0,dimOff1,delta0,delta1	Variable pt,pt1,fra	dimOff0 = DimOffset(w, 0)	dimOff1 = DimOffset(w, 1)	delta0 = DimDelta(w,0)	delta1 = DimDelta(w,1)		for(ii=0;ii<xDim;ii+=1)		qX = dimOff0 + ii *delta0		 		for(jj=0;jj<yDim;jj+=1)			qY = dimOff1 + jj *delta1			//			qZ = dimOff2 + kk*delta2			qTot = sqrt(qX^2 + qY^2)			if(qTot < FFT_QmaxReal)		//only take the time to use the good values			// binning method				binIndex = trunc(x2pnt(qBin_2d, qTot))				val = w[ii][jj]				if (numType(val)==0)		//count only the good points, ignore Nan or Inf					iBin_2d[binIndex] += val					nBin_2d[binIndex] += 1				endif			//				endif		endfor	endfor		iBin_2d /= nBin_2d	//normalize, iBin[0] will be NaN so use point[1], or the first "real" value	ii=0	do		if(nBin_2d[ii] == 0 || nBin_2d[ii] == 1)			DeletePoints 0,1, iBin_2d,qBin_2d,nBin_2d		//keep deleting the first point if there were zero or one bins		else			val = iBin_2d[ii]			if(numtype(val)==0)				break			endif			ii+=1		endif	while(ii<numpnts(iBin_2d))// by channel sharing....(not as good)//	iBin /= qBin^2		//delete first two points (q=0 and q=Qmin)//	DeletePoints 0,2, iBin,qBin,nBin//	val = iBin[0]	if(normalize)		iBin_2d /= val	//then normalize by the first point	endif			Duplicate/O iBin_2d, iBinAll_2d	Duplicate/O qBin_2d, qBinAll_2d	Duplicate/O nBin_2d, nBinAll_2d	//now truncate qBin at FFT_QmaxReal	FindLevel/Q/P qBin_2d, FFT_QmaxReal		//level is reported as a point number, V_LevelX	DeletePoints  trunc(V_LevelX)+1, (numpnts(qBin_2d) - trunc(V_LevelX)-1) , iBin_2d,qBin_2d,nBin_2d		return(0)End// this is how the 3D viewer in the image Processing macros works// to get the correct plane from the 3D matrixFunction get2DSlice(dmat)	wave dmat		ImageTransform/G=4 transposeVol dmat	WAVE M_VolumeTranspose	ImageTransform/P=0 getPlane M_VolumeTranspose	WAVE M_ImagePlane		Duplicate/O M_ImagePlane detPlane		//get the scaling right	NVAR FFT_N=root:FFT_N	NVAR FFT_T=root:FFT_T	NVAR delRho=root:FFT_delRho			detPlane *= delRho*delRho	detPlane *= 1e8	detPlane *= (FFT_T/FFT_N)^3	Duplicate/O detPlane logP		detPlane[FFT_N/2][FFT_N/2] = NaN			//hopefully this trims out the singularity at the center	logP = log(detPlane)		fDoBinning_Scaled2D(detPlane,0)		//last param = normalize y/n		KillWaves/Z M_VolumeTranspose,M_ImagePlane		return(0)end// using a 2D FFT slice, and a folder of real data, interpolate the FFT result to// match the q values of the data//// qz is assumed to be zero.//Function Interpolate2DSliceToData(folderStr)	String folderStr	Wave calc = root:detPlane	Wave data = $("root:"+folderStr+":"+folderStr+"_lin")		Duplicate/O data,interp2DSlice			//keeps the scaling of the data		Variable rowOff,colOff,rowDel,colDel	rowOff = DimOffset(data,0)	colOff = DimOffset(data,1)	rowDel = DimDelta(data,0)	colDel = DimDelta(data,1)// see pnt2x for explanation//	DimOffset(data, 0) + p *DimDelta(data,0)//	DimOffset(data, 1) + q *DimDelta(data,1)	interp2DSlice = Interp2D (calc, rowOff + p*rowDel, colOff + q*colDel )	Duplicate/O interp2DSlice interp2DSlice_log	interp2DSlice_log = log(interp2DSlice)	return(0)end////////// Routines to take the FFT result and convert it to USANS data//// - this is done by taking the 2D detector image and summing the columns (of corrrect Dq resolution)//// OCT/NOV 2013//// This is for when an anisotropic 2D result is desired//// these steps calculate the slit-smeared USANS from the FFT//// I think that the scaling of the USANS result is correct now//// -- for USANS length scales, need to set N ~ 256 and T ~ 500 to get the q-range into//    the proper range (deltaQ and qMax). 256*500 = 128,000 A = 12.8 microns per edge of the box//// 1D output is named "FFT_aUSANS_" (i and q) to signify "Anisotropic" USANS////// SRK 18 OCT 2013//Function Anisotropic_FFT_to_USANS()//figure out the proper Qmin, Qmax for the N and T//want deltaQ = 2e-5 to match the USANS instrumental resolution	Variable maxQx,Qy,num,deltaQ	String str,qmStr		NVAR FFT_N = root:FFT_N	NVAR FFT_T = root:FFT_T	NVAR FFT_QMaxReal = root:FFT_QMaxReal	NVAR delRho = root:FFT_delRho		deltaQ = 2e-5	num = round(FFT_QMaxReal/deltaQ)	if(num>1000)		Print "num = ",num		Abort "N and T are not set correctly for USANS. Reset these (N>=256 and T>=500) for an appropriate range."	endif	//	print "num = ",num		Qmstr = num2str(FFT_QMaxReal-2*deltaQ)		//using FFT_QMaxReal gives NaN at edges of interp2Dslice	str = "FakeQxQy(0,"+qmstr+",-"+qmstr+","+qmstr+","+num2str(num)+",\"USANS_Half\",1,0)"		//overwrites the data folder, no plot	Execute str// do the FFT	Calc_IQ_FFT()//	Execute "DoFFT()"// get the detector slice -- the slice is already on absolute scale	FFT_Get2DSlice("")// interpolate to the USANS-sized detector	Interpolate2DSliceToData("USANS_Half")	Wave interp2Dslice = $("root:interp2Dslice")// sum the rows		MatrixOp/O FFT_aUSANS_i=sumRows(interp2Dslice)	//automatically generates the destination		Make/O/D/N=(num) FFT_aUSANS_q	FFT_aUSANS_q = FFT_QMaxReal/num*x		//now get the scaling correct	// q-integration (rectangular), matrixOp simply summed, so I need to multiply by dy	FFT_aUSANS_i *= dimdelta(interp2dslice,1)	FFT_aUSANS_i *= 4		//why the factor of 4???		Execute "USANSDetectorHalf()"		// not needed -- occupancy and the normal FFT scaling are already done -- the slice is already on absolute scale	Variable occ = VolumeFraction_Occ(root:mat)	print "Fraction occupied = ",occ//	FFT_USANS_i *= occ	return(0)End//////// this is for when an isotropic 2D result is desired//// FIRST -- do the FFT - this calculates the 1D averaged result// SECOND -- get the 2D slice. this sets up a 2D matrix appropriately scaled to the q-space.// then - //// --Take the 1D FFT result - which is orientationally averaged, and convert it to a 2D plot// use the detPlane slice to get the 2D scaling - otherwise there's no need for detPlane// and I could just ask for qMin qMax in XY directions.//// --(optional) after this is called -- call fDoBinning_Scaled2D(avg2d,0) to confirm that it returns// back to the correct, orientationally averaged 1D//// --then to plot -- DisplayFFT_to2DAverage()////// finally, you can use the 2D result to either interpolate to a real 2D range, or more useful, convert// the 2D results to a USANS result. Then the case of an oddly shaped object can be converted to USANS. Previously// only the FFT slice (which is directional) could be converted to USANS. This limited the calculations to only// symmetric structures, which was not very useful.//// 1D output is named "FFT_iUSANS_" (i and q) to signify "isotropic" USANS//Function Isotropic_FFT_to_USANS()	Variable maxQx,Qy,num,deltaQ	String str,qmStr		NVAR FFT_N = root:FFT_N	NVAR FFT_T = root:FFT_T	NVAR FFT_QMaxReal = root:FFT_QMaxReal	NVAR delRho = root:FFT_delRho		deltaQ = 2e-5	num = round(FFT_QMaxReal/deltaQ)	if(num>1000)		Print "num = ",num		Abort "N and T are not set correctly for USANS. Reset these (N>=256 and T>=500) for an appropriate range."	endif	//	print "num = ",num		Qmstr = num2str(FFT_QMaxReal-2*deltaQ)		//using FFT_QMaxReal gives NaN at edges of interp2Dslice	str = "FakeQxQy(0,"+qmstr+",-"+qmstr+","+qmstr+","+num2str(num)+",\"USANS_Half\",1,0)"		//overwrites the data folder, no plot	Execute str// do the FFT	Calc_IQ_FFT()//	Execute "DoFFT()"// get the detector slice -- the slice is already on absolute scale	FFT_Get2DSlice("")	// now get the isotropically averaged I(Q) = iBin		WAVE iBin = iBin	WAVE qBin = qBin	Wave detPlane = root:detPlane		//just for the 2D scaling		Duplicate/O detPlane avg2d	avg2d = 0		Variable rowOff,colOff,rowDel,colDel	rowOff = DimOffset(avg2d,0)	colOff = DimOffset(avg2d,1)	rowDel = DimDelta(avg2d,0)	colDel = DimDelta(avg2d,1)// fill the 2D plane (qx,qy) with I(q) from the FFT		avg2d = interp( sqrt((rowOff + p*rowDel)^2 + (colOff + q*colDel)^2), qBin, iBin )//	avg2d = interp( sqrt((rowOff + p*rowDel)^2 + (colOff + q*colDel)^2), qval_XOP, ival_XOP )		Duplicate/O avg2d logAvg2d	logAvg2d = log(avg2d)		// interpolate to the USANS-sized detector, this is equivalent to://	Interpolate2DSliceToData("USANS_Half")		//except using avg2d rather than "calc = detPlane" (the anisotropic result)	String folderStr = "USANS_Half"	Wave data = $("root:"+folderStr+":"+folderStr+"_lin")		Duplicate/O data,interp2DSlice			//keeps the scaling of the data		rowOff = DimOffset(data,0)	colOff = DimOffset(data,1)	rowDel = DimDelta(data,0)	colDel = DimDelta(data,1)	interp2DSlice = Interp2D (avg2d, rowOff + p*rowDel, colOff + q*colDel )	Duplicate/O interp2DSlice interp2DSlice_log	interp2DSlice_log = log(interp2DSlice)// sum the rows		MatrixOp/O FFT_iUSANS_i=sumRows(interp2Dslice)	//automatically generates the destination		Make/O/D/N=(num) FFT_iUSANS_q	FFT_iUSANS_q = FFT_QMaxReal/num*x		//now get the scaling correct	// q-integration (rectangular), matrixOp simply summed, so I need to multiply by dy	FFT_iUSANS_i *= dimdelta(interp2dslice,1)	FFT_iUSANS_i *= 4		//why the factor of 4???	Execute "DisplayFFT_to2DAverage()"	Execute "USANSDetectorHalf()"// if you want to scale this to match a model calculation, you'll need the volume fraction	Variable occ = VolumeFraction_Occ(root:mat)	print "Fraction occupied = ",occ			return(0)EndProc USANSDetectorHalf()	DoWindow USANS_DetectorHalf	if(V_flag == 0)		PauseUpdate; Silent 1		// building window...		Display /W=(898,808,1083,1150)		DoWindow/C USANS_DetectorHalf		AppendImage/T interp2DSlice_log		ModifyImage interp2DSlice_log ctab= {*,*,YellowHot,0}		ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14,height={Aspect,2}		ModifyGraph mirror=2		ModifyGraph nticks=4		ModifyGraph minor=1		ModifyGraph fSize=9		ModifyGraph standoff=0		ModifyGraph tkLblRot(left)=90		ModifyGraph btLen=3		ModifyGraph tlOffset=-2		SetAxis/A/R left	endifEndProc DisplayFFT_to2DAverage()	DoWindow FFT_Avg2D	if(V_flag == 0)		PauseUpdate; Silent 1		// building window...		Display /W=(1038,44,1404,403)		DoWindow/C FFT_Avg2D		AppendImage/T avg2d		ModifyImage avg2d ctab= {*,*,YellowHot,0}		ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14		ModifyGraph mirror=2		ModifyGraph nticks=4		ModifyGraph minor=1		ModifyGraph fSize=9		ModifyGraph standoff=0		ModifyGraph tkLblRot(left)=90		ModifyGraph btLen=3		ModifyGraph tlOffset=-2		SetAxis/A/R left	endif		DoWindow FFT_logAvg2D	if(V_flag == 0)		Display /W=(1038,44,1404,403)		DoWindow/C FFT_logAvg2D		AppendImage/T logavg2d		ModifyImage logavg2d ctab= {*,*,YellowHot,0}		ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14		ModifyGraph mirror=2		ModifyGraph nticks=4		ModifyGraph minor=1		ModifyGraph fSize=9		ModifyGraph standoff=0		ModifyGraph tkLblRot(left)=90		ModifyGraph btLen=3		ModifyGraph tlOffset=-2		SetAxis/A/R left	endif	End