/*
[INFO]

NAME = SpeedTree Exporter
VERSION = 1.1.6
AUTHOR = MastaMan
DEV = SightLine Vision
HELP = 

[1.0.0]

* First release=

[1.0.1]

* More faster linker =
+ Add helper controllers =
- BugFix: Edit poly detection =

[1.0.2]

* Changed calculate scale for Particles =
- BugFix: Apply scale when PF_Source don't =
have name!=

[1.0.3]

* Remove lock function for spinners=
* Change calculate scale for Objects=
* Set Particles scale in spinners=
* Change output filename treesData.stf to =
Trees.stf=
+ Add Random Rotation =
+ Add Random Position=
+ Add warning when *.stf file not checkout=
- BugFix: Dont't select items in list when select=
particles	=
- Remove warning message about a lot of points=
- Remove Scale Step spinner=

[1.0.4]

- BugFix: Save correctly with SaveAs Dialog=
[1.0.5]
+ Add Export option Selected in Viewport=
+ Improve Trees List =
+ Improve scale transform=
* Fix some bugs=

[1.0.6]

- BugFix: Impossible link if we have one type of=
tree in list=

[1.1.0]

- BugFix: Don't select objects from context menu=
in ListView=
- BugFix: Export more then selected in viewport =
objects=
* Change scale for objects only in Z-axis=
* Change label with project path to editbox=

[1.1.1]

+ Auto open last project folder=
+ Add button Select=
- Remove context menu=

[1.1.2]

* Change scale for objects in all axis=

[1.1.3]

*For old scenes rename and unlink trees=

[1.1.4]

- BugFix: Impossible link same type=

[1.1.5]

- BugFix: Collect geometry function=
* Adopt for new Scripts Launcher=

[1.1.6]

- BugFix: Particles rotation=

[1.1.7]

* Increace maximum value fot Object Scale to 9999=

[ABOUT]

This script helps export "SpeedTrees" boxes=
in to *.stf file.=
_______________________________________=
Features:=
- Show list of SpeedTree=
- Show count objects and particles=
- Hide Empty in list=
- Quick link objects and particles to selected =
type of tree=
- Scale, rotation and position features	=
- Export to *.stf=
- Savable settings=

[SCRIPT]
*/

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


try(closeRolloutFloater rSpeedTreeTools)catch()
global rSpeedTreeTools = newRolloutFloater "SpeedTree Exporter" 250 870

global settingsFile = ""	
global szFolder = ""
global szInitalDir = ""
global szDirectories = ""
global szFiles = #()
global szNames = #()
global iWindowPos = [0.0, 0.0]
global szCurrentSelected = #()
global szCurrentSelectedID = #()
global iSpeedTreeCount = #()
global hObjectData = ()
global hParticleData = ()
global emptySelect = 0
global cObjectColor = #()
global bListViewChecked = false

global rProject
global rRandomTransform

global szUser = sysInfo.computername

fn useSettings k p w =
(	
	case w of
	(
		0:
		(
			s = getINISetting settingsFile szUser k
			case p of
			(
				"int": return s as integer
				"float": return s as float
				"bool": if s == "true" then true else false
				default: return s
			)
		)
		default: return setINISetting settingsFile szUser k (p as string)
	)
)

fn warningMessage n =
(
	szWarnings = #()
	szWarnings[1] = "Please select \"Export\" folder!"
	szWarnings[2] = "Wrong folder!\n*.max file and *.srt files should belong to same project!"
	szWarnings[3] = "Select project folder first!"
	szWarnings[4] = "Please select one type of tree in list!"
	szWarnings[5] = "Please select objects!"
	szWarnings[6] = "The are no export data!"
	szWarnings[7] = "Do not export data!\nPlease checkout *.stf file first!"
	szWarnings[8] = "Please check in list at least one of type a tree!"
		
	MessageBox szWarnings[n] title: "Warning!"
)

fn fwdSelect =
(
	a = false
	b = false 
	
	z = rRandomTransform.rdoAbsoluteOffset.state
		
	for i in selection where classOf i == Box or classOf i == Editable_Poly do a = true	
	for i in selection where classOf i == PF_Source do 
	(
		b = true
		
		if(selection.count == 1 and z == 1) do
		(
			try
			(
				scaleMin = getUserProp i "scaleMin"
				scaleMax = getUserProp i "scaleMax"	

				rRandomTransform.spnScaleMin.value = scaleMin
				rRandomTransform.spnScaleMax.value = scaleMax					
			)
			catch()
		)
	)
		
	c = for i in selection collect trimRight i.name "&_1234567890"
	c = makeUniqueArray c
	
	try(rProject.findAndHighlightLbxList c)catch()
	rProject.getSelectedLbxList()
		
	
	rRandomTransform.spnObjectScale.enabled = a
	rRandomTransform.spnParticleScale.enabled = b	
	rRandomTransform.btnApplyScale.enabled = (a or b)
	rRandomTransform.btnApplyRandom.enabled = (a or b)
	rRandomTransform.spnScaleMin.enabled = (a or b)
	rRandomTransform.spnScaleMax.enabled = (a or b)	
	rRandomTransform.grp1.enabled = (a or b)
	rRandomTransform.grp2.enabled = (a or b)
	rRandomTransform.rdoAbsoluteOffset.enabled = (a or b)
	rRandomTransform.grp3.enabled  = (a)
	rRandomTransform.btnApplyRotation.enabled  = (a)
	rRandomTransform.spnRotMin.enabled  = (a)
	rRandomTransform.spnRotMax.enabled  = (a)
	rRandomTransform.grp4.enabled  = (a)
	rRandomTransform.btnApplyPosition.enabled  = (a)
	rRandomTransform.spnPosMin.enabled  = (a)
	rRandomTransform.spnPosMax.enabled  = (a)
)

rollout rProject "Speed Tree" width:250 height:555
(
	dotNetControl lbxList "system.windows.forms.listView" pos:[1,128] width:234 height:310
	button btnBrowse "Browse" pos:[7,52] width:220 height:35	
	button btnSelect "Select" pos:[121,442] width:115 height:28
	label lblSpeedTree "SpeedTree types: 0" pos:[5,105] width:179 height:19
	edittext edtBrowse "" pos:[5,19] width:223 height:25 readOnly:true text: "Please select speedtree folder"
	button btnUpdate "Update" pos:[3,442] width:115 height:28
	GroupBox grp1 "Project" pos:[3,1] width:230 height:91			
	button btnLink "Link" pos:[7,508] width:220 height:34
	GroupBox grp2 "Link selected to *.srt" pos:[3,483] width:230 height:68
	Timer tmrUpdateListView "Update ListView" pos:[0,0] width:24 height:24 interval:100 active:true
	
	global Clr = dotNetClass "System.Drawing.Color"	
	
	fn clickContextMenu =
	(				
		s = #()
		
		c = lbxList.SelectedItems.Count - 1
		
		for i = 0 to c do
		(
			id = lbxList.SelectedItems.Item[i].Index + 1
			
			join s hObjectData[id] 
			join s hParticleData[id]				
		)
	
		clearSelection()				
		select s			
	)
		
	fn initLbxList =
	(	
		/*contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"	
		contextMenu.Items.Add "Select in Viewport"
		dotNet.addEventHandler contextMenu #ItemClicked clickContextMenu*/
		
		lbxList.Clear()
		lbxList.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxList.FullRowSelect = true
		lbxList.GridLines = true		
		lbxList.ShowItemToolTips = true
		lbxList.MultiSelect = true
		lbxList.CheckBoxes = true
		lbxList.HideSelection = false
		lbxList.Columns.Add "#" 25
		lbxList.Columns.Add "Name" (lbxList.Width - 90)
		lbxList.Columns.Add "Count" 42	
		lbxList.ContextMenuStrip = contextMenu		
	
		lbxList.Update()
		lbxList.Refresh()
	)
		
	fn deselectAllLbxList s =
	(
		try
		(
			c = lbxList.Items.Count - 1
			for i = c to 0 by - 1 where c > 0 do
			(
				if(s == false) do lbxList.Items.Item[i].Selected =  false
				lbxList.Items.Item[i].BackColor = Clr.White
				lbxList.Items.Item[i].ForeColor = Clr.Black	
			)
		)
		catch()
	)
	
	fn highlightLbxList x =
	(		
		deselectAllLbxList false
		
		for i in x do
		(			 								
			lbxList.Items.Item[i - 1].Selected =  true										
		)		
	)
	
	fn findAndHighlightLbxList x =
	(		
		deselectAllLbxList false
				
		lbxList.BackColor = Clr.White
		lbxList.ForeColor = Clr.Black
		
		for i in x do
		(			 
			z = LbxList.FindItemWithText(i)
			if(z != undefined) do
			(							
				lbxList.Items.Item[z.index].BackColor = Clr.DodgerBlue
				lbxList.Items.Item[z.index].ForeColor = Clr.White								
				lbxList.EnsureVisible(z.index)							
			)			
		)
	)

	fn addToLbxList  r =
	(
		lbxList.Items.Clear()
		rows = #()	
		for x in r do	
		(
			li = dotNetObject "System.Windows.Forms.ListViewItem" ""
			li.subitems.add x[1]	
			li.subitems.add x[2]	
			
			append rows li		
		)
		
		lbxList.Items.addRange rows		
	)
	
	fn getCheckedLbxListID =
	(
		c = lbxList.Items.Count - 1
		z = for i = 0 to c where c > 0 and lbxList.Items.Item[i] != undefined and lbxList.Items.Item[i].Checked == true collect i		
		return z					
	)
	
	fn getCheckedLbxListName =
	(
		z = #()
		c = lbxList.Items.Count - 1
		z = for i = 0 to c where c > 0 and lbxList.Items.Item[i] != undefined and lbxList.Items.Item[i].Checked == true collect lbxList.Items.Item[i].SubItems.Item[1].Text
	
		return z					
	)
	
	fn setAllCheckedLbxList =
	(		
		bListViewChecked = not bListViewChecked 
		
		c = lbxList.Items.Count - 1		
		for i = 0 to c where c > 0 and lbxList.Items.Item[i] != undefined do lbxList.Items.Item[i].Checked = bListViewChecked
	)
	
	fn getSelectedLbxList =
	(
		z = #()
		
		emptySelect = 1	
		szCurrentSelected = #()
		szCurrentSelectedID = #()
		
		try
		(
			ids = #()
			c = lbxList.Items.Count - 1
			for i = 0 to c where c >= 0 and lbxList.Items.Item[i] != undefined and (lbxList.Items.Item[i].Selected ==  true or lbxList.Items.Item[i].BackColor == Clr.DodgerBlue) do
			(
				append ids (i + 1)
				append szCurrentSelected  szNames[i + 1]
				append szCurrentSelectedID (i + 1)
				emptySelect = iSpeedTreeCount[i + 1] * emptySelect
			)			
		)
		catch()
		
		return ids
	)
	
	fn setCheckedLbxList x =
	(
		for i in x do try(lbxList.Items.Item[i].Checked =  true)catch()			
	)
	
	fn setSelectedLbxList x =
	(		
		for i in x do try(lbxList.Items.Item[i].Selected =  true)catch()
	)
	
	fn SelectedDir p =
	(
		try
		(
			p = filterString  p "\\"
			i = p.count - 2

			return p[i]
		)
		catch
		(
			return p[p.count]
		)
	)	

	fn DeleteOldControllers o n = 
	(
		p = #()
		p = for k in o where k != undefined and (classOf k == Box or classOf k == Editable_Poly) and k.children.count != 0 collect k
		
		parentObject = p[1]
		
		if(parentObject != undefined) do
		(
			j = 0
			for i in parentObject.children do 
			(
				i.name = n + "_" + (j += 1) as string						
			)
			
			for i in parentObject.children do deleteItem parentObject.children i
			try(delete parentObject) catch()
		)
	)
	
	fn CreateDummy n =
	(
		o = #()
		o = for i in helpers where i.name == n and classOf i == Point collect i
		
		if(o.count == 0) do
		(
			p = Point pos: [0, 0 ,0] box: true cross: false name: n
			p.wirecolor = random black white
			h = for i in helpers where classOf i == Point collect i
			
			try(p.pos.x =  h[h.count - 1].pos.x + p.size)catch()
		)
	)
	
	fn LinkDummy n z =
	(
		o = #()
		o = for i in helpers where i.name == n and classOf i == Point collect i

		if(o.count != 0 and z.count != 0) do		
		(
			for i in z do
			(
				append o[1].children i
				--i.wirecolor = o[1].wirecolor
			)
		)
	)
	
	fn speedTreeProject n =
	(
		Out = #("", 0)
		try
		(
			p = filterString n "\\"

			for i = p.count to 1 by -1 do
			(
				n = substituteString n (p[i]) ""		
				
				x = (GetDirectories(n + "Export\\*"))
				
				if(x[1] != undefined) do 
				(
					x = getFiles (x[1] + "*.srt")
									
					Out[1] = p[i - 1]
					Out[2] = x.count
					
					exit
				)						
			)
		)catch()
		
		return Out	
	)

	fn compareProject =
	(
		p1 = speedTreeProject maxFilePath
		p2 = speedTreeProject szFolder

		return (p1[1] == p2[1] and p1[2] == p2[2])
	)
		
	
	/* BUILD LIST OF TREES */
	
	fn getList =
	(				
		initLbxList()
		
		x = compareProject()
		
		if(x == false) do 
		(
			warningMessage 2			
			lblSpeedTree.caption = ""
		)
		
		if(szFolder != "" and szFolder != undefined and x == true) do
		(			
			hTotalObjectData = #()
			hUnknownData = #()
			
			szFiles = getFiles(szFolder + "\*.srt")
			
			if(szFiles.count == 0 or szFiles == undefined) then
			(					
				lblSpeedTree.caption = "SpeedTree folder empty!"
			)
			else
			(				
				gChecked = getCheckedLbxListID()
				gSelected = getSelectedLbxList()
						
				iSpeedTreeCount = #()
				hObjectData = (#())
				hParticleData = (#())
				szNames = #()
				iTotal = 0
				
				gList = #()			
					
				for i = 1 to szFiles.count do
				(
					tmpCnt = 0
					tmpOData = #()
					tmpPData = #()
								
					n = (filenameFromPath szFiles[i]) as string
																			
					--o = execute("$'" +  n  + "'*") as array
					o = for ii in geometry where matchPattern ii.name pattern:(n + "*") collect ii
					
					DeleteOldControllers o n
										
					tmpOData = for l in o where classOf l == Box or classOf l == Editable_Poly collect l												
					tmpPData = for l in o where classOf l == PF_Source collect l
															
					if(tmpOData[1] != undefined) do 
					(
						tmpCnt = tmpOData.count
						CreateDummy n
						LinkDummy n tmpOData
					)
						
					if(tmpPData[1] != undefined) do
					(												
						sMin = getUserProp tmpPData[1] "scaleMin"
						sMax = getUserProp tmpPData[1] "scaleMax"
											
						if(sMin == undefined or sMax == undefined) do 
						(
							for v in tmpPData do
							(
								setUserProp v "scaleMin" 0.4
								setUserProp v "scaleMax" 0.6
							)
						)
						
						tmpCnt += tmpPData[1].numParticles()
					)
																
					append szNames n
					append gList #(n, tmpCnt as string)
					append iSpeedTreeCount tmpCnt
					join hTotalObjectData tmpOData
					join hTotalObjectData tmpPData
					append hObjectData tmpOData
					append hParticleData tmpPData
					iTotal += tmpCnt															
				)								
				
				addToLbxList gList

				setCheckedLbxList gChecked 
				setSelectedLbxList gSelected
				
			)
			
			iUsed = for u in iSpeedTreeCount where u != 0 collect u
			
			lblSpeedTree.caption = "Types: " + (szFiles.count as string)  + " | Used: " + ((iUsed.count) as string) + " | Total: " + ((iTotal) as string)
			
			lbxList.Update()
			lbxList.Refresh()
			
			fwdSelect()
			
			callbacks.removescripts id:#fwdSelect
			callbacks.addScript #selectionSetChanged "fwdSelect()" id:#fwdSelect persistent:false	
		)
	)
	
	fn getFilesList =
	(
		i = fileProperties.findProperty #custom "SpeedTree Project"
		if(i != 0) do szFolder = fileProperties.getPropertyValue #custom i
				
		if(szFolder != undefined and szFolder != "") do
		(
				btnBrowse.caption = SelectedDir szFolder				
				useSettings "FOLDER" szFolder 1
				edtBrowse.text = szFolder
								
				getList()
				
				try
				(
					lbxList.Items.Item[0].Selected =  true
					szCurrentSelected[1] = szNames[1]								
				)
				catch()			
		)		
	)		
	
	fn saveWindowPos =
	(
		useSettings "x"  iWindowPos[1] 1
		useSettings "y"  iWindowPos[2] 1		
	)

	fn isSaved =
	(
		x =(maxFilePath == undefined or maxFilePath.count == 0)
		return not x
	)

	on rProject open do
	(		
		initLbxList()
						
		settingsFile = getThisScriptFilename() + ".ini"
				
		/*Open last used project*/
		szInitalDir = useSettings "FOLDER" "string" 0
		
		
		x = (useSettings "x" "float" 0) as float
		y = (useSettings "y" "float" 0) as float
	
		rSpeedTreeTools.pos = [x, y]
		
		getFilesList()				
				
	)
	on rProject close do
	(
		saveWindowPos()
		callbacks.removescripts id:#fwdSelect
	)
	on rProject moved p do
	(
		iWindowPos = p
	)
	on lbxList columnClick x do
	(
		i = x.Column
			
		case i of 
		(
	        0: setAllCheckedLbxList()           
		) 
		
		lbxList.Update()
		lbxList.Refresh()
	)
	on lbxList MouseClick do
	(
		deselectAllLbxList true
	)
	on lbxList MouseDoubleClick a do
	(
		/*z = lbxList.FocusedItem.Checked
		lbxList.FocusedItem.Checked =  not z
			
		h = lbxList.HitTest (dotNetObject "System.Drawing.Point" a.x a.y)
		i = h.item.index + 1
		
		clearSelection()				
		try(select hObjectData[i]) catch()
		try(selectMore hParticleData[i]) catch()	*/	
		
	)
	on lbxList ItemSelectionChanged a do
	(				
		z = getSelectedLbxList()
	)
	on btnBrowse pressed do
	(
		saveWindowPos()
		
		if(isSaved() == false) do
		(
			q = QueryBox "Warning! Scene not saved!\nSave scene?"
			if(q == true)do max file saveas	
		)
		
		if(szFolder != undefined) then szFolder = szFolder else szFolder = ""
	
		szFolder = getSavePath caption:"Browse"	  initialDir: szInitalDir
		
		if(szFolder != undefined and szFolder != "") then
		(
			if(findString szFolder "export" == undefined) then 
			(
				warningMessage 1
			)
			else
			(									
				if(compareProject() == true) then
				(				
					btnBrowse.caption = SelectedDir szFolder
					useSettings "FOLDER" szFolder 1
					edtBrowse.text = szFolder
					try(fileProperties.addProperty #custom "SpeedTree Project" szFolder) catch()
								
					getList()
				
					try(lbxList.Items.Item[0].Selected =  true)catch()
				)
				else
				(
					warningMessage 2
				)
			)
		)			
	)

	on btnUpdate pressed do
	(
		getList()
		lbxList.Focus()
	)
	on btnSelect pressed do 
	(						
		s = #()
			
		c = lbxList.Items.Count - 1
				
		for i = 0 to c do
		(						
			a = lbxList.Items.Item[i].BackColor
			b = lbxList.Items.Item[i].Selected
			
			if(a == Clr.DodgerBlue or b == true) do
			(			
				id = i + 1
				
				a = for z in (execute ("$'" + szNames[id] + "'*")) where superClassOf z == GeometryClass collect z
				
				join s a
			)	
		)
			
		clearSelection()				
		select s

		getList()
	)
	on btnLink pressed do
	(	
		if(selection[1] != undefined) then				
		(		
			if(szCurrentSelected.count != 1) then
			(
				warningMessage 4
			)
			else
			(
				undo on
				(
					j = 1
					n = szCurrentSelected[1]
					
					for i in selection where superClassOf i == GeometryClass do
					(
						i.name = n + "_" + j as string
						j += 1
					)
					
					LinkDummy n selection 
					lbxList.Focus()
				)
			)
		)
		else
		(
			warningMessage 5
		)
				
		getList()
	)
	on tmrUpdateListView tick do
	(
		lbxList.Update()
		lbxList.Refresh()
		
		tmrUpdateListView.active = false
	)
)

fn randomizeScale gScale scaleMax scaleMin =
(
	a = rRandomTransform.rdoAbsoluteOffset.state 
	
	if(a == 1) then
	(		
		s = random scaleMin scaleMax
		--s = floor(100 * s) / 100
		return s
	)
	else
	(		
		r = (gScale / 100) * (random scaleMin scaleMax)
		s = gScale + r
		return s
	)
)


rollout rRandomTransform "Random Transform Selected" width:236 height:534
(
	spinner spnObjectScale "Object Scale:  " pos:[47,25] width:123 height:16 enabled:false range:[-9999,9999,1] scale:0.1 fieldwidth:30
	spinner spnParticleScale "Particle Scale: " pos:[50,49] width:120 height:16 enabled:false range:[-100,100,1] scale:0.1 fieldwidth:30
	spinner spnScaleMin "Min: " pos:[32,155] width:78 height:16 enabled:false range:[-100,100,0.4] scale:0.1 fieldwidth:45
	spinner spnScaleMax "Max: " pos:[160,155] width:45 height:16 enabled:false range:[-100,100,0.6] scale:0.1 fieldwidth:45
	GroupBox grp2 "Randomize Scale" pos:[13,111] width:210 height:105 enabled:false
	GroupBox grp1 "Scale" pos:[3,5] width:230 height:216 enabled:false
	button btnApplyScale "Apply Scale" pos:[33,74] width:170 height:27 enabled:false
	button btnApplyRandom "Apply Random Scale" pos:[33,181] width:170 height:27 enabled:false
	radiobuttons rdoAbsoluteOffset "" pos:[48,130] width:140 height:16 enabled:false labels:#("Absolute", "Offset (%)") default:1 columns:2		
			
	spinner spnRotMin "Min: " pos:[32,256] width:78 height:16 enabled:false range:[-9999,9999,0] scale:1 fieldwidth:45
	spinner spnRotMax "Max: " pos:[160,256] width:45 height:16 enabled:false range:[-9999,9999,360] scale:1 fieldwidth:45
	GroupBox grp3 "Random Rotate" pos:[3,235] width:230 height:83 enabled:false
	button btnApplyRotation "Apply Random Rotation" pos:[32,282] width:170 height:27 enabled:false
	
	spinner spnPosMin "Min: " pos:[32,354] width:78 height:16 enabled:false range:[-999,999,-0.5] type:#worldunits scale:0.1 fieldwidth:45
	spinner spnPosMax "Max: " pos:[158,354] width:45 height:16 enabled:false range:[-999,999,0.5] type:#worldunits scale:0.1 fieldwidth:45
	GroupBox grp4 "Random Position" pos:[3,333] width:230 height:83 enabled:false
	button btnApplyPosition "Apply Random Position" pos:[32,380] width:170 height:27 enabled:false
	
	
	on rRandomTransform rolledUp x do
	(
		rProject.lbxList.Update()
		rProject.lbxList.Refresh()
	)
	on spnScaleMin changed x do
	(
		i = spnScaleMax.value
		a = spnScaleMin.value
		
		if(a > i) do spnScaleMax.value = a
	)
	on spnScaleMax changed x do
	(
		a = spnScaleMax.value
		i = spnScaleMin.value
		
		if(a < i) do spnScaleMin.value = a
	)
	on btnApplyScale pressed do
	(
		objectScale = spnObjectScale.value as float
		particleScale = spnParticleScale.value as float
	
		undo on
		(		
			for i in selection where classOf i == Box or classOf i == Editable_Poly do
			(			
				i.scale.z = objectScale
				i.scale.x = objectScale
				i.scale.y = objectScale
			)	
				
			for i in selection where classOf i == PF_Source do
			(
				setUserProp i "scaleMin" particleScale
				setUserProp i "scaleMax" particleScale
			)
		)
	)
	on btnApplyRandom pressed do
	(	
		scaleMin = spnScaleMin.value as float 
		scaleMax = spnScaleMax.value as float 
		
		p = for i in selection where classOf i == PF_Source collect i
		
		if(p.count > 0 and rdoAbsoluteOffset.state == 2 and not QueryBox("Warning!\nThis operation will be ignored for selected Particles.\nUse Absolute option for Particles!")) do
		(
			return false
		)
		
		undo on
		(
			for i in selection where classOf i == Box or classOf i == Editable_Poly do
			(
				gScale = i.scale.z
				
				objectScale = randomizeScale gScale scaleMax scaleMin 
				
				i.scale.z = objectScale
				i.scale.x = objectScale
				i.scale.y = objectScale
			)	
						
			for i in selection where classOf i == PF_Source and rdoAbsoluteOffset.state == 1 do
			(					
				setUserProp i "scaleMin" scaleMin
				setUserProp i "scaleMax" scaleMax
			)
		)
	)
	on rdoAbsoluteOffset changed x do
	(		
		fwdSelect()
		
		case x of 
		(
			1: 
			(
				spnScaleMin.value = 0.4
				spnScaleMax.value = 0.6
			)
			2:
			(
				spnScaleMin.value = -10
				spnScaleMax.value = 10
			)
		)
	)
	on spnRotMin changed x do
	(
		i = spnRotMax.value
		a = spnRotMin.value
		
		if(a > i) do spnRotMax.value = a
	)
	on spnRotMax changed x do
	(
		a = spnRotMax.value
		i = spnRotMin.value
		
		if(a < i) do spnRotMin.value = a
	)
	on btnApplyRotation pressed do
	(	
		rotMin = spnRotMin.value as float 
		rotMax = spnRotMax.value as float 
			
		undo on
		(
			for i in selection where classOf i == Box or classOf i == Editable_Poly do
			(
				r= random rotMin rotMax
				r = floor(100 * r) / 100
				i.rotation.z_rotation = r
			)									
		)
	)
	on spnPosMin changed x do
	(
		i = spnPosMax.value
		a = spnPosMin.value
		
		if(a > i) do spnPosMax.value = a
	)
	on spnPosMax changed x do
	(
		a = spnPosMax.value
		i = spnPosMin.value
		
		if(a < i) do spnPosMin.value = a
	)
	on btnApplyPosition pressed do
	(	
		posMin = spnPosMin.value as float 
		posMax = spnPosMax.value as float 
			
		undo on
		(
			for i in selection where classOf i == Box or classOf i == Editable_Poly do
			(
				r = random posMin posMax
				i.pos.x = i.pos.x + r
	
				r = random posMin posMax
				i.pos.y = i.pos.y + r
			)									
		)
	)
)


rollout rExport "Export" width:236 height:231
(
	radiobuttons rdoExport "" pos:[15,25] width:120 height:80 labels:#("All", "Geometry", "Particles", "Checked in list", "Selected in Viewport (Only placed)")
	button btnExport "Export" pos:[8,146] width:220 height:38
	label lblStatus "" pos:[7,190] width:210 height:18
	checkbox chkSaveAs "Use SaveAs Dialog" pos:[8,119] width:132 height:22
	GroupBox grp32 "Export Settings" pos:[3,3] width:230 height:105
	
	global szExportData = ""
	
	fn isCheckOutFile f =
	(
		if(f == undefined or f.count <= 1) do return false
		
		if(doesFileExist f == true and (getFileAttribute f #readOnly) == true) do
		(
			lblStatus.caption = "Export canceled..."
			warningMessage 7
			return false
		)
		
		return true
	)
		
	fn exportRun = 
	(		
		szCurrentChecked = rProject.getCheckedLbxListName()
		szCurrentSelectedNames = for l in selection where classOf l == Box or classOf l == Editable_Poly collect l.name	
					
		if(szCurrentChecked.count == 0 and rdoExport.state == 4) do 
		(
			warningMessage 8
			return 0
		)
		
		szOutputFile = szFolder + "\\trees.stf"

		if(chkSaveAs.checked == true) then
		(
			szOutputFile = getSaveFileName caption:"Save to:" filename: szOutputFile types:"stf (*.stf) |*.stf|All|*.*|"	
		)
		
		if(isCheckOutFile szOutputFile == false) do return 0
		
		lblStatus.caption = "Wait while exporting..."
		
		iTotalData = 0
					
		j = 1

		fn searchItem &a z =
		(			
			for m in 1 to a.count where a[m] == z do 
			(	
				deleteItem a m
				return true
			)
			return false
		)
			
		for i in szFiles do
		(
			szData = ""
			
			iCount = 0	
			
			n = (filenameFromPath i) as string
			o = execute("$'" +  n + "'*") as array
			
			ObjectData = for l in o where classOf l == Box or classOf l == Editable_Poly collect l
			ParticleData = for l in o where classOf l == PF_Source collect l

			for k in ObjectData  where ObjectData.count > 0  \
				and ((rdoExport.state == 1 or rdoExport.state == 2)  \
				or (rdoExport.state == 4 and (findItem szCurrentChecked n) !=0 ) \
				or (rdoExport.state == 5 and (searchItem szCurrentSelectedNames k.name) == true)) do
			(		
				iTotalData += 1
				iCount += 1
				
				gScale = floor(100 * k.scale.z) / 100
				r = k.rotation.z_rotation
				
				s = "	" + k.pos.x as string + " " + k.pos.y as string + " " + k.pos.z as string + " " + r as string + " " + gScale as string + "\n"
				append szData s
			)							
				
			for k in ParticleData where ParticleData.count > 0 \
				and ((rdoExport.state == 1 or rdoExport.state == 3) \
				or (rdoExport.state == 4 and (findItem szCurrentChecked n) !=0)) do
			(			
				iParticlesNum = k.numParticles()
						
				scaleMin = getUserProp k "scaleMin"
				scaleMax = getUserProp k "scaleMax"
							
				if(scaleMin == undefined or scaleMax ==undefined) do 
				(				
					scaleMin = 0.4
					scaleMax = 0.6										
				)
			
				for p = 1 to iParticlesNum do
				(
					iTotalData += 1
					iCount += 1
										
					k.particleIndex = p
					q = k.particlePosition
									
					randomScale = random scaleMin scaleMax
					
					s =  "	" + q.x as string + " " + q.y as string + " " + q.z as string + " " + (random 0.0 360.0) as string + " " + randomScale as string + "\n"
					append szData s
				)					
			)

			if(iCount != 0) do
			(
				s = n + "\n"
				append szExportData s
				s = "	" + iCount as string + "\n"
				append szExportData s
				append szExportData szData
				s = "\n" + "\n"
				append szExportData s							
			)
			
			j += 1
			iCount = 0
		)
		
		if(iTotalData == 0) then
		(
			warningMessage 6
			lblStatus.caption = "The are no export data!"
		)		
		else
		(			
			bQuery1 = true
			
			if(emptySelect == 0 and rdoExport.state == 4) do bQuery1 = queryBox("Warning!\nSome types of trees don't have export data.\nContinue export?")
						
			if(bQuery1) then
			(											
				if(szOutputFile != undefined and szOutputFile.count > 1) then
				(
					fFile = openFile szOutputFile mode:"w+"
					format "%" szExportData to:fFile
					close fFile	
				
					lblStatus.caption = "Export done (" + iTotalData as string + " points.)"
				)
				else
				(
					lblStatus.caption = "Export cancel!"
				)
			)
			else
			(
				lblStatus.caption = "Export cencel!"
			)
					
			szExportData = ""							
		)
	)
	
	on rExport open do
	(				
		s = useSettings "EXPORTTYPE" "int" 0
		if(s == undefined or s == 0) do s = 1
		rdoExport.state = s
		
		s = useSettings "SAVEASDIALOG" "bool" 0
		chkSaveAs.checked = s			
	)
	on rdoExport changed x do
	(
		useSettings "EXPORTTYPE" x 1
	)
	on rExport rolledUp x do
	(
		rProject.lbxList.Update()
		rProject.lbxList.Refresh()
	)
	on btnExport pressed do
	(
		if(szFolder != "" and szFolder != undefined and findString szFolder "Export" != undefined) then
		(						
			exportRun()			
		)
		else
		(
			warningMessage 1
		)			
	)
	on chkSaveAs changed x do
	(
		useSettings "SAVEASDIALOG" x 1
	)
)

rollout rAbout "About" 
(	
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	button btnHelp "Help" enabled: false
	
	fn getHelp run: false =
	(
		s = getThisScriptFilename()
		i = getScriptInfo s
		szHelp = (getFilenamePath s) + i[7]
		if(i[7] != "" and doesFileExist szHelp) do btnHelp.enabled = true
			
		if(run) do ShellLaunch szHelp ""
	)
	
	on btnHelp pressed do getHelp run: true
				
	on rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
		
		getHelp()
	)
	
	on rAbout rolledUp x do
	(
		rProject.lbxList.Update()
		rProject.lbxList.Refresh()
	)
)

addRollout rProject rSpeedTreeTools rolledUp:false
addRollout rRandomTransform rSpeedTreeTools rolledUp:true
addRollout rExport rSpeedTreeTools rolledUp:false
addRollout rAbout rSpeedTreeTools rolledUp:true