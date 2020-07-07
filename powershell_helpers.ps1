#!/bin/powershell
# author: Alan Livio <alan@telemidia.puc-rio.br>
# URL:    https://github.com/alanlivio/shell.env

# thanks
# https://gist.github.com/alirobe/7f3b34ad89a159e6daa1
# https://gist.github.com/thoroc/86d354d029dda303598a

# ---------------------------------------
# load powershell_helpers_cfg
# ---------------------------------------

$SCRIPT_NAME = "$PSScriptRoot\powershell_helpers.ps1"
$SCRIPT_DIR = $PSScriptRoot
$SCRIPT_CFG = "$SCRIPT_DIR\powershell_helpers_cfg.ps1"
if (Test-Path $SCRIPT_CFG) {
  Import-Module -Force -Global $SCRIPT_CFG
}

# ---------------------------------------
# alias
# ---------------------------------------
Set-Alias -Name grep -Value Select-String
Set-Alias -Name choco -Value C:\ProgramData\chocolatey\bin\choco.exe
Set-Alias -Name gsudo -Value C:\ProgramData\chocolatey\lib\gsudo\bin\gsudo.exe

# ---------------------------------------
# go home
# ---------------------------------------
Set-Location ~

# ---------------------------------------
# profile functions
# ---------------------------------------

function hf_profile_install() {
  Write-Output "Import-Module -Force -Global $SCRIPT_NAME" > $Profile.AllUsersAllHosts
}

function hf_profile_reload() {
  powershell -nologo
}

function hf_profile_import($path) {
  Write-Output "RUN: Import-Module -Force -Global $path"
}

# ---------------------------------------
# powershell functions
# ---------------------------------------

function hf_powershell_show_function($name) {
  Get-Content Function:\$name
}

function hf_powershell_enable_scripts() {
  Set-ExecutionPolicy unrestricted
}

function hf_powershell_profiles_list() {
  $profile | Select-Object -Property *
}

function hf_powershell_profiles_reset() {
  $profile.AllUsersAllHosts = "\Windows\System32\WindowsPowerShell\v1.0\profile.ps1"
  $profile.AllUsersCurrentHost = "\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1"
  $profile.CurrentUserAllHosts = "WindowsPowerShell\profile.ps1"
  $profile.CurrentUserCurrentHost = "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
}

# ---------------------------------------
# system functions
# ---------------------------------------

function hf_system_rename($new_name) {
  Rename-Computer -NewName "$new_name"
}

function hf_system_win_version() {
  Get-ComputerInfo | Select-Object windowsversion
}

function hf_system_path_add($addPath) {
  if (Test-Path $addPath) {
    $path = [Environment]::GetEnvironmentVariable('path', 'Machine')
    $regexAddPath = [regex]::Escape($addPath)
    $arrPath = $path -split ';' | Where-Object { $_ -notMatch 
      "^$regexAddPath\\?" }
    $newpath = ($arrPath + $addPath) -join ';'
    [Environment]::SetEnvironmentVariable("path", $newpath, 'Machine')
  }
  else {
    Throw "'$addPath' is not a valid path."
  }
}

function hf_system_adjust_visual_to_performace() {
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name 'VisualFXSetting' -Value 2 -PropertyType DWORD -Force | Out-Null
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name 'EnableTransparency' -Value 0 -PropertyType DWORD -Force | Out-Null
}

function hf_system_disable_unused_features() {
  # fax
  Remove-Printer -Name "Fax" -ErrorAction SilentlyContinue

  # XPS Services
  dism.exe /online /quiet /disable-feature /featurename:Printing-XPSServices-Features /norestart

  # Internet Explorer
  dism.exe /online /quiet /disable-feature /featurename:Internet-Explorer-Optional-$env:PROCESSOR_ARCHITECTURE /norestart

  # Work Folders
  dism.exe /online /quiet /disable-feature /featurename:WorkFolders-Client /norestart

  # WindowsMediaPlayer
  dism.exe /online /quiet /disable-feature /featurename:WindowsMediaPlayer /norestart
}

function hf_system_disable_password_policy {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  $tmpfile = New-TemporaryFile
  secedit /export /cfg $tmpfile /quiet
  (Get-Content $tmpfile).Replace("PasswordComplexity = 1", "PasswordComplexity = 0").Replace("MaximumPasswordAge = 42", "MaximumPasswordAge = -1") | Out-File $tmpfile
  secedit /configure /db "$env:SYSTEMROOT\security\database\local.sdb" /cfg $tmpfile /areas SECURITYPOLICY | Out-Null
  Remove-Item -Path $tmpfile
}

# ---------------------------------------
# network functions
# ---------------------------------------

function hf_network_list_wifi_SSIDs() {
  return (netsh wlan show net mode=bssid)
}

# ---------------------------------------
# link functions
# ---------------------------------------

function hf_link_create($desntination, $source) {
  cmd /c mklink /D $desntination $source
}

# ---------------------------------------
# store functions
# ---------------------------------------

function hf_store_list_installed() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  Get-AppxPackage -AllUsers | Select-Object Name, PackageFullName
}

function hf_store_install($name) {
  Write-Host $MyInvocation.MyCommand.ToString() "$name"  -ForegroundColor YELLOW
  Get-AppxPackage -allusers $name | ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" }
}

function hf_store_install_essentials() {
  Write-Host $MyInvocation.MyCommand.ToString()  -ForegroundColor YELLOW
  hf_store_install Microsoft.WindowsStore
  hf_store_install Microsoft.WindowsCalculator
  hf_store_install Microsoft.Windows.Photos
}

function hf_store_reinstall_all() {
  Get-AppXPackage -AllUsers | ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" }
}

# ---------------------------------------
# folders functions
# ---------------------------------------

function hf_remove_unused_folders() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  $folders = @("Favorites/", "OneDrive/", "Pictures/", "Public/", "Templates/", "Videos/", "Music/", "Links/", "Saved Games/", "Searches/", "SendTo/", "PrintHood", "MicrosoftEdgeBackups/", "IntelGraphicsProfiles/", "Contacts/", "3D Objects/", "Recent/", "NetHood/")
  $folders | ForEach-Object { Remove-Item -Force -Recurse -ErrorAction Ignore $_ }
}

# ---------------------------------------
# explorer functions
# ---------------------------------------

function hf_explorer_open_start_menu_folder() {
  explorer '%ProgramData%\Microsoft\Windows\Start Menu\Programs'
}

function hf_explorer_open_task_bar_folder() {
  explorer '%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
}

function hf_explorer_open_startup_folder() {
  explorer 'shell:startup'
}

function hf_explorer_open_home_folder() {
  explorer $env:userprofile
}

function hf_explorer_hide_dotfiles() {
  Get-ChildItem "$env:userprofile\.*" | ForEach-Object { $_.Attributes += "Hidden" }
}

function hf_explorer_restart() {
  # restart
  taskkill /f /im explorer.exe | Out-Null
  Start-Process explorer.exe
}

function hf_explorer_sanity_search() {
  # https://superuser.com/questions/1498668/how-do-you-default-the-windows-10-explorer-view-to-details-when-looking-at-sea/1499413
  (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes' |
    Where-Object { (Get-ChildItem $_.PSPath).CanonicalName -match '\.S' }).PSChildname |
  ForEach-Object {
    $SRPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell\$_"
    New-Item  -ErrorAction SilentlyContinue  -Force -Path $SRPath | Out-Null
    New-ItemProperty -ErrorAction SilentlyContinue -Force -Path $SRPath -Name 'Mode' -Value 4 | Out-Null
  }
}

function hf_explorer_sanity_lock() {
  If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" | Out-Null
  }
  Set-ItemProperty  -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Type DWord -Value 1 | Out-Null
}

function hf_explorer_sanity_taskbar() {
  # use small icons
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarSmallIcons  -PropertyType DWORD -Value 1 -Force | Out-Null

  # hide search button
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchboxTaskbarMode -PropertyType DWORD -Value 0 -Force | Out-Null

  # hide task view button
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Software\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView" -Force -Recurse | Out-Null
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton  -PropertyType DWORD -Value 0 -Force | Out-Null

  # hide taskbar people icon
  if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" | Out-Null
  }
  Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 0

  # disable action center
  if (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
  }
  Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
  Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0
}

function hf_explorer_sanity_navigation() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW

  # Hide icons in desktop
  $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
  Set-ItemProperty -Path $Path -Name "HideIcons" -Value 1

  # Hide recently and frequently used item shortcuts in Explorer
  Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Type DWord -Value 0

  # Set explorer to open to "This PC"
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name LaunchTo -PropertyType DWORD -Value 1 -Force | Out-Null

  # Show file extensions
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -PropertyType DWORD -Value 0 -Force | Out-Null

  # Remove 'Customize this folder' from context menu
  New-Item -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force | Out-Null
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoCustomizeThisFolder -Value 1 -PropertyType DWORD -Force | Out-Null

  # Remove 'Restore to previous versions' from context menu (might be superflous, just in case)
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Directory\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Drive\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" -Force -Recurse | Out-Null

  # Remove 'Share with' from context menu (First 9 might be superflous, just in case)
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Directory\Background\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Directory\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Directory\shellex\CopyHookHandlers\Sharing" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Directory\shellex\PropertySheetHandlers\Sharing" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Drive\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\Drive\shellex\PropertySheetHandlers\Sharing" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing" -Force -Recurse | Out-Null
  New-ItemProperty -ErrorAction SilentlyContinue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name SharingWizardOn -PropertyType DWORD -Value 0 -Force | Out-Null

  # Remove 'Include in library' from context menu (might be superflous, just in case)
  Remove-Item -ErrorAction SilentlyContinue "HKCR:\Folder\ShellEx\ContextMenuHandlers\Library Location" -Force -Recurse | Out-Null
  Remove-Item -ErrorAction SilentlyContinue "HKLM:\SOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\Library Location" -Force -Recurse | Out-Null

  # Remove 'Send to' from context menu (might be superflous, just in case)
  Remove-Item -ErrorAction SilentlyContinue -Path "HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo" -Force -Recurse | Out-Null

  # Disable search for app in store for unknown extensions
  If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
  }
  Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoUseStoreOpenWith" -Type DWord -Value 1
}

function hf_explorer_sanity_start_menu() {
  # Remove tiles
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  (New-Object -Com Shell.Application).
  NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').
  Items() |
  ForEach-Object { $_.Verbs() } |
  Where-Object { $_.Name -match 'Un.*pin from Start' } |
  ForEach-Object { $_.DoIt() }

  # Disable Bing
  reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /d "0" /t REG_DWORD /f | Out-Null
  reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /v AllowSearchToUseLocation /d "0" /t REG_DWORD /f | Out-Null
  reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaConsent /d "0" /t REG_DWORD /f | Out-Null
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb  /d "0" /t REG_DWORD /f | Out-Null
}

# ---------------------------------------
# customize functions
# ---------------------------------------

function hf_enable_dark_mode() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 00000000 /f | Out-Null
}

# ---------------------------------------
# uninstall functions
# ---------------------------------------

function hf_uninstall_ondrive() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  c:\\Windows\\SysWOW64\\OneDriveSetup.exe /uninstall
}

function hf_uninstall_not_essential_store_packages() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW

  # windows
  $pkgs = 'Microsoft.XboxGameOverlay
  Microsoft.GetHelp
  Microsoft.XboxApp
  Microsoft.Xbox.TCUI
  Microsoft.XboxSpeechToTextOverlay
  Microsoft.Wallet
  Microsoft.MinecraftUWP
  A278AB0D.MarchofEmpires
  king.com.FarmHeroesSaga_5.34.8.0_x86__kgqvnymyfvs32
  king.com.BubbleWitch3Saga
  Microsoft.Messaging
  Microsoft.Appconnector
  Microsoft.BingNews
  Microsoft.SkypeApp
  Microsoft.BingSports
  Microsoft.CommsPhone
  Microsoft.ConnectivityStore
  Microsoft.Office.Sway
  Microsoft.WindowsPhone
  Microsoft.XboxIdentityProvider
  Microsoft.StorePurchaseApp
  Microsoft.DesktopAppInstaller
  Microsoft.BingWeather
  Microsoft.MicrosoftStickyNotes
  Microsoft.MicrosoftSolitaireCollection
  Microsoft.OneConnect
  Microsoft.People
  Microsoft.ZuneMusic
  Microsoft.ZuneVideo
  Microsoft.Getstarted
  Microsoft.XboxApp
  Microsoft.windowscommunicationsapps
  Microsoft.WindowsCamera
  Microsoft.WindowsSoundRecorder
  Microsoft.WindowsMaps
  Microsoft.3DBuilder
  Microsoft.WindowsFeedbackHub
  Microsoft.MicrosoftOfficeHub
  Microsoft.WindowsAlarms
  Microsoft.3DBuilder
  Microsoft.OneDrive
  Microsoft.Print3D
  Microsoft.Office.OneNote
  Microsoft.Microsoft3DViewer
  Microsoft.XboxGamingOverlay
  Microsoft.MSPaint
  Microsoft.Office.Desktop
  Microsoft.MicrosoftSolitaireCollection
  Microsoft.MixedReality.Portal'
  $pkgs -split '\s+|,\s*' -ne '' | ForEach-Object { Get-AppxPackage -allusers $_ | Remove-AppxPackage -ErrorAction SilentlyContinue -AllUsers | Out-Null }

  # others
  $pkgs = 'Facebook.Facebook
  SpotifyAB.SpotifyMusic
  9E2F88E3.Twitter
  A278AB0D.DisneyMagicKingdoms
  king.com.CandyCrushFriends
  king.com.BubbleWitch3Saga
  king.com.CandyCrushSodaSaga
  king.com.FarmHeroesSaga
  7EE7776C.LinkedInforWindows
  king.com.CandyCrushSaga
  NORDCURRENT.COOKINGFEVER'
  $pkgs -split '\s+|,\s*' -ne '' | ForEach-Object { Get-AppxPackage -allusers $_ | Remove-AppxPackage -ErrorAction SilentlyContinue -AllUsers | Out-Null }
}

# ---------------------------------------
# permissions functions
# ---------------------------------------

function hf_adminstrator_user_enable() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  net user administrator /active:yes
}

function hf_adminstrator_user_disable() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  net user administrator /active:no
}

# ---------------------------------------
# update functions
# ---------------------------------------

function hf_windows_update() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  control update
  wuauclt /detectnow /updatenow
}

# ---------------------------------------
# choco function
# ---------------------------------------

function hf_choco_cleaner() {
  hf_choco_install choco-cleaner
  \ProgramData\chocolatey\bin\Choco-Cleaner.ps1
}

function hf_choco_install() {
  choco install -y --acceptlicense --no-progress --ignorechecksum  ($args -join ";")
}

function hf_choco_uninstall() {
  choco uninstall -y --acceptlicense --no-progress ($args -join ";")
}

function hf_choco_upgrade() {
  choco upgrade -y --acceptlicense --no-progress
}

# ---------------------------------------
# wsl function
# ---------------------------------------

function hf_wsl_root() {
  wsl -u root
}

function hf_wsl_list() {
  wsl --list -v
}

function hf_wsl_list_running() {
  wsl --list --running
}

function hf_wsl_terminate_running() {
  wsl -t ((wsl --list --running -split [System.Environment]::NewLine)[3]).split(' ')[0]
}

function hf_wsl_ubuntu_set_default_user() {
  ubuntu.exe config --default-user alan
}

function hf_wsl_enable_features() {
  Write-Output "-- (1) after hf_wsl_enable_features, reboot "
  Write-Output "-- (2) in WindowStore, download ubuntu"
  Write-Output "-- (3) in PowerShell terminal, run hf_wsl_fix_home_user"
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  # https://docs.microsoft.com/en-us/windows/wsl/wsl2-install
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
}

function hf_wsl_fix_home_user() {
  # fix file metadata
  # https://docs.microsoft.com/en-us/windows/wsl/wsl-config
  # https://github.com/Microsoft/WSL/issues/3138
  # https://devblogs.microsoft.com/commandline/chmod-chown-wsl-improvements/
  wsl -u root touch /etc/wsl.conf
  bash -c 'echo "[automount]" > /etc/wsl.conf'
  bash -c 'echo "enabled=true" >> /etc/wsl.conf'
  bash -c 'echo "root=/mnt" >> /etc/wsl.conf'
  bash -c 'echo "mountFsTab=false" >> /etc/wsl.conf'
  bash -c 'echo "options=\"metadata,uid=1000,gid=1000,umask=0022,fmask=11\"" >> /etc/wsl.conf'
  wsl -t Ubuntu

  # ensure sudoer
  wsl -u root usermod -aG sudo "$env:UserName"
  wsl -u root usermod -aG root "$env:UserName"

  # change default folder to /mnt/c/Users/
  wsl -u root skill -KILL -u $env:UserName
  wsl -u root usermod -d /mnt/c/Users/$env:UserName $env:UserName

  # change permissions
  wsl -u root chown -R $env:UserName:$env:UserName /mnt/c/Users/$env:UserName
}

# ---------------------------------------
# install function
# ---------------------------------------

function hf_install_chocolatey() {
  if (-Not (Get-Command 'choco' -errorAction SilentlyContinue)) {
    Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Set-Variable "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    cmd /c 'setx ChocolateyToolsLocation C:\opt\'

    choco feature enable -n allowGlobalConfirmation
    choco feature enable -n allowEmptyChecksumsSecure
    choco feature disable -n showNonElevatedWarnings
    choco feature disable -n showDownloadProgress
    choco feature enable -n removePackageInformationOnUninstall
    choco feature enable -n exitOnRebootDetected
  }
}

function hf_install_battle_steam_stramio() {
  hf_choco_install battle.net steam stremio
}

# ---------------------------------------
# config functions
# ---------------------------------------

function hf_config_install_wt($path) {
  Copy-Item $path $env:userprofile\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
}

function hf_config_installvscode($path) {
  Copy-Item $path .\AppData\Roaming\Code\User\settings.json
}

function hf_config_wt_open() {
  code $env:userprofile\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
}

# ---------------------------------------
# init functions
# ---------------------------------------

function hf_windows_sanity() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  hf_system_disable_password_policy
  hf_system_adjust_visual_to_performace
  hf_explorer_sanity_navigation
  hf_explorer_sanity_start_menu
  hf_explorer_sanity_search
  hf_system_disable_unused_features
  hf_explorer_sanity_taskbar
  hf_explorer_sanity_lock
  hf_explorer_restart
  hf_remove_unused_folders
  hf_system_disable_unused_features
  hf_uninstall_ondrive
}

function hf_windows_init_user_nomal() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  Write-Output "-- (1) in other PowerShell terminal, run hf_uninstall_not_essential_store_packages"
  hf_install_chocolatey
  hf_windows_sanity
  hf_choco_install GoogleChrome vlc 7zip ccleaner FoxitReader
}

function hf_windows_init_user_bash() {
  Write-Host $MyInvocation.MyCommand.ToString() -ForegroundColor YELLOW
  Write-Output "-- (1) in other PowerShell terminal, run hf_uninstall_not_essential_store_packages"
  Write-Output "-- (2) in PowerShell terminal, run hf_config_install_wt <profiles.jon>"
  hf_install_chocolatey
  hf_choco_install vscode gsudo msys2
  hf_system_path_add 'C:\ProgramData\chocolatey\lib\gsudo\bin'
  hf_windows_sanity
  hf_choco_install GoogleChrome vlc 7zip ccleaner FoxitReader
}