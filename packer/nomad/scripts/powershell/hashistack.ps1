###############################################################################################
#
#   Repo:           packer/templates/powershell
#   File Name:      hashistack.ps1
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           April 2021
#   Description:    Hashistack windows client installation script
#
###############################################################################################
param (
    [string]$c = "", 
    [string]$n = "",
    [string]$i = $null
)

Write-Host "Configure UAC to Allow Privilege Elevation in Remote Shells"
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

Write-Host "Turn Off the Firewall Because It's Being Handled Through the Security Group"
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

Write-Host "Turn Off UAC"
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force

Write-Host "Set Folder Options"
$Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $key Hidden 1
Set-ItemProperty $key HideFileExt 0
Set-ItemProperty $key ShowSuperHidden 0
Stop-Process -processname explorer

Write-Host "Disable IE Advanced Security"
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

Write-Host "Pull a docker image"
if ($i) {
    docker pull $i
}

Write-Host "Install Chocolately Package Manager"
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Host "Enable Chocolately Auto Confirmation"
choco feature enable -n allowGlobalConfirmation

Write-Host "Install SSH"
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
# Start the service
Start-Service sshd
# OPTIONAL but recommended:
Set-Service -Name sshd -StartupType 'Automatic'
# Confirm the Firewall rule is configured. It should be created automatically by setup.
Get-NetFirewallRule -Name *ssh*
# There should be a firewall rule named "OpenSSH-Server-In-TCP", which should be enabled
# If the firewall does not exist, create one
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
# Set the shell to powershell which recognizes some bash commands.
# New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

Write-Host "Install IIS"
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Install-WindowsFeature -name Web-App-Dev -IncludeAllSubFeature

Write-Host "Install Go Language"
choco install golang

Write-Host "Install Git"
choco install git

Write-Host "Install Make"
choco install make

Write-Host "Install Java"
choco install jdk8

Write-Host "Update the Environement Variables"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

Write-Host "Create Directories"
$Base_Directory = "c:/users/hashistack"

Write-Host "Installing Consul"
mkdir -p "$Base_Directory/consul"
$ZIP = "$Base_Directory/consul/consul.zip"
(New-Object System.Net.WebClient).DownloadFile("https://releases.hashicorp.com/consul/${c}/consul_${c}_windows_amd64.zip", $ZIP)
Expand-Archive $ZIP -DestinationPath "c:\windows\system32"
Remove-Item $ZIP

Write-Host "Installing BIND"
& c:\temp\bind.ps1

Write-Host "Installing Nomad"
mkdir -p "$Base_Directory/nomad/config"
$ZIP = "$Base_Directory/nomad/nomad.zip"
(New-Object System.Net.WebClient).DownloadFile("https://releases.hashicorp.com/nomad/${n}/nomad_${n}_windows_amd64.zip", $ZIP)
Expand-Archive $ZIP -DestinationPath "c:\windows\system32"
Remove-Item $ZIP

Write-Host "Installing IIS Plugin"
mkdir -p "$Base_Directory/nomad/plugins"
$GOPATH = "$Base_Directory/go"
mkdir -p $GOPATH/src/github.com/Roblox
cd $GOPATH/src/github.com/Roblox
Write-Host "Cloning IIS Plugin"
git clone https://github.com/Roblox/nomad-driver-iis.git
cd nomad-driver-iis
Write-Host "Building IIS Plugin"
make build
Write-Host "Copying IIS Plugin"
cp win_iis.exe "$Base_Directory/nomad/plugins/"

Write-Host "Installing Nuget and Trust the Powershell Gallery"
Install-PackageProvider -Name NuGet -Force
Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

Write-Host "Remove Windows Defender"
Remove-WindowsFeature Windows-Defender