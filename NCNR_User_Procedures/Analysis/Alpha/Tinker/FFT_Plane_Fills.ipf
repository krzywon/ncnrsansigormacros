#pragma rtGlobals=1		// Use modern global access method.// some very, very simple fills for lines and planes.// not of much use right now, but a good example of how to// index and access lines and planes in the 3D space//Function GridOfLines(m)	Wave m		Variable num=DimSize(m,0),ii=0		for(ii=0;ii<num;ii+=10)		m[][ii][ii] = 1		m[ii][][ii] = 1		m[ii][ii][] = 1	endfor	EndFunction PlanesInMatrix(m)	Wave m		Variable num=DimSize(m,0),ii=0		for(ii=0;ii<num;ii+=10)		m[][][ii] = 1				//fill the XY plane//		m[ii][][] = 1				//fill the YZ plane//		m[][ii][] = 1				//fill the XZ plane	endfor	EndFunction MakeTactoid()	WAVE mat=root:mat	Variable ii,trim=10	Variable num=DimSize(mat,0)		PlanesInMatrix(mat)		//the whole YZ plane (gives INF FFT)		//chop the planes down	for(ii=0;ii<trim;ii+=1)		mat[][][ii] = 0		mat[ii][][] = 0		mat[][ii][] = 0	endfor	for(ii=num-1;ii>(num-1-trim);ii-=1)		mat[][][ii] = 0		mat[ii][][] = 0		mat[][ii][] = 0	endforend