Set-Location "C:\Users\rijen002\OneDrive\TechMentor 2017\Lability"

#region Installation Lability

Install-Module -Name "Lability"


#endregion Installation Lability

#region Configure Lability

Get-Command -Module Lability


$LabHostParameters = @{
    ParentVhdPath = 'C:\Lability\MasterVirtualHardDisks'
    DifferencingVhdPath = 'C:\Lability\VMVirtualHardDisks'
    IsoPath = 'C:\Lability\ISOs'
    ConfigurationPath = 'C:\Lability\'
    HotfixPath = 'C:\Lability\Hotfixes'
    ResourcePath = 'C:\Lability\Resources'
    ModuleCachePath = 'C:\Lability\Modules'
}    

Set-LabHostDefault $LabHostParameters

Set-LabHostDefault -ConfigurationPath "C:\Lability\Configurations"

#Check HKLM\SYSTEM\CurrentControlSet\Control\Session Manager

Start-LabHostConfiguration

Test-LabHostConfiguration

Get-LabVMDefault

Get-LabMedia | Format-Table ImageName,Id

$LabDefaultVMParameters = @{
    InputLocale = 'en-US'
    SystemLocale = 'en-US'
    ProcessorCount = '1'
    StartupMemory = '2147483648'
    RegisteredOwner = 'Sven van Rijen'
    TimeZone = 'Eastern Standard Time'
    SwitchName = 'TechMentor2017'
    Media = "2016_x64_Standard_EN_Eval"
}

Set-LabVMDefault @LabDefaultVMParameters

#endregion Configure Lability

#region Create config

psedit .\config.ps1

psedit .\data.psd1

#endregion Create config

#region Start-Labconfig

.\config.ps1

#endregion Start-Labconfig

#region cleanup

Stop-Lab -ConfigurationData .\data.psd1

Remove-LabVM -Name DC01 -ConfigurationData .\data.psd1

Remove-VMSwitch -Name TechMentor2017 -Force

Get-NetNat | Remove-NetNat -Verbose

#endregion cleanup