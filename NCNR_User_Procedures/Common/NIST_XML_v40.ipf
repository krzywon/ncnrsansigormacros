#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.00
#pragma IgorVersion=6.0

#include "cansasXML_v11", version >= 1.10


function LoadNISTXMLData(filestr,doPlot)
	String filestr
	Variable doPlot
	
	
	Variable rr,gg,bb
	NVAR dQv = root:Packages:NIST:USANS_dQv

		
	Print "Trying to load canSAS XML format data" 
	Variable result = CS_XMLReader(filestr)
	
	String xmlReaderFolder = "root:Packages:CS_XMLreader:"
	
	if (result == 0)
			SetDataFolder xmlReaderFolder
						
			Variable i
			
			for (i = 0; i < CountObjects(xmlReaderFolder,4); i+=1)
				
				String xmlDataFolder = xmlReaderFolder+GetIndexedObjName(xmlReaderFolder,4,i)+":"
								
				SetDataFolder xmlDataFolder
										
				String w0,w1,w2
			
				String basestr = CleanupName(getXMLDataSetTitle(xmlDataFolder),0)
				//String basestr = ParseFilePath(3, ParseFilePath(5,filestr,":",0,0),":",0,0)				
				String fileName =  ParseFilePath(0,ParseFilePath(5,filestr,":",0,0),":",1,0)
					
				//print "In NIST XML Loader"
				//print "fileStr: ",fileStr
				//print "basestr: ",basestr
				//print "fileName: ",fileName
				//remove the semicolon AND period from files from the VAX
				w0 = basestr + "_q"
				w1 = basestr + "_i"
				w2 = basestr + "_s"
				
				if(DataFolderExists("root:"+baseStr))
						DoAlert 1,"The data set " + basestr + " from file "+fileName+" has already been loaded. Do you want to load the new data file, overwriting the data in memory?"
						if(V_flag==2)	//user selected No, don't load the data
							SetDataFolder root:
							if(DataFolderExists("root:Packages:NIST"))
								String/G root:Packages:NIST:gLastFileName = filename
							endif		//set the last file loaded to the one NOT loaded
							return	0	//quits the macro
						endif
						SetDataFolder $("root:"+baseStr)
				else
					NewDataFolder/S $("root:"+baseStr)
				endif
	
				Duplicate/O $(xmlDataFolder+"Qsas") $w0
				Duplicate/O $(xmlDataFolder+"Isas") $w1
				Duplicate/O $(xmlDataFolder+"Idev") $w2


					
				if (exists(xmlDataFolder+"Qdev"))
					Wave Qsas = $(xmlDataFolder+"Qsas")
					Wave Qdev = $(xmlDataFolder+"Qdev")
				
				// make a resolution matrix for SANS data
					Variable np=numpnts($w0)
					Make/D/O/N=(np,4) $(baseStr+"_res")
					Wave reswave =  $(baseStr+"_res")
					
					reswave[][0] = Qdev[p]		//sigQ
					reswave[][3] = Qsas[p]	//Qvalues
					if(exists(xmlDataFolder+"Qmean"))
						Wave Qmean = $(xmlDataFolder+"Qmean")
						reswave[][1] = Qmean[p]		//qBar
					endif
					if(exists(xmlDataFolder+"Shadowfactor"))
						Wave Shadowfactor = $(xmlDataFolder+"Shadowfactor")
						reswave[][2] = Shadowfactor[p]		//fShad
					endif
				elseif(exists(xmlDataFolder+"dQl"))
					//USAS Data
					Wave dQl = $(xmlDataFolder+"dQl")
					dQv = dQl[0]
				
					USANS_CalcWeights(baseStr,dQv)
				else
					//No resolution data
				endif
					//get rid of the resolution waves that are in the matrix
			
					SetScale d,0,0,"1/A",$w0
					SetScale d,0,0,"1/cm",$w1
				
					
		
				//////
				if(DataFolderExists("root:Packages:NIST"))
					String/G root:Packages:NIST:gLastFileName = filename
				endif
			
				
				//plot if desired
				if(doPlot)
					// assign colors randomly
					rr = abs(trunc(enoise(65535)))
					gg = abs(trunc(enoise(65535)))
					bb = abs(trunc(enoise(65535)))
					
					// if target window is a graph, and user wants to append, do so
				   DoWindow/B Plot_Manager
					if(WinType("") == 1)
						DoAlert 1,"Do you want to append this data to the current graph?"
						if(V_Flag == 1)
							AppendToGraph $w1 vs $w0
							ModifyGraph mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1) =(rr,gg,bb),tickUnit=1
							ErrorBars $w1 Y,wave=($w2,$w2)
							ModifyGraph tickUnit(left)=1
						else
						//new graph
							Display $w1 vs $w0
							ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
							ModifyGraph grid=1,mirror=2,standoff=0
							ErrorBars $w1 Y,wave=($w2,$w2)
							ModifyGraph tickUnit(left)=1
							Legend
						endif
					else
					// graph window was not target, make new one
						Display $w1 vs $w0
						ModifyGraph log=1,mode($w1)=3,marker($w1)=19,msize($w1)=2,rgb($w1)=(rr,gg,bb),tickUnit=1
						ModifyGraph grid=1,mirror=2,standoff=0
						ErrorBars $w1 Y,wave=($w2,$w2)
						ModifyGraph tickUnit(left)=1
						Legend
					endif
				endif
			endfor
	endif

	//go back to the root folder and clean up before leaving
	SetDataFolder root:
	//KillDataFolder xmlReaderFolder
	

end


function/S getXMLDataSetTitle(xmlDF)
	String xmlDF

	String mdstring = xmlDF+"metadata"
	print mdstring

	Wave/T meta = $mdstring
	FindValue/TEXT="Title"/TXOP=4/Z meta

	String title = meta[V_Value][1]
	
	return title
end

function isXML(filestr)
	String filestr
	
	String line
	Variable fileref
	
	Open/R fileref as filestr
	FReadLine fileref,  line
	Close fileref
	
	//Hopefully this will distinguish between other formats and the XML
	return stringmatch(line, "*xml*")	

end