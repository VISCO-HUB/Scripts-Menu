macroScript runScriptsLauncher
category:"[VISCOCG]" 
toolTip:"Scripts Launcher" 
buttontext:"SL"
Icon:#("UVWUnwrapView",19)
(	
	szScript = @"\\visco.local\data\Instal_Sync\scripts\MENU.ms"
	try(fileIn(szScript)) catch(messageBox "Lost network connection!" title: "Warning!")
)
	
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
		szScriptHelpFile = getFilenamePath (getThisScriptFilename()) + @"help\scriptsLauncher.html"
			
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
		m += "How to add button on tool bar:\r\n"
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
		m += "\t\tScripts Launcher\r\n\t\tMastaMan\r\n\t\tViscoCG\r\n\t\tGNU GPL v3.0"
	
		edtStat.text = m				
	)
		
)

createDialog rNotify 350 500
	