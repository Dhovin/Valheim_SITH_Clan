if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
$installpath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" -Name "InstallLocation").InstallLocation
$output = $installpath + "\Valheim_mods.zip"
$url = "https://github.com/Dhovin/Valheim_SITH_Clan/raw/main/Valheim.zip"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $output)
Expand-Archive -Path $output -DestinationPath $installpath
#Write-Host -NoNewLine 'Press any key to continue...';
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');