macroScript runScriptsLauncher
category:"[VISCOCG]" 
toolTip:"Scripts Launcher" 
buttontext:"SL"
Icon:#("UVWUnwrapView",19)
(	
	szScript = @"\\visco.local\data\Instal_Sync\scripts\MENU.ms"
	try(fileIn(szScript)) catch(messageBox "Lost network connection!" title: "Warning!")
)

fn addToolBarButton macro cat txt =
(
	try
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
			
			mt = "\"Main Toolbar\""
			
			skipToString stream mt
			
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
	) catch(messageBox "Error to install Scripts Launcher!\nPlease install manually!" title: "Error!")
)

addToolBarButton "runScriptsLauncher" "VISCOCG" "Scripts Launcher"

rollout rNotify "Installed Success!" 
(		
	dotNetControl edtStat "System.Windows.Forms.Textbox" width:350 height:460 align:#center 
			
	button btnCopy "Copy" align: #left width: 50 across: 3
	button btnScriptHelp "Help" width: 50 align: #right tooltip: "Help is not available for this script" enabled: false offset: [-110, 0]	
	button btnOK "Ok" align: #right  width: 50
	
	global szScriptHelpFile = "" 
	
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
	
	on btnScriptHelp pressed do
	(
		if(doesFileExist szScriptHelpFile) do shellLaunch szScriptHelpFile ""
	)

	on btnOK pressed do try(DestroyDialog rNotify)catch()
	on btnCopy pressed do setClipBoardText edtStat.text	
		
	on rNotify open do
	(
		szScriptHelpFile = @"\\visco.local\data\Instal_Sync\scripts\help\scriptsLauncher.html"
			
		if(doesFileExist szScriptHelpFile) do 
		(
			btnScriptHelp.enabled = true
			btnScriptHelp.tooltip = ""
		)
		
		initTextBox edtStat
		
		s = "\r\n\r\n___________________________________________________\r\n\r\n"
		m = ""
		m += "\r\nScripts Launcher installed succes!"
		m += s
		m += "If no added button on tool bar automatically:\r\n"
		m += "\r\n1. Go to \"Customize\""
		m += "\r\n2. Choose \"Customize User Interface\""
		m += "\r\n3. Choose tab \"Toolbars\""
		m += "\r\n4. Select category \"[VISCOCG]\" in the end of list"
		m += "\r\n5. Drag&Drop \"Scripts Launcher\" to your tool bar"
		m += s
		m += "Important:\r\n"
		m += "\r\nPlease read help for Scripts Launcher in About section!"
		m += s
		m += "Installed from:\r\n\r\n"
		m += getFilenamePath (getThisScriptFilename()) 
		m += s	
		m += "\t\tScripts Launcher\r\n\r\n\t\tMastaMan\r\n\r\n\t\tViscoCG\r\n\t\tGNU GPL v3.0"
	
		edtStat.text = m				
	)
		
)

createDialog rNotify 350 500
	