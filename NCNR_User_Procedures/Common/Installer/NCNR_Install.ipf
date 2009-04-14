#pragma rtGlobals=1		// Use modern global access method.



///
// ***********
// it may be prefereable to COPY the files to the UP folder, so that the installer doesn't "eat" itself 
// and require users to re-download if they do something wrong. the difficulty with CopyFolder is that
// on Windows it does a "mix-in" copy, rather than a delete/overwrite all. So it may be better to just leave
// the installer as is, requiring a fresh copy each time. SRK 10MAR09
//
//
///

// Install the NCNR Macros

//InstallNCNRMacros() // run this function when experiment is loaded
//InstallerPanel() // run this function when experiment is loaded

//
// package-6.001
// - lots more diagnostics added

Function InstallNCNRMacros(forceInstall)
	Variable forceInstall		// if == 1, install whatever possible, even if R/W errors from the OS

	//first step, check for Igor 6!!!
	if(NumberByKey("IGORVERS", IgorInfo(0)) < 6)
		Abort "You must be running Igor 6 or later to use these macros."
	endif
	
	
	// check to see if the installer has already been run... if so, the folders will be gone... stop now BEFORE removing things
	String test = IndexedDir(home, -1, 0)	
	if(stringmatch(test, "*NCNR_User_Procedures*") == 0)
		print test
		Abort "You've already run the installer. If you want to re-install, you'll need a fresh copy from the NCNR website."
	endif
	
	// check for install problems
	// locked folders, OS errors _err will be non-zero if there is an error
	Variable UP_err,IH_err,IE_err
	UP_err = FolderPermissionCheck("User Procedures:")
	IH_err = FolderPermissionCheck("Igor Help Files:")
	IE_err = FolderPermissionCheck("Igor Extensions:")	
//	Print UP_err,IH_err,IE_err

	String alertStr=""
	if(UP_err != 0)
		alertStr += "User Procedures has no write permission.\r"
	endif
	if(IH_err != 0)
		alertStr += "Igor Help Files has no write permission.\r"
	endif
	if(IE_err != 0)
		alertStr += "Igor Extensions has no write permission.\r"
	endif
	
	if(forceInstall == 0)
		if(UP_err != 0 || IH_err != 0 || IE_err != 0)
			alertStr += "You will need to install manually."
			DoAlert 0,alertStr
			return(0)
		endif
	endif
	
	
	// check the platform
	Variable isMac=0
	if(cmpstr("Macintosh",IgorInfo(2))==0)
		isMac=1
	endif
	

	String igorPathStr,homePathStr
	PathInfo Igor
	igorPathStr = S_Path		//these have trailing colons
	PathInfo home					//the location where this was run from...
	homePathStr = S_Path
	
	// clean up old stuff, moving to home:old_moved_files
	// extensions - these show up as files, even the aliases
	// help files - these are files
	// user procedures - these can be in folders or as files
	variable i=0, AliasSet=0, isThere = 0
	String tmpStr
	
// clean up the Igor Extensions
	NewPath /Q/O ExPath, igorPathStr+"Igor Extensions:"
	PathInfo ExPath
	String extPathStr = S_Path 
	string strFileList = IndexedFile(ExPath, -1, "????" )
	
	Wave/T extFiles=root:IExtFiles
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,extFiles)
		if(isThere)
			MoveFile/O/P=ExPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from Igor Extensions: "+num2str(V_flag)
		endif
	endfor
	
	//then anything that shows up as a folder
	Wave/T extFolders=root:IExtFolders
	strFileList = IndexedDir(ExPath, -1, 0 )
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,extFolders)
		if(isThere)
			MoveFolder extPathStr+tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from Igor Extensions: "+num2str(V_flag)
		endif
	endfor
	
// clean up the user procedures (files first)
	NewPath /Q/O UPPath, igorPathStr+"User Procedures:"
	PathInfo UPPath
	String UPPathStr = S_Path
	strFileList = IndexedFile(UPPath, -1, "????" )			//for files
	
	Wave/T UPFilesWave=root:UPFiles
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,UPFilesWave)
		if(isThere)
			MoveFile/O/P=UPPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from User Procedures: "+num2str(V_flag)
		endif
	endfor
	
// clean up the user procedures (folders second)
	strFileList = IndexedDir(UPPath, -1, 0)			//for folders, just the names, not full paths
	
	Wave/T UPFoldersWave=root:UPFolders
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,UPFoldersWave)
		if(isThere)
		// THIS is the problem, when NCNR_Help_Files is moved - it is in use
			MoveFolder/Z UPPathStr + tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from User Procedures: "+num2str(V_flag)
		endif
	endfor

// now try to move the  Igor Help files out
	NewPath /Q/O IHPath, igorPathStr+"Igor Help Files:"
	PathInfo IHPath
	String IHPathStr = S_Path
	strFileList = IndexedFile(IHPath, -1, "????" )			//for files
	
	Wave/T IHFilesWave=root:IHFiles
	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IHFilesWave)
		if(isThere)
			MoveFile/O/P=IHPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			Print "Move file "+ tmpStr + " from Igor Help Files: "+num2str(V_flag)
		endif
	endfor	
	
	// then anything that shows up as a folder
	Wave/T IHFilesWave=root:IHFolders
	strFileList = IndexedDir(IHPath, -1, 0)	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
		isThere = CheckForMatch(tmpStr,IHFolders)
		if(isThere)
			MoveFolder IHPathStr + tmpStr as homePathStr+"NCNR_Moved_Files:NCNR_Moved_Folders:"+tmpStr
			Print "Move folder "+ tmpStr + " from Igor Help Files: "+num2str(V_flag)
		endif
	endfor
	
// INSTALL the new stuff
//(1) copy the items to install to the User Procedures folder
//(2) set up the aliases from there
//
// the old ones should be gone already, so just put in the new ones

// they may not be possible to remove, so try to overwrite...

//  and then create shortcuts for XOP and help files
//	MoveFolder/Z=1/O homePathStr+"NCNR_Help_Files" as UPPathStr+"NCNR_Help_Files"
//	Print "Move folder NCNR_Help_Files into User Procedures, overwrite if needed: "+num2str(V_flag)
//	if(V_Flag != 0)
		MoveFolder/Z=1 homePathStr+"NCNR_Help_Files" as UPPathStr+"NCNR_Help_Files"
		Print "******Move folder NCNR_Help_Files into User Procedures, NO overwite: "+num2str(V_flag)
//	endif
	CreateAliasShortcut/O/P=UPPath "NCNR_Help_Files" as igorPathStr+"Igor Help Files:NCNR_Help_Files"
	Print "Creating shortcut from NCNR_Help_Files into Igor Help Files: "+num2str(V_flag)
	
	
//	MoveFolder/Z=1/O homePathStr+"NCNR_User_Procedures" as UPPathStr+"NCNR_User_Procedures"
//	Print "Move folder NCNR_User_Procedures into User Procedures, overwrite if needed: "+num2str(V_flag)
//	if(V_flag !=0)
		MoveFolder/Z=1 homePathStr+"NCNR_User_Procedures" as UPPathStr+"NCNR_User_Procedures"
		Print "*******Move folder NCNR_User_Procedures into User Procedures, NO overwrite: "+num2str(V_flag)
//	endif	
	// don't need an alias for the UserProcedures - they're already here....


//	MoveFolder/Z=1/O homePathStr+"NCNR_Extensions" as UPPathStr+"NCNR_Extensions"
//	Print "Move folder NCNR_Extensions into User Procedures, overwrite if needed: "+num2str(V_flag)
//	if(V_flag !=0)
		MoveFolder/Z=1 homePathStr+"NCNR_Extensions" as UPPathStr+"NCNR_Extensions"
		Print "*******Move folder NCNR_Extensions into User Procedures, NO overwrite: "+num2str(V_flag)
//	endif
	if(isMac)
		CreateAliasShortcut/O/P=UPPath "NCNR_Extensions:Mac_XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
	else
		CreateAliasShortcut/O/P=UPPath "NCNR_Extensions:Win_XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
	endif
	Print "Creating shortcut for XOP into Igor Extensions: "+num2str(V_flag)
	

// put shortcuts to the template in the "top" folder
//??
	NewPath/O/Q UtilPath, homePathStr+"NCNR_SANS_Utilities:"
	strFileList = IndexedFile(UtilPath,-1,".pxt")	
	for (i=0; i<itemsInList(strFileList); i+=1)
		tmpStr = StringFromList(i,strFileList)
//		isThere = CheckForMatch(tmpStr,IHFolders)
//		if(isThere)
//			Print "Move "+ tmpStr
//			MoveFolder/O/P=IHPath tmpStr as homePathStr+"NCNR_Moved_Files:"+tmpStr
			CreateAliasShortcut/O/P=UtilPath tmpStr as homePathStr +tmpStr
			Print "Creating shortcut for "+tmpStr+" into top level: "+num2str(V_flag)
//		endif
	endfor
	
// old method, used shortcuts from main package (risky if user deletes them)
//	CreateAliasShortcut/O/P=home "NCNR_Help_Files" as igorPathStr+"Igor Help Files:NCNR_Help_Files"
//	CreateAliasShortcut/O/P=home "NCNR_User_Procedures" as igorPathStr+"User Procedures:NCNR_User_Procedures"
//	if(isMac)
//		CreateAliasShortcut/O/P=home "NCNR_Extensions:Mac XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
//	else
//		CreateAliasShortcut/O/P=home "NCNR_Extensions:Win XOP" as igorPathStr+"Igor Extensions:NCNR_Extensions"
//	endif
	

// installation is done, quit to start fresh
	DoAlert 1, "Quit Igor to complete installation.\rQuit now? "
	if (V_Flag==1)
		execute "Quit /Y"
	endif
	
	return 1
End

// return (1) if str is an entry in tw
// must be an exact match, with or without ".lnk" extension
//
Function CheckForMatch(str,tw)
	String str
	Wave/T tw
	
	Variable num=numpnts(tw),ii=0
	
	do
		if(cmpstr(str,tw[ii])==0 || cmpstr(str,tw[ii]+".lnk")==0)
			return (1)
		endif
		ii+=1
	while(ii<num)
	
	return(0)
End


Function InstallButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			InstallNCNRMacros(0)
			break
	endswitch

	return 0
End

Function UpdateCheckButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			Execute "CheckForLatestVersion()"
			break
	endswitch

	return 0
End

Function DiagnosticsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			InstallDiagnostics()
			break
	endswitch

	return 0
End

Window InstallerPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(150,50,445,292)	/K=2
	Button button0,pos={73,24},size={150,40},proc=InstallButtonProc,title="Install SANS Macros"
	Button button0,fColor=(1,26214,0)
	Button button0_1,pos={75,94},size={150,40},proc=UpdateCheckButtonProc,title="Check for Updates"
	Button button0_1,fColor=(1,26221,39321)
	Button button0_2,pos={75,164},size={150,40},proc=DiagnosticsProc,title="Print Diagnostics"
	Button button0_2,fColor=(65535,0,0)
EndMacro

// generate a notebook with install diagnostics suitable for e-mail
Function InstallDiagnostics()
	
	String nb="Install_Diagnostics_v6",textStr
	
	DoWindow/F $nb
	if(V_flag==0)
		NewNotebook/N=$nb/F=0 /W=(387,44,995,686) as nb
	else
		//clear contents
		Notebook $nb selection={startOfFile, endOfFile}	
		Notebook $nb text="\r"
	endif	
	
// what version, what platform
	Notebook $nb text="**Install Diagnostics**\r\r"
	Notebook $nb text="**Version / Platform**\r"
	textStr =  IgorInfo(0)+"\r"
	Notebook $nb text=textStr
	textStr =  IgorInfo(2)+"\r"
	Notebook $nb text=textStr
// what is the currently installed version from the string
	PathInfo Igor
	String IgorPathStr = S_Path
	String fileNameStr = IgorPathStr + "User Procedures:NCNR_User_Procedures:InstalledVersion.txt"
	String installedStr
	Variable refnum
	
	Open/R/Z refNum as fileNameStr
	if(V_flag != 0)
		//couldn't find the file
		textstr = "I could not determine what version of the SANS Macros you are running."
	else
		FReadLine refNum, installedStr
		Close refnum
		textStr = installedStr
	endif
	
	// check for permissions
	Variable UP_err,IH_err,IE_err
	UP_err = FolderPermissionCheck("User Procedures:")
	IH_err = FolderPermissionCheck("Igor Help Files:")
	IE_err = FolderPermissionCheck("Igor Extensions:")
	
	Print UP_err,IH_err,IE_err
	
	String alertStr=""
	if(UP_err != 0)
		alertStr += "User Procedures has no write permission. Error = "+num2Str(UP_err)+"\r"
	else
		alertStr += "User Procedures permission is OK.\r"
	endif
	if(IH_err != 0)
		alertStr += "Igor Help Files has no write permission. Error = "+num2Str(IH_err)+"\r"
	else
		alertStr += "Igor Help Files permission is OK.\r"
	endif
	if(IE_err != 0)
		alertStr += "Igor Extensions has no write permission. Error = "+num2Str(IE_err)+"\r"
	else
		alertStr += "Igor Extensions permission is OK.\r"
	endif
	
	if(UP_err != 0 || IH_err != 0 || IE_err != 0)
		alertStr += "You will need to install manually."
	endif
	
	Notebook $nb text="\r\r**Folder Permissions**\r"
	Notebook $nb text=AlertStr +"\r"
	
	
	Notebook $nb text="\r\r**InstalledVersion.txt**\r"
	Notebook $nb text=textStr +"\r"

// get listings of everything in each folder
	string strfileList=""

// what is the listing of the Igor Extensions
	Notebook $nb text="\r\r**Igor Extensions (files)**\r"
	NewPath /Q/O ExPath, igorPathStr+"Igor Extensions:"
	
	//files
	strFileList = IndexedFile(ExPath, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**Igor Extensions (folders)**\r"
	strFileList = IndexedDir(ExPath, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"


// what is the listing of Igor Help files
	Notebook $nb text="\r\r**Igor Help (files)**\r"
	NewPath /Q/O IHPath, igorPathStr+"Igor Help Files:"

	//files
	strFileList = IndexedFile(IHPath, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**Igor Help (folders)**\r"
	strFileList = IndexedDir(IHPath, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"
	
	
// what is the listing of the User Procedures
	Notebook $nb text="\r\r**User Procedures (files)**\r"
	NewPath /Q/O UPPath, igorPathStr+"User Procedures:"
	//files
	strFileList = IndexedFile(UPPath, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**User Procedures (folders)**\r"
	strFileList = IndexedDir(UPPath, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"
	
// what is the listing of the Igor Procedures

//  generating a path for this seems to be problematic - since it can't be killed , or found on another computer
// that is (apparently) because if there is anything included from the IgP folder (and there is on even the default installation)
// - then the path is "in use" and can't be killed...
//
	Notebook $nb text="\r\r**Igor Procedures (files)**\r"
	NewPath /Q/O IgorProcPath, igorPathStr+"Igor Procedures:"

	//files
	strFileList = IndexedFile(IgorProcPath, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**Igor Procedures (folders)**\r"
	strFileList = IndexedDir(IgorProcPath, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"
//
//
	// then get a listing of the "home" directory. If files were not moved properly, they will still be here
	Notebook $nb text="\r\r**Home (files)**\r"
//	NewPath /Q/O IgorProcPath, igorPathStr+"Igor Procedures:"

	//files
	strFileList = IndexedFile(home, -1, "????" )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr

	//folders
	Notebook $nb text="\r**Home (folders)**\r"
	strFileList = IndexedDir(home, -1, 0 )
	textStr = ReplaceString(";", strFileList, "\r")
	Notebook $nb text=textStr+"\r"
	
	//move to the beginning of the notebook
	Notebook $nb selection={startOfFile, startOfFile}	
	Notebook $nb text=""
	
	return(0)
End

Function AskUserToKillHelp()

	//// clean up the Igor help files
// first, kill any open help files
// there are 5 of them
	Variable numHelpFilesOpen=0
//	do
		numHelpFilesOpen = 0
		// V_flag is set to zero if it's found, non-zero (unspecified value?) if it's not found
		DisplayHelpTopic/Z "Beta SANS Tools"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
		
		DisplayHelpTopic/Z "SANS Data Analysis Documentation"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
				
		DisplayHelpTopic/Z "SANS Model Function Documentation"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
				
		DisplayHelpTopic/Z "SANS Data Reduction Tutorial"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
				
		DisplayHelpTopic/Z "USANS Data Reduction"
		if(V_flag==0)
			numHelpFilesOpen += 1
		endif
			
//		PauseForUser		// can't use this, it keeps you from interacting with anything....
//	while(NumHelpFilesOpen != 0)
	DoWindow HelpNotebook
	if(V_flag)
		DoWindow/K HelpNotebook
	endif
	
	String helpStr = "Please kill the open Help Files by holding down the OPTION key (Macintosh) or ALT key (Windows) and then CLICKING on the close box of each help window."
	helpStr += " Once you have finished, please close this window and install the SANS Macros."
	if(NumHelpFilesOpen != 0)
		NewNotebook/F=1/K=1/N=HelpNotebook /W=(5,44,547,380) as "Please close the open help files"
		Notebook HelpNotebook,fsize=18,fstyle=1,showRuler=0,text=helpStr
		return(0)
	endif

	return(0)
End

//check each of the three folders
// folder string MUST have the trailing colon
Function FolderPermissionCheck(folderStr)
	String folderStr
	Variable refnum
	String str="delete me"
	
	String igorPathStr,resultStr=""
	PathInfo Igor
	igorPathStr = S_Path
	
	NewPath /Q/O tmpPath, igorPathStr+folderStr

	
	Open/Z/P=tmpPath refnum as "test.txt"
	if(V_flag != 0)
		return(V_flag)
	else
		FBinWrite refnum,str
		Close refnum
		
//		Print "folder OK"
		DeleteFile/Z/P=tmpPath  "test.txt"
	endif
	
	
	return(V_flag)
end

// this will "force" an install, even if there are R/W errors
Macro ForceInstall()

	Execute "InstallNCNRMacros(1)"
end