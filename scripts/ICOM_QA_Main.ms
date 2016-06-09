--ScriptName: ICOM_QA_Main
--author: Anton Berg
--version: 18
--createdDate: Mon May 09 2016 11:49:57 GMT+0000 (UTC)
--updateDate: Mon May 09 2016 14:58:52 GMT+0000 (UTC)
--description: Installation of QA scripts
--key: d95ed9342f2a18e0f6c5b7ee8e6a0b4f

	Struct DownloadUtils (
	fn existFile fname = ((getfiles fname).count != 0),
	
	--Inits some of the namespaces used by all functions below
	fn InitDotNetNamespace = (
		format "DownloadUtils version:%\n" Version
		
		dotNetClass "System.Net"
		dotNetClass "System.Web"
		dotNetClass "System.IO"
		dotNetClass "System"
	),
	
	-- Gets the content from the remote url and stores as a string directly in memory
	fn GetStringFromUrl urlString = (
		returnVal = ""
		error = ""
		
		DownloadUtils.InitDotNetNamespace()
		StringWebClient = dotNetObject "System.Net.WebClient"
		--StringWebClient.encoding = dotNetObject "System.Text.UTF8Encoding"
		--StringWebClient.encoding = dotNetObject "System.Text.UnicodeEncoding"
		try (
			returnVal = StringWebClient.DownloadString urlString
		) catch (
			returnVal = "" 
			format "*** % ***\n" (getCurrentException())
			error = getCurrentException()
		)
		StringWebClient.Dispose()
		return #((returnVal as stringstream),error)
	),
	
	-- Downloads a file from the remote url and stores at local path
	fn Downloadfile RemoteFileUrl LocalFileUrl = (
		error = ""
		DownloadUtils.InitDotNetNamespace()
		FileWebClient = dotNetObject "System.Net.WebClient"
		dlName = (LocalFileUrl + ".dlTemp")
		try (
			returnVal = FileWebClient.DownloadFile RemoteFileUrl dlName
			deleteFile LocalFileUrl
			CouldRename = renamefile dlName LocalFileUrl
			if CouldRename != true then (   
			format "***ERROR COULD NOT DELETE OLD MAXSCRIPT. IS IT LOCKED?? \nFile:%\n\n***" LocalFileUrl
			error = ("***ERROR COULD NOT DELETE OLD MAXSCRIPT. IS IT LOCKED?? ***")
			)
			
			FileWebClient.Dispose()
		) catch (
			format "*** % ***\n" (getCurrentException())
			error = (getCurrentException())
			FileWebClient.Dispose()
			
		)
		return #(returnVal, error)
	),
	
	--Gets the path to this User application directory
	fn getIkeaUserScriptFolder = (
		returnVal = ""
		maxVers = (maxVersion()) [1] as string 
		DownloadUtils.InitDotNetNamespace()
		
		Environment = dotNetClass "System.Environment" 
		BaseAppdataPath = Environment.GetFolderPath ((dotnetclass "Environment+SpecialFolder").ApplicationData)
		ExtraPath = ("IKEA Communications AB\\MaxScript\\" + maxVers)
		returnVal = (BaseAppdataPath + "\\IKEA Communications AB\\MaxScript\\" + maxVers + "\\" )
		
		--The makedir command in 3dsmax does not work with this folder		
		success = hiddenDosCommand ("mkdir \"" + ExtraPath + "\"") startpath:BaseAppdataPath
		if success != true then returnVal = ""
			
		return returnVal
	),
	
	--Ping address
	fn PingUrl urlString = (
		IPStatus = dotNetClass "System.Net.NetworkInformation.IPStatus"
		ping = dotNetObject "System.Net.NetworkInformation.Ping"
		pingReply = dotNetObject "System.Net.NetworkInformation.PingReply" (ping.send urlString)

		return (pingReply.status == IPStatus.Success)
	),
	
	--This downloads and tries to executes the url
	fn executeStartUpScript RemoteUrlString localFileName = (
		format " == Startup script running == \n"
		scriptVersion = " Old Cached Version "
		
		--create base folder
		UserScriptFolder = DownloadUtils.getIkeaUserScriptFolder()
		format "StartupFolder: %\n" UserScriptFolder
		
		--localPath to script
		LocalFilePath = (UserScriptFolder + localFileName)
		
		--try to download the latest script from webservser and store locally
		Success = DownloadUtils.Downloadfile RemoteUrlString LocalFilePath
		if Success[2] != "" 
		then ( format "Download of remote file did not work, produced the following error\n%" Success[2] ) 
		else ( format "file downloaded successfully\n" 
		scriptVersion = " Latest Remote Updated Version "	
		)
		
		--time to execute the script from the localStorage
		if (DownloadUtils.existFile LocalFilePath) then (
			msg = DownloadUtils.GetStringFromUrl LocalFilePath
			try (execute msg[1]) 
			catch(format "The Script contined errors\n*** % ***\n" (getCurrentException()))
				
		) else (
			format "======== COULD NOT DOWNLOAD FILE FROM URL OR FIND A LOCAL CACHED VERSION"	
		)
		
		return ("executed the"+scriptVersion+ "script\n" + LocalFilePath + "\n")
		
	),
	
	fn getFilesRecursive root pattern = (
		dir_array = GetDirectories (root+"\\*")
		for d in dir_array do (
			join dir_array (GetDirectories (d+"\\*"))
		)
		my_files = #()
		for f in dir_array do (
			join my_files (getFiles (f + pattern))
		)
		my_files
	),
	
	fn copyTree inputFolder outputFolder removeInputfiles:true= (
		fileList = this.getFilesRecursive inputFolder "*"
		for file in fileList do (
			NewOutputFilePath = substituteString file inputFolder outputFolder
			makedir (getfilenamepath NewOutputFilePath) all:true
			try (
				didDelete = deletefile NewOutputFilePath
				format "deleted existing file: %\n" didDelete
			) catch()
			try (
				didCopy = copyfile file NewOutputFilePath
				format "copied existing file: %\n" didCopy	
			) catch()
		)
		
		if removeInputfiles then (
			for file in fileList do try (deletefile file) catch ()
		)
		
	)

)
	
DLUtils = DownloadUtils()

--messagebox ("hello world:\n" + getIkeaUserScriptFolder())
global IKEAUserFolder = DLUtils.getIkeaUserScriptFolder()

print "start to download asset files"
DLUtils.Downloadfile @"http://icom-scripts.cloudapp.net/assets/AssetFiles.mzp" (IKEAUserFolder + @"/AssetFiles.mzp")
print "end download asset mzp files"

extractDir = ""
if msZip.fileInPackage (IKEAUserFolder + @"/AssetFiles.mzp") &extractDir then 
( 
	DLUtils.copyTree extractDir (IKEAUserFolder + "icomQA_tools")
	--messagebox ("extractdir for assets is: \n" + ("\\assetfiles\\"))
)

DLUtils.executeStartUpScript @"http://icom-scripts.cloudapp.net/scripts/compiled/icom_qa?key=d95ed9342f2a18e0f6c5b7ee8e6a0b4f" "icom_qa.ms"

format "ICOM QA assets, install complete!!"