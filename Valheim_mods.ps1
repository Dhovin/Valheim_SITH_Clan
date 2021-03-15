#Checks for Admin rights and opens new shell with admin rights. Admin rights needed to add files if game installed in Program Files.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; 
	exit 
}

#Finds install folder
$installpath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" -Name "InstallLocation").InstallLocation
#setup for menu selection
$install = New-Object System.Management.Automation.Host.ChoiceDescription '&Install', 'Install mods to game folder'
$remove = New-Object System.Management.Automation.Host.ChoiceDescription '&Remove', 'Remove mods from game folder'
$update = New-Object System.Management.Automation.Host.ChoiceDescription '&Update', 'Update mod config files in game folder'
$quit = New-Object System.Management.Automation.Host.ChoiceDescription '&Q', 'Quit out of tool.'
$title = 'SITH Clan Valheim Mods'
$message = 'What would you like to do today?'

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
		2 {Write-Host 'updating mods'
			If(-not (Get-Module -ListAvailable -Name PowerShellForGitHub)) {Install-Module -Name PowerShellForGitHub -scope CurrentUser}
			$configfiles = (Get-GitHubContent -OwnerName Dhovin -RepositoryName Valheim_SITH_clan -Path config).entries | Select-Object name,download_url
			$outputpath = ($installpath+"\BepInEx\config\")
			$configfiles | ForEach-Object {If (Test-Path -Path ($outputpath)){$wc = New-Object System.Net.WebClient; $wc.DownloadFile($_.download_url, ($outputpath+$_.name))}else {Write-Host "config folder missing. Install mods."; $result = 55}}
			break}
		3 {exit}
		}
	} until (($result -eq 0) -or ($result -eq 1) -or ($result -eq 2) -or ($remove -eq 3))

#Uncomment below to add "Press to continue..." prompt
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');