/*
[INFO]

NAME = Auto Material
VERSION = 1.0.6
AUTHOR = MastaMan
DEV = ViscoCG
HELP = \help\autoMaterial.html

[INSTALL]
MACRO=IKEA_AutoMaterial
CAT=IKEA
TEXT=Auto Material
ICON=#("Material_Modifiers", 3)

[1.0.0]

* First release =

[1.0.1]

Added basic functionality=

[1.0.2]

- BugFix: Correct open rollout from toolbar button=

[1.0.3]

* Changed: UI=
- Removed: Support *.ini=
+ Added: Ability to add materials via UI=

[1.0.4]

- BugFix: Small fixes=

[1.0.5]

+ Added: Insert Material button=
+ Added: Clear Material=
+ Added: "(Not found)" postfix in list, when can't found material=
+ Added: Query message continue create material if *.mat not found or used empty ID=
+ Added: Load list form exist materials=
* Changed: UI=

[1.0.6]

* Changed: Apply material for Active material slot

[1.0.7]
* Adopted for new Scripts Launcher=

[ABOUT]

Auto assign material from material library.=

[SCRIPT]

*/

try(closeRolloutFloater fAutoMaterial)catch()
global fAutoMaterial = newRolloutFloater "Auto Material" 260 545
global szVer = "1.0.6"

global szMatPath = @"\\visco.local\resource\ikea\MaterialsMAX2012\"
global listMat = #()
global goodChars = "1234567890"

global fAutoMaterial
global rAutoMaterialSettings
global rAutoMaterial
global rAbout

fn isGoodChars s =
(
	c = #()
	c = filterString s goodChars
	
	if(s == "") do return false
	
	return c.count == 0
)

fn useSettings k v type:#get =
(
	f = getThisScriptFilename() + ".ini"
	case type of
	(
		#set: setIniSetting f "SETTINGS" k v
		default: getIniSetting f "SETTINGS" k
	)
)

rollout rAutoMaterial "Create Material" 
(	
	group "Material List"
	(			
		listbox lbxPreview height: 20
		edittext edtMaterialName "Name:" fieldWidth: 90 align: #left  across: 3
		spinner spnID "ID:" type: #integer align: #right range: [1, 100, 1] fieldWidth: 30 offset: [45, 0]
		button brnIncrement "+" align: #right offset:[0, -2]
		
		
		button btnAddID "Add/Edit Material" across: 2 offset: [0, 5] width: 95
		button btnInsertID "Insert Material" offset: [0, 5]	width: 95		
		button btnClearID "Clear Material" offset: [0, 5] across: 2  width: 95
		button btnDelID "Delete Material" offset: [0, 5]  width: 95
	)
		
	
	group "Create"
	(
		button btnCreatemMat "Create" width: 205 height: 35
		checkbox cbxAutoAssing "Assign to model" checked: true
	)
	
	fn setEdtFocus =
	(
		setFocus rAutoMaterial.edtMaterialName
		edtMaterialName.text = ""
	)
	
	fn matFile f = szMatPath + f + ".mat"
	
	fn isExist n = n != undefined  and doesFileExist (matFile n)
	
	fn previewMaterials =
	(				
		lbxPreview.items = for i in 1 to listMat.count collect (i as string + ": ") + (if(listMat[i] == undefined) then "" else listMat[i] + (if(not isExist listMat[i]) then " (Not found)" else "")) 
	)
	
	fn parseItem i =
	(
		s = filterString i ":"
		
		if(s[2] != undefined) do return s[2]
		if(s[1] != undefined) do return s[1]
		return ""
	)
	
	fn clearUnusedId = 
	(
		for i in listMat.count to 1 by -1 do 
		(	
			if(listMat[i] == undefined) then deleteItem listMat i else exit
		)
	)
	
	fn setLastID = spnID.value = listMat.count + 1
				
	on btnInsertID pressed do
	(
		id = lbxPreview.selection
		m = edtMaterialName.text
		
		if(id == 0) do return false
		
		setEdtFocus()
		
		if(m == "" or isGoodChars m == false) do 
		(			
			return messageBox "Please enter correct Material Name!" title: "Warning!"
		)
		
		insertItem m listMat id
					
		previewMaterials()
		
		setEdtFocus()
		
		setLastID()
	)
	
	on spnID changed x do
	(
		try(lbxPreview.selection = x) catch()
	)
	
	on btnAddID pressed do
	(
		m = edtMaterialName.text
		id = spnID.value
			
		setEdtFocus()
		
		if(m == "" or isGoodChars m == false) do 
		(			
			return messageBox "Please enter correct Material Name!" title: "Warning!"
		)
		
		if(listMat[id] != undefined) do 
		(
			q = queryBox ("Do you really want to replace item: " + lbxPreview.items[id] + " to " + m)
			
			if(not q) do return false
		)
		
		listMat[id] = m
		
		previewMaterials()
		
		setLastID()
		
		setEdtFocus()
	)
	
	on btnDelID pressed do
	(
		id = lbxPreview.selection
							
		if(id == 0) do return false
		
		q =  queryBox ("Do you really want to delete item: " + lbxPreview.items[id] + " ?")
		
		if(not q) do return false
		
		deleteItem listMat id
					
		clearUnusedId()
	
		if(lbxPreview.items.count > 0 and lbxPreview.items[id] != undefined) then
		(				
			lbxPreview.selection = id			
		)
		else
		(
			setLastID()
		)
			
		previewMaterials()
	)
	
	on btnClearID pressed do
	(
		id = lbxPreview.selection
		
		if(id == 0) do return false
		
		q =  queryBox ("Do you really want to clear item: " + lbxPreview.items[id] + " ?")
		
		if(not q) do return false
		
		listMat[id] = undefined	

		previewMaterials()			
	)
	
	on lbxPreview selected x do
	(
		spnID.value = x
	)
	
	on brnIncrement pressed do
	(
		spnID.value += 1
	)
	
	on cbxAutoAssing changed x do
	(
		useSettings "AUTO_ASSIGN" (x as string) type:#set
	)

	fn loadList = 
	(
		o = $model*
		
		m = #()
		
		for i in o where i.material != undefined do append m i.material
				
		m = makeUniqueArray m
		
		if(m.count != 1 or classOf m[1] != MultiMaterial) do return false
		mat = m[1]			
		for i in 1 to mat.count do listMat[i] = if(mat.names[i] == "") then undefined else mat.names[i]
		
		previewMaterials()	
	)
	
	on rAutoMaterial open do
	(
		autoAssign = useSettings "AUTO_ASSIGN" ""
		cbxAutoAssing.checked = if(autoAssign == "false" ) then false else true	

		loadList()
	)
			
	on btnCreatemMat pressed do
	(						
		if(listMat.count == 0) do return messageBox "Please add materials to list!" title: "Warning"
		
		errorMissingID = for i in 1 to listMat.count where listMat[i] == undefined collect i as string
		if(errorMissingID.count != 0) do
		(
			missingId = ""
			for i in errorMissingID do missingId += " " + i + ","
			missingId[missingId.count] = ""
			
			q = queryBox ("Found missing ID's in list!\n\nFix next ID:" + missingId+ ".\n\nDo you want tot continue?") title: "Warning!"
			if(not q) do return false
		)
							
		errorBrokenMat = for i in 1 to listMat.count where (listMat[i] != undefined and not doesFileExist (matFile listMat[i])) collect listMat[i] + ".mat"
		
		if(errorBrokenMat.count != 0) do 
		(			
			brokenMats = ""
			for i in errorBrokenMat do brokenMats += i + "\n"
			
			q = queryBox ("Not found next materials:\n\n" + brokenMats + "\nUsed path:\n" + szMatPath + "\n\nDo you want to continue?") title: "Warning!"
			if(not q) do return false
		)
			
		m = multiMaterial()
		m.numsubs = listMat.count
		m.name = "material"
		
		for i in 1 to listMat.count do
		(	
			id = i as integer
			
			if(listMat[i] == undefined) do
			(
				m[id] = undefined
				m.names[id] = ""
				continue
			)
			
			if(not doesFileExist (matFile listMat[i])) do
			(
				m[id] = undefined
				m.names[id] = listMat[i]
				continue
			)
											
			t = loadTempMaterialLibrary (matFile listMat[i])
							
			
			
			m[id] = t[1]
			m.names[id] = listMat[i]
		)
		
		setMeditMaterial activeMeditSlot  m
					
		if(cbxAutoAssing.checked) do
		(
			mdl = $model*
			if(mdl.count > 0) do for i in mdl do i.material = m
		)
	)
)
rollout rAutoMaterialSettings "Settings" 
(	
	group "Materials Path"
	(
		edittext edtMatPath "" height: 25 readOnly: true
		button btnSelectMatPath "Select Path" 
	)

	on rAutoMaterialSettings open do
	(
		tmpMatPath= useSettings "MAT_PATH" ""
		
		if(tmpMatPath != "") do szMatPath = tmpMatPath		
			
		edtMatPath.text = szMatPath
	)
	
	on btnSelectMatPath pressed do
	(
		f = getSavePath caption:"Choose Materials Path" initialDir: szMatPath
			
		if(f == undefined) do return false
		
		szMatPath = f + "\\"
		edtMatPath.text = szMatPath
		useSettings "MAT_PATH" szMatPath type:#set
	)
)

rollout rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	button btnHelp "Help" enabled: false
	
	fn getScriptIniInfo s releaseInfo: "" =
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
		t = getINISetting s "TEST"
		
		r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" and i != "TEST" collect i
		
		return #(n, a, v, o, r, c, h, t)
	)
	
	fn getHelp run: false =
	(
		s = getThisScriptFilename()
		i = getScriptIniInfo s
		szHelp = (getFilenamePath s) + i[7]
		if(i[7] != "" and doesFileExist szHelp) do btnHelp.enabled = true
			
		if(run) do ShellLaunch szHelp ""
	)
	
	on btnHelp pressed do getHelp run: true
			
	on rAbout open do
	(		
		i = getScriptIniInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
		
		getHelp()
	)
)

addRollout rAutoMaterial fAutoMaterial rolledUp:false 
addRollout rAutoMaterialSettings fAutoMaterial rolledUp:true 
addRollout rAbout fAutoMaterial rolledUp:true 

setFocus rAutoMaterial.edtMaterialName
