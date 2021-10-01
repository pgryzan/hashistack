###############################################################################################
#
#   Repo:           /scripts/powershell
#   File Name:      bind.ps1
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           September 2020
#   Description:    This is an installation file for BIND 9 that doesn't require the native
#                   MFC installation application so it runs silently
#
#                   Assume Chocolatey is installed
#
###############################################################################################

Write-Host "Installing BIND 9"
choco feature enable -n allowGlobalConfirmation
choco install vcredist140

Write-Host "Set Registry Keys"
$registryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\ISC\BIND"
$name = "InstallDir"
$value = "C:\Program Files\ISC BIND 9"
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null

$registryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ISC BIND"
$name = "DisplayName"
$value = "ISC BIND"
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null
$name = "UninstallString"
$value = 'C:\Program Files\ISC BIND 9\bin\BINDInstall.exe"'
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null

$registryPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\EventLog\Application\named"
$name = "EventMessageFile"
$value = "C:\Program Files\ISC BIND 9\bin\bindevt.dll"
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null
$name = "TypesSupported"
$value = 7
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null

Write-Host "Download BIND 9"
New-Item -Path "C:/Program Files" -Name "ISC BIND 9" -ItemType "directory" -Force
New-Item -Path "C:/Program Files/ISC BIND 9" -Name "bin" -ItemType "directory" -Force
New-Item -Path "C:/Program Files/ISC BIND 9" -Name "etc" -ItemType "directory" -Force
New-Item -Path "C:/Program Files/ISC BIND 9" -Name "zones" -ItemType "directory" -Force
(New-Object System.Net.WebClient).DownloadFile("https://downloads.isc.org/isc/bind9/9.16.15/BIND9.16.15.x64.zip", "C:/Program Files/ISC BIND 9/bind.zip")
Expand-Archive "C:/Program Files/ISC BIND 9/bind.zip" -DestinationPath "C:/Program Files/ISC BIND 9/bin"
cd "C:/Program Files/ISC BIND 9/bin"

Write-Host "Generate Key rndc.conf"
.\rndc-confgen.exe -a
[System.IO.File]::WriteAllLines("C:/Program Files/ISC BIND 9/etc/rndc.conf", (.\rndc-confgen.exe | Out-String))

Write-Host "Create named.conf"
[System.IO.File]::WriteAllLines("C:/Program Files/ISC BIND 9/etc/named.conf", (Select-String -Path "C:/Program Files/ISC BIND 9/etc/rndc.conf" -Pattern '# key' -Context 0, 8 | ForEach-Object {
    $($_.Line; $_.Context.PostContext) -replace "# ", "" | Out-String
}))

Add-Content -Path "C:/Program Files/ISC BIND 9/etc/named.conf" -Encoding utf8 -Value @"
options {
    listen-on port 53 { 127.0.0.1; };
    listen-on-v6 port 53 { ::1; };
    directory       "C:/Program Files/ISC BIND 9";
    dump-file       "C:/Program Files/ISC BIND 9/data/cache_dump.db";
    statistics-file "C:/Program Files/ISC BIND 9/data/named_stats.txt";
    memstatistics-file "C:/Program Files/ISC BIND 9/data/named_mem_stats.txt";
    allow-query     { localhost; };
    recursion yes;
  
    dnssec-enable no;
    dnssec-validation no;
};

include "C:/Program Files/ISC BIND 9/zones/consul.conf";
"@

Write-Host "Create consul.conf"
[System.IO.File]::WriteAllLines("C:/Program Files/ISC BIND 9/zones/consul.conf", (@"
zone "consul" IN {
    type forward;
    forward only;
    forwarders { 127.0.0.1 port 8600; };
};
"@))

sc.exe create "ISC BIND" binPath= "C:/Program Files/ISC BIND 9/bin/named.exe" DisplayName= "ISC BIND 9" start= auto
sc.exe start "ISC BIND"

Write-Host "Set BIND 9 Path"
$newpath = [System.Environment]::GetEnvironmentVariable('PATH','machine') + ';C:/Program Files/ISC BIND 9;C:/Program Files/ISC BIND 9/bin;C:/Program Files/ISC BIND 9/etc;'
[System.Environment]::SetEnvironmentVariable('PATH', $newpath,[System.EnvironmentVariableTarget]::Machine)

Write-Host "Set Ethernet DNS to Point to BIND"
netsh interface ipv4 set dnsserver "Ethernet" static 127.0.0.1 primary