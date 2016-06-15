/*
[INFO]

NAME = Scripts Launcher
VERSION = 1.4.0
AUTHOR = MastaMan
DEV = ViscoCG
HELP = \help\scriptsLauncher.html

[INSTALL]
MACRO=Scripts_Launcher
CAT=ViscoCG
TEXT=SL
ICON=#("UVWUnwrapView",19)

[ICONS]

[1.0.0]

* First release =

[1.0.1]

+ Add buttons All and Favorite =
+ Add icon = 

[1.0.2]

+ Add update feature = 

[1.1.0]

* Changed window width =
+ Add dock feature (Configure in Settings) =

[1.2.0]

* Small improvements =
* Quick search by first word =
+ Add notify features (Configure in Settings) =
+ Add feature get info about any script =
(Context menu) =
+ Add Info button in About rollout =
+ Add Help button in About rollout =

[1.2.1]

- BugFix: Small fix for 3Ds Max 2012=

[1.2.3]

* Added Installs rollout for quick install plugins=
- BugFix: New versions notify=

[1.2.4]
* Adopted for ArchViz=

[1.2.5]

+ Added: Added Test section=

[1.3.0]

+ Added: Categories=
+ Added: Filter by category=
- Removed: Buttons All and Favorite=

[1.3.1]

+ Added: Category Custom for add custom scripts=

[1.3.2]

* Improved INSTALL.mcr=
+ Added: Installation scripts to interface

[1.3.3]

- BugFix: Notify updated scripts

[1.4.0]

+ Added: Create button for every script by Right Click Menu=
- Removed: Installs -> Install Script featature=

[ABOUT]

- Run any ViscoCG script=
- Search =
- Favorite =
- Categories =
- Updates =
- Notification =
- Info about scripts =
- More features coming soon... =

[TEST]
Text here=
@=
_=

[SCRIPT]

*/


global szScriptsDir = getFilenamePath (getThisScriptFilename()) + @"scripts\"
global szScriptsName = filenameFromPath (getThisScriptFilename())
global szInstallsDir = szScriptsDir + @"installs\"
global runCopyAsstes = szInstallsDir + "copy_assets.lnk"
global szTestDir = szScriptsDir + @"test\"
global szIconFilter24i = szScriptsDir + @"\icons\MENU\filter_24i.bmp"
global szIconFilter24a = szScriptsDir + @"\icons\MENU\filter_24a.bmp"
	
global iniSettingsFile = szScriptsDir + @"ini\" + (sysInfo.username) + "_" + szScriptsName + ".ini"
global filterPrefix = "_"
global szCurrentCategory = "All"
	
global szExt = ".ms"
global szExt2 = ".mzp"
global szExt3 = ".mcr"


----------------------------------------------------------------------------------------------------
try(cui.UnRegisterDialogBar rScriptsLoader) catch()
try(closeRolloutFloater rScriptsLoader)catch()
global szScriptsPath = #()
global szInstallsPath = #()
global szCategoriesPath = #()
global szTestPath = #()
global szTempScriptspath = #()
global iWinPos = [0.0, 0.0]

global goodChars = #("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z")

global rLauncher
global rInstalls
global rTest
global rSettings
global rAbout
global rScriptsLoader = newRolloutFloater "Menu" 235 575

----------------------------------------------------------------------------------------------------

fn getScriptIniInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	fn isVer i = (filterString i ".").count > 1
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	t = getINISetting s "TEST"
	b = getINISetting s "INSTALL"
	 			
	r = for i in (getINISetting s) where isVer i  collect i
	
	return #(n, a, v, o, r, c, h, t, b)
)

fn writeFile f s =
(			
	f = createFile f mode: "wt"

	format(s as string) to:f

	flush f
	close f
)

fn parseIniLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""	

	try
	(
		for i in m do 
		(	
			if(i[1] == "_") do 
			(
				l += "_______________________________________\r\n\r\n" 
				continue
			)
			if(i[1] == "@") do 
			(
				l += "\r\n"
				continue
			)
			
			l += i + "\r\n"
		)
	) catch()
	return l
)

fn initTextBox textBox =
(
	b = (colorMan.getColor #background) * 255
	t = (colorMan.getColor #text) * 255
	
	textBox.Font = dotNetObject "System.Drawing.Font" "MS Sans Serif" 8 ((dotNetClass "System.Drawing.FontStyle").Regular)
	textBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
	textBox.BackColor = (dotNetClass "System.Drawing.Color").fromARGB (b[1] as integer) (b[2] as integer) (b[3] as integer)
	textBox.ForeColor = (dotNetClass "System.Drawing.Color").fromARGB (t[1] as integer) (t[2] as integer) (t[3] as integer)
	textBox.MultiLine = true
	textBox.WordWrap = true
	textBox.ScrollBars = (dotNetClass "System.Windows.Forms.ScrollBars").Vertical
	textBox.ReadOnly = true
)	


fn displayInfo szScriptPath tb: false cat:"" =
(
	try(DestroyDialog rNotify)catch()
	
	global scriptInfo = getScriptIniInfo szScriptPath

	if(scriptInfo[1] == "" and scriptInfo[2] == "") do
	(
		try(DestroyDialog rNotify)catch()
		
		if(tb) do return messageBox "Script installed and added to interface!" title: "Success!" beep: false
		return messageBox "No info about this script!" title: "Sorry!"
	)
		
	global script = szScriptPath
	global toolbar = tb
	global category = cat
	global szScriptHelpFile = ""
	
	rollout rNotify "Info" 
	(
		label lblReleases "Release:" across: 3 align: #left offset: [-5, 0]
		dropdownlist ddlReleases "" align: #left offset: [-25, -2]
		button btnScriptHelp "?" align: #right tooltip: "Help is not available for this script" enabled: false offset: [8, 0]
				
		dotNetControl edtStat "System.Windows.Forms.Textbox" width:260 height:260 align:#center 
				
		button btnCopy "Copy" align: #left width: 50 across: 2
		button btnOK "Ok" align: #right  width: 35
	
		fn buildInfo =
		(				
			i = scriptInfo			
			
			szStat = ""
			
			sep = "\r\n\r\n_______________________________________\r\n\r\n"
			
			p = getFilenamePath(getThisScriptFilename()) + i[7]
			isHelp = i[7] != "" and doesFileExist p
			
			if(toolbar) do 
			(
				szStat += "Script installed success and added to interface!"
				szStat += sep
				szStat += "If interface button not deployed:\r\n"
				szStat += "\r\n1. Go to \"Customize\""
				szStat += "\r\n2. Choose \"Customize User Interface\""
				szStat += "\r\n3. Choose tab \"Toolbars\""
				szStat += "\r\n4. Select category \"[" + category + "]\" in the end of list"
				szStat += "\r\n5. Drag&Drop \"" + i[1]  + "\" to your tool bar"
				szStat += sep
				
				if(isHelp) do
				(
					szStat += "Important:\r\n\r\n"
					szStat += "Please read help for " + i[1] + " in About section!"
					szStat += sep
				)
			)
			
			szStat += "Name:\t" + i[1] + "\r\n"
			szStat += "Author:\t" + i[2] + "\r\n"
			szStat += "Version:\t" + i[3] + "\r\n"
			if(i[6] != "") do szStat += "Dev.:\t" + i[6]
			if(i[4].count > 0) do
			(
				szStat += sep
				
				szStat += "About:\r\n\r\n" 
				
				szStat += parseIniLine i[4]
			)
			
			
			p = getFilenamePath(getThisScriptFilename()) + i[7]
			if(isHelp) do
			(
				btnScriptHelp.enabled = true
				btnScriptHelp.tooltip = "Help is available for this script"
				szScriptHelpFile = p
			)
			
			edtStat.text = szStat
		)
		
		fn buildRelease v =
		(										
			szStat = ""
						
			szStat += "Release Notes " + v + ":\r\n\r\n" 
			
			r = getScriptIniInfo script releaseInfo:v
			
			if(r.count == 0) do return ""
			
			szStat += parseIniLine r
			
			edtStat.text = szStat
		)
		
		on ddlReleases selected x do 
		(
			case x of
			(
				1: buildInfo()
				default: buildRelease (ddlReleases.selected)
			)
		)
		on btnScriptHelp pressed do if(doesFileExist szScriptHelpFile) do shellLaunch szScriptHelpFile ""
	
		on btnOK pressed do try(DestroyDialog rNotify)catch()
		on rNotify open do
		(
			initTextBox edtStat
			
			i = scriptInfo
		
			edtStat.text = buildInfo() 

			ddlReleases.items = i[5]
			rNotify.title = i[1]						
		)
		on btnCopy pressed do setClipBoardText edtStat.text			
	)

	createDialog rNotify 260 320 --modal:true
)

rollout rLauncher "Scripts" 
(
	dotNetControl lblTitle "System.Windows.Forms.Label" width: 148 height: 24 align: #left offset: [24, 0] across: 2	
	button btnFilter width: 24 height: 24  align: #left border: false offset: [-100, 0]

	dotNetControl edtFindScript "system.windows.forms.textBox" width: 165 height:26 across: 2 align:#left
	dotNetControl btnFindClear "system.windows.forms.button" width:24 height:24  align: #right offset: [0, -2]
	dotNetControl lbxScriptList "system.windows.forms.listView" height:330				
	button btnRunScript "Run Script" width:200 height:34 offset: [-2, 0]	
	timer tmrFocus "" interval: 200 active: true

	
	global kKeys =  DotNetClass "System.Windows.Forms.Keys" 
	global Clr = dotNetClass "System.Drawing.Color"		
----------------------------------------------------------------------------------------------------	

	fn Settings z k p w =
	(	
		makeDir (getFilenamePath iniSettingsFile)
		
		case w of
		(
			"r":
			(
				s = getINISetting iniSettingsFile z k
				case p of
				(
					"int": return s as integer
					"float": return s as float
					"bool": if s == "true" then true else false
					default: return s
				)
			)
			"a":
			(
				return getINISetting iniSettingsFile z
			)
			"d":
			(
				delIniSetting iniSettingsFile z k
			)
			default: return setINISetting iniSettingsFile z k (p as string)
		)
	)
	
	fn saveWinPos =
	(
		Settings "POS" "x"  iWinPos[1] "w"
		Settings "POS" "y"  iWinPos[2] "w"		
	)
	
	fn getSelectedId =
	(
		c = lbxScriptList.SelectedItems.Count - 1
		
		id = 0
		
		for i = 0 to c do 
		(		
			id = lbxScriptList.SelectedItems.Item[i].Index + 1			
		)
	
		return id
	)
	
	fn addToFavorite =
	(
		id = getSelectedId()
		
		if(id != 0) do Settings "FAVORITE" szTempScriptspath[id] "true" "w"
	)
	
	fn getCategory c =
	(
		p = filterString c "\\"
		
		return trimLeft p[p.count] filterPrefix
	)	
	
	fn initDotNet =
	(	
		bg = (colorMan.getColor #background) * 255
		
		btnFilter.images = #(szIconFilter24i, szIconFilter24a , 1,1,1,1,1)
		
		lblTitle.TextAlign =  (getProperty lblTitle.TextAlign "MiddleCenter") 
		lblTitle.BackColor = lblTitle.backcolor.fromARGB bg[1] bg[2] bg[3]
		lblTitle.ForeColor = lblTitle.forecolor.fromARGB 255 255 255
		
		FontStyle = dotnetclass "System.Drawing.FontStyle"
		
		lblTitle.Font = dotnetobject "System.Drawing.Font" "Arial" 9 FontStyle.Bold
		
		
		lbxScriptList.Clear()
		lbxScriptList.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxScriptList.FullRowSelect = true
		lbxScriptList.GridLines = true		
		lbxScriptList.ShowItemToolTips = true
		lbxScriptList.MultiSelect = false
		lbxScriptList.CheckBoxes = false
		lbxScriptList.HideSelection = false
		lbxScriptList.Columns.Add "Name" 175
			
		lbxScriptList.Update()
		lbxScriptList.Refresh()
			
		btnFindClear.text = "X"		
	)
		
	fn deselectAll =
	(
		try
		(
			c = lbxScriptList.Items.Count - 1
			for i = c to 0 by - 1 where c > 0 do
			(
				lbxScriptList.Items.Item[i].BackColor = Clr.White
				lbxScriptList.Items.Item[i].ForeColor = Clr.Black	
			)
		)
		catch()
	)
	
	fn addToLbxList r =
	(				
		lbxScriptList.Items.Clear()
		rows = #()	
		i = 1
		for x in r do	
		(
			li = dotNetObject "System.Windows.Forms.ListViewItem" ""
			li.text = (i as string + ". " + getFilenameFile x) + (if(not doesFileExist x) then " (Not Found)" else "")
		
			append rows li		
			i += 1
		)
		
		lbxScriptList.Items.addRange rows
	)	
	
	fn findCategory c = 
	(
		f = undefined
		for i in szCategoriesPath where c == getCategory i do
		(
			f = i
			exit
		)
		
		return f
	)	
	
	
	fn buildScriptList c =
	(											
		szScriptsPath = #()
		for i in szCategoriesPath where c == getCategory i or c == "All" do
		(
			join szScriptsPath (getFiles(i + "*" + szExt))
		)
		
		join szScriptsPath (getFiles(szScriptsDir + "*" + szExt))
				
		szScriptsPath = for i in szScriptsPath where getFilenameFile i != "menu.ms" collect i
		
		szTempScriptspath = szScriptsPath
		
		addToLbxList szScriptsPath
	)
	
	fn buildCustomList =
	(
		szScriptsPath = (Settings "CUSTOM" "" "" "a")
					
		szTempScriptspath = szScriptsPath
		
		addToLbxList(szScriptsPath)	
	)
	
	fn removeFromCustom =
	(
		id = getSelectedId()
		
		if(id != 0) do 
		(
			Settings "CUSTOM" szTempScriptspath[id] "false" "d"
			Settings "FAVORITE" szTempScriptspath[id] "false" "d"
		)
		
		
		buildCustomList()
	)
	
	fn addToCustom =
	(	
		f = getOpenFileName caption:"Choose Custom Script" types: "*.ms (MaxScript)|*.ms"
				
		if(f == undefined) do return false
			
		Settings "CUSTOM" f "true" "w"
		
		buildCustomList()
	)
	
	fn buildFavoriteList =
	(
		szScriptsPath = (Settings "FAVORITE" "" "" "a")
		szTempScriptspath = szScriptsPath
		
		addToLbxList(szScriptsPath)
	)
	
	fn removeFromFavorite =
	(
		id = getSelectedId()
		
		if(id != 0) do Settings "FAVORITE" szTempScriptspath[id] "false" "d"
			
		
		buildFavoriteList()
	)
	
	fn showScriptInfo =
	(
		id = getSelectedId()
		
		if(id != 0) do displayInfo szTempScriptspath[id]				
	)
	
	fn showScriptHelp =
	(
		id = getSelectedId()
		
		if(id != 0) do
		(
			i = getScriptIniInfo szTempScriptspath[id]
			
			szHelp = (getFilenamePath (szTempScriptspath[id])) + i[7]
			
			if(i[7] == "" or doesFileExist szHelp == false) do return  messageBox "No help for this script!" title: "Sorry."
			
			ShellLaunch szHelp ""			
		)
	)
	
	-----
	
	fn copyAssets a d altPath: ""=
	(		
		
		f = @"c:\temp\"
		makeDir f
		
		f += "install.bat"
		
		if(doesFileExist f) do deleteFile f
		
		s = ""
		
		for i in a do
		(
			s += "xcopy \"" + i + "\" \"" + d  + "\" /Y \n"
			if(altPath != "") do s += "xcopy \"" + i + "\" \"" + altPath  + "\" /Y \n"
		)
				
		writeFile f s
		
		-- IMPORTANT link must exist!
		HiddenDOSCommand runCopyAsstes 		
	)

	fn addToolBarButton macro cat txt =
	(
		f = cui.getConfigFile() 
		cui.loadConfig f
		cui.saveConfigAs f
		
		l = "<Item typeID=\"2\" type=\"CTB_MACROBUTTON\" width=\"0\" height=\"0\" controlID=\"0\" macroTypeID=\"3\" macroType=\"MB_TYPE_ACTION\" actionTableID=\"647394\" imageID=\"-1\" imageName=\"\" actionID=\"" + macro + "`[" + cat + "]\" tip=\"" + txt + "\" label=\"" + txt + "\" />"
		
		file = MemStreamMgr.openFile f
		size = file.size()
		MemStreamMgr.close file

		stream = openFile f mode:"r+"
		
		if((skipToString stream l) == undefined) do
		(
			seek stream 0 
			
			c = "</Items>"
			
			skipToString stream c
				
			pos = filePos stream - c.count
			
			seek stream pos
			
			previousContent = readChars stream (size - pos)
			
			seek stream pos
			
			format ("\n\t\t" + l + "\n") to:stream
			format previousContent to:stream
		)
		
		close stream
		
		cui.loadConfig f
		cui.saveConfigAs f
		cui.setConfigFile f
	)

	fn addQuadMenuButton macro cat txt =
	(
		quadMenu = menuMan.getViewportRightClickMenu #nonePressed
		theMenu = quadMenu.getMenu 1

		fn findMenuItem theMenu menuName =
		(
			for i in 1 to theMenu.numItems() where (theMenu.getItem i).getTitle() == menuName do return i
			return 0
		)

		fn unregisterMenuItem theMenu menuName =
		(	
			try
			(
				for i in 1 to theMenu.numItems() do
				(
					if((theMenu.getItem i).getTitle() == menuName) do
					(
						theMenu.removeItemByPosition i 	

						if((theMenu.getItem (i - 1)).getIsSeparator()) do theMenu.removeItemByPosition (i - 1)
					)
				)
			)catch()
		)

		item = try(findMenuItem theMenu "Select &Similar")catch(6)

		unregisterMenuItem theMenu txt
		
		quadItem = menuMan.createActionItem macro ("[" + cat + "]")
			
		theMenu.addItem quadItem (item += 1)
			
		menuMan.updateMenuBar()
	)
	
	fn installButton type: 1=
	(
		id = getSelectedId()
			
		if(id != 0) do
		(			
			launch = szTempScriptspath[id]			
			macro = getIniSetting szTempScriptspath[id]  "INSTALL" "MACRO"
			cat = getIniSetting szTempScriptspath[id]  "INSTALL" "CAT"			
			txt = getIniSetting szTempScriptspath[id]  "INSTALL" "TEXT"
			ico = getIniSetting szTempScriptspath[id]  "INSTALL" "ICON"			
			icons = getIniSetting szTempScriptspath[id]  "ICONS"
			
			if(launch == "" or cat == "" or macro =="" or txt == "") do return messageBox "Bad macroscript installaiton file!\nPlease notify developer team about this problem." title: "Error!"
			
			if(icons.count > 0) do
			(
				destPath = (GetDir #ui) + @"icons\"
				altPath = (GetDir #userIcons) 
				copyAssets icons destPath altPath: altPath				
			)
			
			p = getDir (#downloads) + @"\"
								
			p += "install_" + timeStamp() as string + ".mcr"
			
			s = "macroScript " + macro + "\n"
			s += "category:\"[" + cat + "]\" \n"
			s += "toolTip:\"" + txt + "\" \n"
			s += "buttontext:\"" + txt + "\" \n"
			if(ico != "") do s += "Icon:" + ico + "\n"
			s += "(\n"
			s += "try(fileIn(@\"" + launch + "\"))catch(messageBox \"Lost network connection!\" title: \"Warning!\")	\n"
			s += ")\n"
			
			writeFile p s
			
			try(fileIn p) catch(messageBox "1111Bad macroscript installaiton file!\nPlease notify developer team about this problem." title: "Error!")
						
			displayInfo launch tb:true cat: cat			
			
			
			case type of
			(
				2: addQuadMenuButton macro cat txt												
				default: addToolBarButton macro cat txt
			)	

			colorman.reInitIcons()			
		)
		
		rLauncher.lbxScriptList.Update()
		rLauncher.lbxScriptList.Refresh()
	)
	
	fn installButtonType1 = installButton type: 1
	
	fn installButtonType2 = installButton type: 2

	
	---
	
	fn contextMenuItem m n enabled: true =
	(
		item = undefined	
		c = m.Items.Count - 1
		for i = c to 0 by - 1 where c > 0 do
		(
			ii = m.Items.Item[i].Text
			if(ii == n) do
			(
				item = m.Items.Item[i]
				item.Enabled = enabled
				exit
			)
		)
		
		return item
	)
	
	fn bindContextMenu =
	(
		id = getSelectedId()
		
		contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"	
		
		if(szCurrentCategory == "Custom") do
		(			
			dotNet.addEventHandler (contextMenu.Items.Add("Add to Custom")) "Click" addToCustom
			dotNet.addEventHandler (contextMenu.Items.Add("Remove from Custom")) "Click" removeFromCustom
			contextMenu.Items.Add("-")
		)			
		
		if(szCurrentCategory != "Favorite") then
		(
			dotNet.addEventHandler (contextMenu.Items.Add("Add to Favorite")) "Click" addToFavorite
		)
		else
		(
			dotNet.addEventHandler (contextMenu.Items.Add("Remove from Favorite")) "Click" removeFromFavorite
		)
			
		contextMenu.Items.Add("-")
		dotNet.addEventHandler (contextMenu.Items.Add("Info about script")) "Click" showScriptInfo
		dotNet.addEventHandler (contextMenu.Items.Add("Help for script")) "Click" showScriptHelp
					
			
		/* Enable/ Disable StripMenu items*/
		
		s = getThisScriptFilename()
			
		i = #()	
		if(id > 0) do i = getScriptIniInfo szTempScriptspath[id]
			
		if(id == 0) do 
		(
			contextMenuItem contextMenu "Add to Favorite" enabled: false	
			contextMenuItem contextMenu "Remove from Favorite" enabled: false	
			
			contextMenuItem contextMenu "Remove from Custom" enabled: false	
		)
		
		if(id == 0 or (i[1] == "" and i[2] == "")) do contextMenuItem contextMenu "Info about script" enabled: false	
		
		if(id == 0 or i[7] == undefined or i[7] == "" or (doesFileExist ((getFilenamePath szTempScriptspath[id]) + i[7])) == false) do contextMenuItem contextMenu "Help for script" enabled: false
		
		if(id > 0 and i[9].count > 0) do
		(
			contextMenu.Items.Add("-")
			subMenu = contextMenu.Items.Add("Add button")
			dotNet.addEventHandler (subMenu.DropDownItems.Add("Main Toolbar")) "Click" installButtonType1
			dotNet.addEventHandler (subMenu.DropDownItems.Add("Quad Menu")) "Click" installButtonType2
		)
			
		lbxScriptList.ContextMenuStrip = contextMenu	
	)
	
	fn runScript p =
	(
		try
		(
			if(p == 1) do lbxScriptList.Items.Item[0].Selected = true
			
			c = lbxScriptList.SelectedItems.Count - 1
			
			for i = 0 to c do
			(
				x = lbxScriptList.SelectedItems.Item[i].Index + 1
				
				if(szTempScriptspath[x] != undefined and doesFileExist szTempScriptspath[x]) then 
				(
					try
					(
						fileIn szTempScriptspath[x] quiet: true
						clearListener()	
						print ("Scripts Launcher run: " + getFilenameFile szTempScriptspath[x])
					)
					catch()
				)
				
				exit				
			)
		)
		catch()
	)
	
	fn fnSetDock d s = 
	(
		Settings "DOCK" "DOCKABLE"  d "w"
		Settings "DOCK" "DOCKSIDE"  s "w"
		
		if(d) then
		(
			cui.RegisterDialogBar  rScriptsLoader style:#(#cui_floatable, #cui_dock_vert, #cui_handles, #cui_max_sized, #style_toolwindow, #style_sysmenu)
		
			case s of
			(
				1:  cui.DockDialogBar rScriptsLoader #cui_dock_left
				2:  cui.DockDialogBar rScriptsLoader #cui_dock_right
			)			
		)
		else	
		(
			if(rScriptsLoader.dialogBar) do
			(
				cui.UnRegisterDialogBar rScriptsLoader	
			)
			
			if (not rScriptsLoader.dialogBar) do
			(
				x = (Settings "POS" "x" "float" "r") 
				y = (Settings "POS" "y" "float" "r") 

				rScriptsLoader.pos = [x, y]
			)								
		)			
	)
	
	fn changeCategory c =
	(
		bindContextMenu()
		
		szCurrentCategory = c
		
		lblTitle.text = szCurrentCategory
		
		Settings "MAIN" "SHOW" c "w"
		
		case c of
		(
			"Custom": buildCustomList()
			"Favorite": buildFavoriteList()			
			default: buildScriptList c
		)	
		
		edtFindScript.Focus()
		edtFindScript.text = ""
	)
	
	global rcCatChecked = undefined
	

	fn rcCheckItem c = (szCurrentCategory == c) as string	
	
	fn showCategoriesMenu =
	(			
		rcPoupPos = btnFilter.pos
		rcPoupPos.y += 24
		
		ex = "rcmenu rcCategories \n(\n"		
		ex += "menuItem rcAll \"All\" checked:" + rcCheckItem "All" + " \n"
		ex += "on rcAll picked do rLauncher.changeCategory \"All\"\n"
		ex += "menuItem rcFavorite \"Favorite\" checked:" + rcCheckItem "Favorite" + " \n"
		ex += "on rcFavorite picked do rLauncher.changeCategory \"Favorite\"\n"
		ex += "separator sep1\n"	
		
		for i in 1 to szCategoriesPath.count do
		(	
			n = "rcCat" + i as string 			
			c = getCategory szCategoriesPath[i]
					
			ex += "menuItem " + n +  " \"" + c+ "\" checked: " + rcCheckItem c + "\n" 
			ex += "on " + n + " picked do (\n rLauncher.changeCategory \"" + c + "\"  \n) \n"	
		)
		ex += "separator sep2\n"
		ex += "menuItem rcCustom \"Custom\" checked:" + rcCheckItem "Custom" + " \n"
		ex += "on rcCustom picked do rLauncher.changeCategory \"Custom\"\n"		
		ex += "\n )\n popUpMenu rcCategories rollout: rLauncher pos:" + rcPoupPos as string + "\n"
		
		execute ex	
	)

----------------------------------------------------------------------------------------------------	
	
	on rLauncher open do
	(								
		d = Settings "DOCK" "DOCKABLE"  "bool" "r"
		s = Settings "DOCK" "DOCKSIDE"  "int" "r"		
		
		fnSetDock d s
		
		initDotNet()
		
		c = Settings "MAIN" "SHOW" "" "r"
		
		if(c != "") do szCurrentCategory = c
				
		bindContextMenu()
		
		x = (Settings "POS" "x" "float" "r") 
		y = (Settings "POS" "y" "float" "r") 
	
		try(rScriptsLoader.pos = [x, y]) catch()
		
		szCategoriesPath = getDirectories (szScriptsDir + filterPrefix + "*")
						
		changeCategory szCurrentCategory	
	)
	on rLauncher close do
	(
		saveWinPos()
		try(DestroyDialog rNotify)catch()		
	)
	on rLauncher moved p do
	(
		iWinPos = p
	)
	on edtFindScript TextChanged x do
	(
		w = edtFindScript.text 
		
		if(w == "Search...") do return false

		o = #()
		
		if(w.count > 0) then
		(
			for i in szScriptsPath do
			(
				t = getFilenameFile i
						
				j = w + "*"
										
				if(matchPattern t pattern: j) do
				(					
					append o i
				)
			)
			
			for i in szScriptsPath do
			(
				t = getFilenameFile i
						
				j = "*" + w + "*"
										
				if(matchPattern t pattern: j and findItem o i == 0) do
				(					
					append o i
				)
			)
						
			addToLbxList o			
			szTempScriptspath = o
			
			try
			(
				lbxScriptList.Items.Item[0].Focused =  true
				lbxScriptList.Items.Item[0].BackColor = Clr.DodgerBlue
				lbxScriptList.Items.Item[0].ForeColor = Clr.White	
			)
			catch()
		)
		else
		(
			addToLbxList szScriptsPath
			szTempScriptspath = szScriptsPath
		)		
	)
	
	on edtFindScript GotFocus do
	(
		t = edtFindScript.text
		if(t == "Search...") do edtFindScript.text = ""
	)
		
	on edtFindScript LostFocus do
	(
		t = edtFindScript.text
		if(t == "") do edtFindScript.text = "Search..."
	)
	
	on edtFindScript keyUp k do
	(	 		
		if(k.KeyCode == kKeys.Escape) do edtFindScript.text = ""
		if(k.KeyCode == kKeys.Enter) do runScript 1
		edtFindScript.Focus()
		
		if(k.KeyCode == kKeys.Down) do lbxScriptList.Focus()				
	)
	on lbxScriptList DoubleClick a do
	(
		runScript 0
	)
	on lbxScriptList keyUp k do
	(
		if(k.KeyCode == kKeys.Escape or k.KeyCode == kKeys.Tab) do 
		(
			edtFindScript.text = ""
			edtFindScript.Focus()
			return false
		)
		if(k.KeyCode == kKeys.Enter) do 
		(
			runScript 0
			return false
		)
		if(k.KeyCode == kKeys.Up) do 
		(
			if(lbxScriptList.Items.Item[0].Selected == true) do edtFindScript.Focus()
			return false
		)
				
		goodChar = false		
		char = k.KeyCode.ToString()		
		for i in goodChars where i == char do goodChar = true
			
		if(not goodChar) do return false
	
		
		edtFindScript.Focus()
		edtFindScript.text = k.KeyCode.ToString()
		edtFindScript.SelectionStart = 2
	)
	on lbxScriptList MouseUp do
	(		
		deselectAll()
		bindContextMenu()
	)
	

	
	on btnRunScript pressed do
	(
		lbxScriptList.Focus()
		runScript 0
	)
	on btnFindClear mouseDown do
	(
		edtFindScript.text = ""
		edtFindScript.Focus()
	)

	
	on btnFilter pressed do
	(
		showCategoriesMenu()
	)
	on tmrFocus tick do
	(
		edtFindScript.Focus()
		tmrFocus.active = false
	)
	
	on rLauncher rolledUp x do
	(
		rLauncher.lbxScriptList.Update()
		rLauncher.lbxScriptList.Refresh()
	)
)

rollout rUpdate "Update"
(	
	button btnUpdate "Update Scripts" enabled: true
	
	on btnUpdate pressed do
	(				
		s = getFilenamePath (getThisScriptFilename())
				
		fileIn(getThisScriptFilename())		
	)	
	
	on rUpdate rolledUp x do
	(
		rLauncher.lbxScriptList.Update()
		rLauncher.lbxScriptList.Refresh()
	)
)

fn notifyScripts =
(
		upd = rSettings.cbxScriptsUpdated.checked
		new = rSettings.cbxScriptsAdded.checked
	
	if(new == false and upd == false) do return false
	
	f  =#()
	for i in szCategoriesPath do
	(
		join f (getFiles(i + "*" + szExt))
	)
		 
	szUpdated = ""
	szNew = ""
	m = ""
			
	for i in f do
	(		
		n = getFilenameFile  i 

		v = getScriptIniInfo i
						
		z = rLauncher.Settings "UPDATES" n "string" "r"
		
		if(z != "" and v[1] != "" and v[3] > z and upd == true) then
		(
			szUpdated += "\t" + n + " " + v[3] + "\r\n\r\n"
			szUpdated += "Change Log:\r\n\r\n"
			
			r = getScriptIniInfo i releaseInfo:v[3]
			szUpdated += parseIniLine r + "\r\n"
			szUpdated += "_______________________________________\r\n\r\n" 
		)
		else if (v[1] != "" and v[3] != "" and z == "" and new == true) then 
		(			
			szNew += "\t" + n + " " + v[3] + "\r\n\r\n"
			
			szNew += "Change Log:\r\n\r\n"
				
			r = getScriptIniInfo i releaseInfo:v[3]
			szNew += parseIniLine r + "\r\n"
			szNew += "_______________________________________\r\n\r\n" 
		)
				
		rLauncher.Settings "UPDATES" n v[3] "w"
	)
	
	m1 = (filterString szNew "\t\r\n").count
	m2 = (filterString szUpdated "\t\r\n").count
	if(m1 > 0) do m += "Added new scripts:\r\n\r\n" + szNew	
	if(m2 > 0) do m += "Updated scripts:\r\n\r\n" + szUpdated
	
	
	if(m1 > 0 or m2 > 0) do
	(
		global rNotify
		try(DestroyDialog rNotify)catch()	
				
		global szStat = m
	
		rollout rNotify "New Releases" 
		(
			dotNetControl edtStat "System.Windows.Forms.Textbox" width:260 height:260 align:#center readOnly: true 
			checkbox cbxShowOnStartup "Show on start" align: #left  across: 2
			button btnOK "Ok" align: #right  width: 35
			
			on cbxShowOnStartup changed s do
			(
				rSettings.cbxScriptsUpdated.checked = s
				rSettings.cbxScriptsAdded.checked = s
				
				rLauncher.Settings "MAIN" "NOTIFYUPDATED" s "w"	
				rLauncher.Settings "MAIN" "NOTIFYNEW" s "w"
			)
			
			
			on btnOK pressed do try(DestroyDialog rNotify)catch()
			on rNotify open do 
			(	
				initTextBox edtStat
				edtStat.text = szStat	
				
				s = rSettings.cbxScriptsUpdated.checked  or rSettings.cbxScriptsAdded.checked
				cbxShowOnStartup.checked = s
			)
			on btnCopy pressed do setClipBoardText edtStat.text			
		)

		createDialog rNotify 260 295 --modal:true
	)
)

rollout rInstalls "Installs"
(
	group "Install Plugin (*.mzp)"
	(
		dropdownlist ddlInstalls ""
		button btnInstall "Install"
	)
	
	on rInstalls open do
	(
		szInstallsPath= getFiles(szInstallsDir + "\*" + szExt2)			
		ddlInstalls.items = for z in szInstallsPath collect (getFilenameFile z)
				
		rLauncher.lbxScriptList.Update()
		rLauncher.lbxScriptList.Refresh()
	)
	
	on btnInstall pressed do
	(
		i = ddlInstalls.selection
		
		if(i > 0  and szInstallsPath[i] != undefined and szInstallsPath[i] != "" and doesFileExist szInstallsPath[i]) do fileIn szInstallsPath[i] 
	)
)

rollout rTest "Test"
(
	group "Test Script"
	(
		dropdownlist ddlTest ""
		button btnTest "Test"
	)
	
	group "Description"
	(
		dotNetControl edtDescription "System.Windows.Forms.Textbox" height:200 align:#center 
	)
	
	on rTest open do
	(
		initTextBox edtDescription
		
		i = getFiles(szTestDir + "\*" + szExt)
		
		szTestPath = #("")
		
		join szTestPath i
		
		ddlTest.items = for z in szTestPath collect (getFilenameFile z)
		
		rLauncher.lbxScriptList.Update()
		rLauncher.lbxScriptList.Refresh()
	)
	
	on btnTest pressed do
	(
		i = ddlTest.selection
		
		if(szTestPath[i] != undefined and szTestPath[i] != "" and doesFileExist szTestPath[i]) do fileIn szTestPath[i] 
	)
	
	on ddlTest selected i do
	(		
		edtDescription.text = ""
		
		if(szTestPath[i] != undefined and szTestPath[i] != "" and doesFileExist szTestPath[i])  do
		(
			d = ""
			t = getScriptIniInfo szTestPath[i]		
			print t
			if(t[8] != undefined) do d = parseIniLine t[8]
						
			edtDescription.text = d
		)
		
	)
	
)

rollout rSettings "Settings"
(
	group "Dock Launcher"
	(
		checkbox cbxDockable "Dock Launcher" 
		radioButtons rdoDockTo "" labels:#("Left", "Right") default:1 columns:2 align: #left		
	)
	
	group "Notify Me When"
	(
		checkbox cbxScriptsUpdated "Scripts Updated" checked: true
		checkbox cbxScriptsAdded "New Scripts Added" checked: true
	)
	
	button btnOpenScripts "Open Scripts Folder" enabled: false
	timer tmrNotify active: true interval: 500

	on btnOpenScripts pressed do
	(
		if(doesDirectoryExist szScriptsDir) do return ShellLaunch szScriptsDir ""
		return messageBox "Scripts Directory not found!" title: "Warning!"
	)
	
	on cbxDockable changed x do
	(
		s = rdoDockTo.state
		rLauncher.fnSetDock x s				
	)
	
	on rdoDockTo changed s do
	(
		x = cbxDockable.checked
		
		if(x == true) do rLauncher.fnSetDock x s
	)
	
	on cbxScriptsUpdated changed x do rLauncher.Settings "MAIN" "NOTIFYUPDATED" x "w"
	
	on cbxScriptsAdded changed x do rLauncher.Settings "MAIN" "NOTIFYNEW" x "w"
	
	on rSettings open do
	(
		d = rLauncher.Settings "DOCK" "DOCKABLE"  "bool" "r"
		s = rLauncher.Settings "DOCK" "DOCKSIDE"  "int" "r"	
		try
		(
			cbxDockable.checked = d
			rdoDockTo.state = s 
		)
		catch()
		
		
		n = rLauncher.Settings "MAIN" "NOTIFYNEW"  "string" "r"
		u = rLauncher.Settings "MAIN" "NOTIFYUPDATED"  "string" "r"
				
		if(n != "") do cbxScriptsAdded.checked = rLauncher.Settings "MAIN" "NOTIFYNEW"  "bool" "r"
		if(u != "") do cbxScriptsUpdated.checked = rLauncher.Settings "MAIN" "NOTIFYUPDATED"  "bool" "r"
		
		
		rLauncher.lbxScriptList.Update()
		rLauncher.lbxScriptList.Refresh()
	)
	
	on tmrNotify tick do
	(
		notifyScripts()
		tmrNotify.active = false
	)
	
	on rSettings rolledUp x do
	(
		rLauncher.lbxScriptList.Update()
		rLauncher.lbxScriptList.Refresh()
	)
)

rollout rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	button btnInfo "Info" across: 2
	button btnHelp "Help" enabled: false
	
	fn getHelp run: false =
	(
		s = getThisScriptFilename()
		i = getScriptIniInfo s
		szHelp = (getFilenamePath s) + i[7]
		if(i[7] != "" and doesFileExist szHelp) do btnHelp.enabled = true
			
		if(run) do ShellLaunch szHelp ""
	)
	
	on btnHelp pressed do getHelp run: true
	
	on btnInfo pressed do displayInfo (getThisScriptFilename())
		
	on rAbout open do
	(		
		i = getScriptIniInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
		
		getHelp()
	)
	
	on rAbout rolledUp x do
	(
		rLauncher.lbxScriptList.Update()
		rLauncher.lbxScriptList.Refresh()
	)
)

addRollout rLauncher rScriptsLoader rolledUp:false 
addRollout rInstalls rScriptsLoader rolledUp:true 
addRollout rTest rScriptsLoader rolledUp:true 
addRollout rUpdate rScriptsLoader rolledUp:true 
addRollout rSettings rScriptsLoader rolledUp:true 
addRollout rAbout rScriptsLoader rolledUp:true

