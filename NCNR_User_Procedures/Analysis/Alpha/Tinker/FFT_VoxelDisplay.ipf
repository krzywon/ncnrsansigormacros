#pragma rtGlobals=1		// Use modern global access method.Window Gizmo_VoxelMat() : GizmoPlot	PauseUpdate; Silent 1	// Building Gizmo 6 window...	// Do nothing if the Gizmo XOP is not available.	if(exists("NewGizmo")!=4)		DoAlert 0, "Gizmo XOP must be installed"		return	endif	NewGizmo/N=Gizmo_VoxelMat/T="Gizmo_VoxelMat" /W=(1557,254,2015,684)	ModifyGizmo startRecMacro	AppendToGizmo voxelgram=root:mat,name=voxelgram0	ModifyGizmo ModifyObject=voxelgram0 property={ valueRGBA,0,1,1.5259e-05,0.195544,0.8,0.3}	ModifyGizmo ModifyObject=voxelgram0 property={ mode,0}	ModifyGizmo ModifyObject=voxelgram0 property={ pointSize,3}	AppendToGizmo Axes=boxAxes,name=axes0	ModifyGizmo ModifyObject=axes0,property={-1,axisScalingMode,1}	ModifyGizmo ModifyObject=axes0,property={-1,axisColor,0,0,0,1}	ModifyGizmo ModifyObject=axes0,property={0,ticks,2}	ModifyGizmo ModifyObject=axes0,property={1,ticks,2}	ModifyGizmo ModifyObject=axes0,property={2,ticks,2}	ModifyGizmo modifyObject=axes0 property={Clipped,0}	AppendToGizmo light=Directional,name=light0	ModifyGizmo light=light0 property={ position,0.000000,0.000000,-1.000000,0.000000}	ModifyGizmo light=light0 property={ direction,0.000000,0.000000,-1.000000}	ModifyGizmo light=light0 property={ ambient,0.866667,0.866667,0.866667,1.000000}	ModifyGizmo light=light0 property={ specular,1.000000,1.000000,1.000000,1.000000}	AppendToGizmo freeAxesCue={0,0,0,1.5},name=freeAxesCue0	AppendToGizmo attribute blendFunc={770,771},name=blendFunc0	ModifyGizmo setDisplayList=0, object=freeAxesCue0	ModifyGizmo setDisplayList=1, object=light0	ModifyGizmo setDisplayList=2, attribute=blendFunc0	ModifyGizmo setDisplayList=3, object=voxelgram0	ModifyGizmo setDisplayList=4, object=axes0	ModifyGizmo SETQUATERNION={0.358770,0.538311,0.643129,0.409744}	ModifyGizmo autoscaling=1	ModifyGizmo currentGroupObject=""	ModifyGizmo compile//	ModifyGizmo showInfo//	ModifyGizmo infoWindow={1350,1036,1821,1272}//	ModifyGizmo bringToFront	ModifyGizmo endRecMacroEnd// a simple slice viewer ? where did this come from?// plots xy slice at z(ii) as an image, and loops through the z-slices// cmd-. to stop at any slice, sleepTime slows the rate.// a new image is created every time//Proc AnimatedSlices(matStr)	String matStr="mat"		variable ii=0,num,sleepTime=0.3	num=DimSize(mat,2)	//Print "num = ",num	Display /W=(5,44,313,319)	AppendImage $matStr	ModifyImage $matStr ctab= {*,*,YellowHot,1}	ModifyImage $matStr plane= 0	ModifyGraph width={Aspect,1},height={Aspect,1}	ModifyGraph mirror=2	TextBox/N=text0/A=MC/X=43.30/Y=-44.20 ""		do		modifyimage $matStr plane=(ii)		TextBox/C/N=text0 num2str(ii+1)+"/"+num2str(num)		DoUpdate		Sleep/S sleepTime		ii+=1	while(ii<num)EndProc ShowFullMatrix()		//get the maximum dimensions - assumes input matrix "mat"	Variable xm,ym,zm	xm=DimSize(mat,0)	ym=DimSize(mat,1)	zm=DimSize(mat,2)		ModifySurfer  xmin=0,ymin=0,zmin=0	ModifySurfer  xmax=xm,ymax=ym,zmax=zmEnd//plots each point in 3D space, does NOT autoscale to the input data//Proc PlotXYZ(xStr,yStr,zStr)	String xStr="x3d",yStr="y3d",zStr="z3d"		//get the maximum dimensions - assumes input matrix "mat"	Variable xm,ym,zm	xm=DimSize(mat,0)	ym=DimSize(mat,1)	zm=DimSize(mat,2)		CreateSurfer	MoveWindow 4,44,517,382 	ModifySurfer  FactoryDefaults, Update=0	ModifySurfer/N=Surface0	ModifySurfer srcWave=($xStr,$yStr,$zStr)	ModifySurfer  srcType=4,plotType=5	ModifySurfer  setControlView=3	ModifySurfer  zScale=1,  xStep=1,  yStep=1	ModifySurfer  frame=895,  drawFrame=1	ModifySurfer  xmin=0,ymin=0,zmin=0	ModifySurfer  xmax=xm,ymax=ym,zmax=zm	ModifySurfer  drawBox=1	ModifySurfer  drawTicks=5	ModifySurfer backRGB={65535,65535,65535}	ModifySurfer palette=Grays	ModifySurfer markerRGB={65535,0,0}	ModifySurfer  grids=1	ModifySurfer  marker=19,  markerSize=2	ModifySurfer  scatterDepthCue=1//	ModifySurfer  autoscale=1	ModifySurfer  Update=1	End