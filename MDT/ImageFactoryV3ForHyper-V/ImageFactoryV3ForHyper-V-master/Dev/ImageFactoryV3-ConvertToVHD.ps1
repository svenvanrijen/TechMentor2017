$DateTime = (Get-Date).ToString('yyyyMMdd')
$CaptureFolder = "D:\MDTBuildLab\Captures"
$VHDxFolder = "C:\Setup\VHD\$DateTime"
$UEFI = $true
$BIOS = $false
New-Item -Path $VHDxFolder -ItemType Directory -Force

$wims = Get-ChildItem -Path $CaptureFolder -Filter *.wim
foreach($wim in $wims){
    $WindowsImage = Get-WindowsImage -ImagePath $wim.FullName
    if ($WindowsImage.ImageDescription -ne ""){
        $ImageName = $WindowsImage.ImageDescription
    }else{
        $ImageName = $wim.BaseName
    }

    Write-Host "Working on $ImageName"
    if($UEFI -eq $True){
        #Create UEFI VHDX files
        $DestinationFile =  $VHDxFolder + "\" + $ImageName + "_UEFI.vhdx"
        if((Test-Path -Path $DestinationFile) -ne $true){
            Write-Host "About to create $DestinationFile"
            C:\Setup\ImageFactoryV3ForHyper-V\Convert-VIAWIM2VHD.ps1 -SourceFile $SourceFile -DestinationFile $DestinationFile -Disklayout UEFI -SizeInMB 80000 -Index 1
        }else{
            Write-Host "$DestinationFile already exists"
        }
    }

    if($BIOS -eq $True){
        #Create BIOS VHDX files
        $DestinationFile =  $VHDxFolder + "\" + $ImageName + "_BIOS.vhdx"
        if((Test-Path -Path $DestinationFile) -ne $true){
            Write-Host "About to create $DestinationFile"
            C:\Setup\ImageFactoryV3ForHyper-V\Convert-VIAWIM2VHD.ps1 -SourceFile $SourceFile -DestinationFile $DestinationFile -Disklayout BIOS -SizeInMB 80000 -Index 1
        }else{
            Write-Host "$DestinationFile already exists"
        }
    }
}
