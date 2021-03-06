#Checks for Admin rights and opens new shell with admin rights. Admin rights needed to add files if game installed in Program Files.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; 
	exit 
}
$error.clear()
#Finds install folder
$installpath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" -Name "InstallLocation" -erroraction silentlycontinue).InstallLocation
if ($Error -ne $null) {Write-Host "Valheim is not installed or can't be found."; Write-Host -NoNewLine 'Press any key to continue...';$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); exit}
#setup for menu selection
$install = New-Object System.Management.Automation.Host.ChoiceDescription '&Install', 'Install mods to game folder'
$remove = New-Object System.Management.Automation.Host.ChoiceDescription '&Remove', 'Remove mods from game folder'
$update = New-Object System.Management.Automation.Host.ChoiceDescription '&Update', 'Update mods and config files in game folder'
$quit = New-Object System.Management.Automation.Host.ChoiceDescription '&Q', 'Quit out of tool.'
$title = 'SITH Clan Valheim Mods'
$message = 'What would you like to do today?'

Write-Host "Press Ctrl-C if script appears to hang up."
#creates menu and prompts
$options = [System.Management.Automation.Host.ChoiceDescription[]]($install, $remove, $update,$quit)

#runs menu until a valid selection is made
do {
	#displays menu
	$result = $host.ui.PromptForChoice($title, $message, $options, 0)
	Switch ($result) {
		0 {Write-Host "Installing Mods";
			#defines output file name and attachs to game folder
			$output = $installpath + "\Valheim_mods.zip"
			#download file for combined mods
			$url = "https://github.com/Dhovin/Valheim_SITH_Clan/raw/main/Valheim.zip"
			#Establishs WebClient and downloads mods to game folder
			$wc = New-Object System.Net.WebClient
			$wc.DownloadFile($url, $output)
			#expands archive into game folder
			Expand-Archive -Path $output -DestinationPath $installpath -force
			#Cleans up downloaded zip file
			Remove-Item -Path $output
			break
			}
		1 {Write-Host 'Removing Mods';
			#removes mod folders and files
			Remove-Item -Path ($installpath+"\BepInEx\") -Force -Recurse
			Remove-Item -Path ($installpath+"\doorstop_libs\") -Force -Recurse
			Remove-Item -Path ($installpath+"\unstripped_corlib\") -Force -Recurse
			Remove-Item -Path ($installpath+"\doorstop_config.ini") -Force
			Remove-Item -Path ($installpath+"\winhttp.dll") -Force
			break}
		2 {Write-Host 'Updating mods and config files'
			$error.clear()
			#installs package provider needed to install GitHub interation module
			If (-not (Get-PackageProvider -ListAvailable -Name nuget -erroraction 'silentlycontinue')) {(Install-PackageProvider -Name Nuget -scope CurrentUser -Force | Out-Null)}
			#installs GitHub integration module
			If (-not (Get-Module -ListAvailable -Name PowerShellForGitHub)) {Install-Module -Name PowerShellForGitHub -scope CurrentUser -Force}
			#Disables telemetry data for GitHub module commands to follow
			Set-GitHubConfiguration -DisableTelemetry
			#checks for files in repository config folder and get name and download link
			$configfiles = (Get-GitHubContent -OwnerName Dhovin -RepositoryName Valheim_SITH_clan -Path config).entries | Select-Object name,download_url
			$pluginfiles = (Get-GitHubContent -OwnerName Dhovin -RepositoryName Valheim_SITH_clan -Path plugins).entries | Select-Object name,download_url
			#set local path for files to go to
			$configpath = ($installpath+"\BepInEx\config\")
			$pluginpath = ($installpath+"\BepInEx\plugins\")
			#downloads and installs to appropriate folder
			$configfiles | ForEach-Object {If (Test-Path -Path ($configpath)){$wc = New-Object System.Net.WebClient; $wc.DownloadFile($_.download_url, ($configpath+$_.name))}else {Write-Host "config folder missing. Install mods."; $result = 55}}
			$pluginfiles | ForEach-Object {If (Test-Path -Path ($pluginpath)){$wc = New-Object System.Net.WebClient; $wc.DownloadFile($_.download_url, ($pluginpath+$_.name))}else {Write-Host "plugins folder missing. Install mods."; $result = 55}}
			if ($error -ne $null) {Write-Host "Mods updates successfully"}Else{}
			break}
		3 {exit}
		}
	} until (($result -eq 0) -or ($result -eq 1) -or ($result -eq 2) -or ($remove -eq 3))

#Uncomment below to add "Press to continue..." prompt
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');