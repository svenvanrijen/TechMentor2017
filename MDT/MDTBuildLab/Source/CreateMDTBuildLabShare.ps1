<#
.Synopsis
    Sample script for MDT Build Lab
.DESCRIPTION
    Created: 2017-10-18
    Version: 1.0

    Author : Sven van Rijen
    Twitter: @svenvanrijen
    Blog   : http://www.svenvanrijen.nl

    Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the author..
.EXAMPLE
    NA
#>


# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
Write-Warning "Aborting script..."
Break
}

# Verify that MDT 8443 is installed
if (!((Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft Deployment Toolkit (6.3.8443.1000)"}).Displayname).count) {Write-Warning "MDT 8443 not installed, aborting...";Break}

# Verify that Windows ADK 10 v1709 is installed 
if (!((Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Windows Deployment Tools" -and $_.DisplayVersion -eq "10.1.16299.15"}).Displayname).count) {Write-Warning "Windows ADK 10 v1709 is not installed, aborting...";Break}

# Validation, verify that the deployment share doesnt exist already
$RootDrive = "C:"
If (Get-SmbShare | Where-Object { $_.Name -eq "MDTBuildLab$"}){Write-Warning "MDTBuildLab$ share already exist, please cleanup and try again. Aborting...";Break}
if (Test-Path -Path "$RootDrive\MDTBuildLab\DS") {Write-Warning "$RootDrive\MDTBuildLab\DS already exist, please cleanup and try again. Aborting...";Break}


# Validation, verify that the PSDrive doesnt exist already
if (Test-Path -Path "DS002:") {Write-Warning "DS002: PSDrive already exist, please cleanup and try again. Aborting...";Break}

# Check free space on C: - Minimum for the Hydration Kit is 50 GB
$NeededFreeSpace = 50 #GigaBytes
$Disk = Get-wmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" 
$FreeSpace = [MATH]::ROUND($disk.FreeSpace /1GB)
Write-Host "Checking free space on C: - Minimum is $NeededFreeSpace GB"

if($FreeSpace -lt $NeededFreeSpace){

Write-Warning "Oupps, you need at least $NeededFreeSpace GB of free disk space"
Write-Warning "Available free space on C: is $FreeSpace GB"
Write-Warning "Aborting script..."
Write-Host ""
Write-Host "TIP: If you don't have space on C: but have other volumes, say D:, available, " -ForegroundColor Yellow
Write-Host "then copy the MDTBuildLab folder to D: and use mklink to create a synlink on C:" -ForegroundColor Yellow
Write-Host "The syntax is: mklink C:\MDTBuildLab D:\MDTBuildLab /D" -ForegroundColor Yellow
Break
}

# Validation OK, create Hydration Deployment Share
$MDTServer = (get-wmiobject win32_computersystem).Name

Add-PSSnapIn Microsoft.BDD.PSSnapIn -ErrorAction SilentlyContinue 
mkdir C:\MDTBuildLab\DS
new-PSDrive -Name "DS002" -PSProvider "MDTProvider" -Root "C:\MDTBuildLab\DS" -Description "MDT Build Lab" -NetworkPath "\\$MDTServer\MDTBuildLab$" | add-MDTPersistentDrive
New-SmbShare -Name MDTBuildLab$ -Path "C:\MDTBuildLab\DS"  -ChangeAccess EVERYONE

# Add MDT_BA user
$password = ConvertTo-SecureString "P@ssW0rd" -AsPlainText -Force
New-LocalUser -Name "MDT_BA" -Description "MDT User" -Password $password -PasswordNeverExpires

# Configure NTFS Permissions for the MDT Build Lab deployment share
$DeploymentShareNTFS = "C:\MDTBuildLab"
icacls $DeploymentShareNTFS /grant '"Administrators":(OI)(CI)(F)'
icacls $DeploymentShareNTFS /grant '"SYSTEM":(OI)(CI)(F)'
icacls $DeploymentShareNTFS /grant '"MDT_BA":(OI)(CI)(RX)'

# Configure Sharing Permissions for the MDT Build Lab deployment share
$DeploymentShare = "MDTBuildLab$"
Grant-SmbShareAccess -Name $DeploymentShare -AccountName "EVERYONE" -AccessRight Change -Force
Revoke-SmbShareAccess -Name $DeploymentShare -AccountName "CREATOR OWNER" -Force

# Copy sample files to MDT Lab Share
Copy-Item -Path ".\Hydration\Control" -Destination "C:\MDTBuildLab\DS" -Recurse -Force
Copy-Item -Path ".\Hydration\Operating Systems" -Destination "C:\MDTBuildLab\DS" -Recurse -Force
Copy-Item -Path ".\Hydration\Scripts" -Destination "C:\MDTBuildLab\DS" -Recurse -Force
