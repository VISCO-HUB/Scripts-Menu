/*
[INFO]

NAME = Auto Material
VERSION = 1.0.6
AUTHOR = MastaMan
DEV = ViscoCG
HELP = \help\

[ABOUT]

Auto assign material from material library.=

[SCRIPT]

*/

macroScript IKEA_AutoMaterial
category:"[IKEA]"
toolTip:"Material"
(

	try(closeRolloutFloater fAutoMaterial)catch()
	local fAutoMaterial = newRolloutFloater "Auto Material" 260 545
	global szVer = "1.0.6"
	
	global szMatPath = @"\\visco.local\resource\ikea\MaterialsMAX2012\"
	global listMat = #()
	global goodChars = "1234567890"

	local fAutoMaterial
	local rAutoMaterialSettings
	local rAutoMaterial
	local rAbout

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
		local c = color 200 200 200 
		
		label lbl2 "Auto Material" 
		label lbl3 szVer
		
		label lbl5 "by MastaMan" 
		label lbl6 "" 

			
		hyperLink href2 "IKEA" address: "http://www.ikea.com/" align: #center hoverColor: c visitedColor: c
		hyperLink href "ViscoCG" address: "http://www.viscocg.com/" align: #center hoverColor: c visitedColor: c
	)

	addRollout rAutoMaterial fAutoMaterial rolledUp:false 
	addRollout rAutoMaterialSettings fAutoMaterial rolledUp:true 
	addRollout rAbout fAutoMaterial rolledUp:true 
	
	setFocus rAutoMaterial.edtMaterialName
)