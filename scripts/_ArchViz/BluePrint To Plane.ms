/*
[INFO]

NAME = BluePrint To Plane
VERSION = 1.0.1
AUTHOR = MastaMan
DEV = SightLine Vision
HELP = 


[1.0.0]

* First release =

[1.0.1]

* Adopt for new Scripts Launcher =


[ABOUT]

This script helps to place images drawings in the scene. =
Just select image file then the plane will be created with a image in the scene. =


[SCRIPT]
*/
try(closeRolloutFloater BluePrintToPlane)catch()
global BluePrintToPlane = newRolloutFloater "BluePrint To Plane" 200 180
global rImage


fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn parseToLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""				
	for i in m do l += i + "\n"
	return l
)

rollout rImage "Image"
(
	button btnSelectImage "Select Image" height:35 width: 160
	
	group "Settings"
	(
		spinner spnOpacity "Opacity: " range:[0,100,100] scale:5 align: #left width: 80 across: 2 offset:[-5, 0]
		spinner spnScale "Scale: " range:[0,999999,100] scale:5 align: #left width: 80 offset:[5, 0]
		button btnTop "T" across: 5 offset: [0, 6] align: #left tooltip: "Align for Top View"
		button btnFront "F" offset: [0, 6] align: #left tooltip: "Align for Front View"
		button btnLeft "L" offset: [0, 6] align: #left tooltip: "Align for Left View"
		button btnRight "R" offset: [0, 6] align: #left tooltip: "Align for Right View"
	)
	
	fn createPlane szImg =
	(
		n = getFilenameFile  szImg
		
		b = Bitmaptexture()
		b.name = n
		b.fileName = szImg
		
		m = Standardmaterial()
		m.name = n
		m.opacity = spnOpacity.value
		m.diffuseMap = b
		
		m.showInViewport = on
		
		p = plane()
		p.lengthsegs = 1
		p.widthsegs = 1
		p.name = n
		p.material = m
		p.width = b.bitmap.width / 100.0
		p.length = b.bitmap.height / 100.0
		p.showFrozenInGray = off
		
		s = rImage.spnScale.value / 100.0
		
		p.scale = [s, s, s]
		
		select p
	)
	
	fn setRotation r =
	(
		in coordsys local selection[1].rotation.controller.value = r
	)
	
	fn rotatePlane r =
	(
		if(selection[1] == undefined) do return false
		
		case r of
		(
			"f": setRotation (quat -0.5 0 0 0.5)
			"t": setRotation (quat 0 0 0 1)
			"r": setRotation (quat 0.5 0.5 0.5 -0.5)
			"l": setRotation (quat -0.5 0.5 0.5 0.5)			 			
		)
	)
		
	on btnSelectImage pressed do
	(
		szImg = getOpenFileName  caption:"Browse" types:"All files(*.*)|*.*|JPG(*.jpg)|*.jpg|Bitmap(*.bmp)|*.bmp|PNG(*.png)|png.*|"
		
		if(szImg != undefined)do
		(
			t = getFilenameType szImg
			
			case t of
			(
				".jpg": createPlane szImg
				".png": createPlane szImg
				".bmp": createPlane szImg
				default: 
				(
					messageBox "Image type must be: *.jpg, *.png, *.bmp" title: "Warning!"
					return false
				)
			)
		)
	)
		
	on rImage open do
	(	
		NitrousGraphicsManager.SetBackgroundTextureSizeLimit  6000 true
		NitrousGraphicsManager.SetTextureSizeLimit 6000 true
	)

	on spnOpacity changed v do
	(
		if(selection[1] != undefined and classOf selection[1].material == Standardmaterial) do
		(
			selection[1].material.opacity = v
		)
	)
	
	on spnScale changed v do
	(
		if(selection[1] != undefined) do
		(
			v = v / 100.0
			selection[1].scale = [v, v, v]
		)
	)
	
	on btnTop pressed do rotatePlane  "t"
	on btnFront pressed do rotatePlane  "f"
	on btnRight pressed do rotatePlane  "r"
	on btnLeft pressed do rotatePlane  "l"
)

rollout rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30

	
	on rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]	
	)
)

addRollout rImage BluePrintToPlane rolledUp:false 
addRollout rAbout BluePrintToPlane rolledUp:true