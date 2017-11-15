Set-Location "C:\Users\rijen002\OneDrive\TechMentor 2017\NewLabEnvironment"

#region Add AzureRM module

Find-Module -Name *azurerm*

Install-Module -Name AzureRM -Force

#endregion Add AzureRM module

#region Add 'old' Azure module

#Install-Module -Name Azure -AllowClobber

#endregion Add 'old' Azure module

#region login AzureRM

Login-AzureRmAccount 

#!!Login screen is behind vscode window!!

#endregion login AzureRM

#region define parameters

#Choose region: http://azurespeedtest.azurewebsites.net/

$resourcegroupname = "TechMentor2017"

$location = "East US"

$AutomAccountName = "TechMentor2017"

#endregion define parameters

#region Create AzureRM Resource Group

New-AzureRmResourceGroup -Name $resourcegroupname -Location $location

#endregion Create AzureRM Resource Group

#region Create AzureRM Automation Account

New-AzureRmAutomationAccount -Name $AutomAccountName `
                             -ResourceGroupName $resourcegroupname `
                             -Location $location

#endregion Create AzureRM Automation Account

#region Get AzureRM Registration Info

Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $resourcegroupname `
                                      -AutomationAccountName $AutomAccountName

#endregion Get AzureRM Registration Info

#region Open & Edit meta config AzureDSCPullConfig.ps1

psEdit .\AzureDSCPullConfig.ps1

psEdit .\TechMentor2017DSCPullConfig.ps1

# Save with different file name!

# Edit RegURL & RegKey

#endregion Open & Edit meta config AzureDSCPullConfig.ps1

#region Open & Edit node config TestConfig.ps1

psEdit .\TestConfig.ps1

psEdit .\TechMentor2017.ps1

# Save with different file name!
# Edit NodeConfig in Meta Pull Config

# Make sure DSC Resources/modules are on local workstation while editing

Install-Module -Name xActiveDirectory, `
                     xNetworking, `
                     xDnsServer, `
                     xPendingReboot, `
                     xDHCPServer, `
                     xPSDesiredStateConfiguration

#endregion Open & Edit node config TestConfig.ps1

#region Add admin creds to Azure Automation

#Add-AzureAccount

#New-AzureAutomationAccount -Name $AutomAccountName -Location $location

$user = "TechMentor2017.com\Administrator"

$pw = ConvertTo-SecureString "P@ssW0rd" -AsPlainText -Force

$cred = New-Object –TypeName System.Management.Automation.PSCredential `
                   –ArgumentList $user, $pw

New-AzureRMAutomationCredential -Name "Local domain admin" `
                                -Value $cred `
                                -AutomationAccountName $AutomAccountName `
                                -ResourceGroupName $resourcegroupname
                                

#endregion Add admin creds to Azure Automation

#region Add modules to Azure Automation modules store

# Make sure DSC Resources/modules are in the online modules store

Install-Script -Name Import-ModuleFromPSGalleryToAutomation

$modules = @("xActiveDirectory", `
             "xNetworking", `
             "xDnsServer", `
             "xPendingReboot", `
             "xDHCPServer", `
             "xPSDesiredStateConfiguration")

foreach ($module in $modules) {
  
  Import-ModuleFromPSGalleryToAutomation.ps1 -ResourceGroupName $resourcegroupname `
                                             -AutomationAccountName $AutomAccountName `
                                             -ModuleName $module `
                                             -Verbose

}

#endregion Add modules to Azure Automation modules store

#region upload config

#Login-AzureRmAccount

Import-AzureRmAutomationDscConfiguration -SourcePath "C:\Users\rijen002\OneDrive\TechMentor 2017\NewLabEnvironment\TechMentor2017.ps1" `
                                         -Published `
                                         -ResourceGroupName $resourcegroupname `
                                         -AutomationAccountName $AutomAccountName `
                                         -Force

#endregion

#region compile config

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = "*"             
            DomainName = "techmentor2017.com"             
            RetryCount = 20              
            RetryIntervalSec = 30
            ConfigurationMode = 'ApplyAndAutoCorrect'            
            PsDscAllowPlainTextPassword = $true
          }

        @{             
        Nodename = "DC01"             
        Role = "Primary DC"             
        DomainName = "techmentor2017.com"             
        RetryCount = 20              
        RetryIntervalSec = 30            
        PsDscAllowPlainTextPassword = $true
        PsDscAllowDomainUser = $true        
       }
     )
}

Start-AzureRmAutomationDscCompilationJob -ResourceGroupName "TechMentor2017" `
                                                           -AutomationAccountName "TechMentor2017" `
                                                           -ConfigurationName "TechMentor2017" `
                                                           -ConfigurationData $ConfigData

#endregion compile config

#region Get Job status

Get-AzureRmAutomationJob -Id <ID> `
                         -ResourceGroupName $resourcegroupname `
                         -AutomationAccountName $AutomAccountName

#endregion Get Job status

#region Get DSC Node Configs

Get-AzureRmAutomationDscNodeConfiguration -ResourceGroupName $resourcegroupname `
                                      -AutomationAccountName $AutomAccountName

#endregion Get DSC Node Configs

#region Install New-LabEnvironment

Install-Module NewLabEnvironment

#endregion Install New-LabEnvironment

#region Open New-LabVM module

psEdit "C:\Program Files\WindowsPowershell\Modules\NewLabEnvironment\2.4\New-LabVM.psm1"

#endregion Open New-LabVM module

#region Create NATSwitch

New-NATSwitch -Name TechMentor2017 `
              -IPAddress 10.0.1.1 `
              -PrefixLength 24 `
              -NATName TechMentor `
              -Verbose

#endregion Create NATSwitch

#region Create DC01

New-LabVM -VMName DC01 `
          -VMIP 10.0.1.100 `
          -GWIP 10.0.1.1 `
          -diskpath "C:\vhdx\" `
          -ParentDisk "C:\VMs\Server2016Template\Virtual Hard Disks\Server2016Template.vhdx" `
          -VMSwitch TechMentor2017 `
          -DNSIP 8.8.8.8 `
          -DSC $true `
          -DSCPullConfig "C:\Users\rijen002\OneDrive\TechMentor 2017\NewLabEnvironment\TechMentor2017DSCPullConfig.ps1" `
          -NestedVirt $false `
          -Unattendloc "C:\users\rijen002\OneDrive\TechMentor 2017\NewLabEnvironment\unattend.xml" `
          -Verbose

#endregion Create DC01

#region Logon to DC01

#password: P@ssW0rd

#endregion Logon to DC01

#region Cleanup

Stop-VM DC01

Remove-VM DC01

Remove-Item -Path "C:\vhdx\DC01.vhdx"

Remove-VMSwitch -Name "TechMentor2017" -Force

Remove-NetNat -Name "TechMentor"

Remove-AzureRmResourceGroup -Name $resourcegroupname

Remove-Item -Path "C:\Program Files\WindowsPowerShell\Modules\NewLabEnvironment\" -Force 

#endregion Cleanup