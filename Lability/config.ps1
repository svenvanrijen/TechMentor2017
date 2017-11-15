# Config.ps1

# Stop the script if a fatal error occurs
$ErrorActionPreference = 'Stop'

Configuration DC01 {
    param (
        [ValidateNotNull()]
        [PSCredential]$Credential = (Get-Credential -Credential 'Administrator')
    )

    # Remember, these modules are required on the host as that's where the .MOFs are compiled,
    # and the modules are also copied across to our VMs as that's where they are applied
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking, xActiveDirectory
    Import-DscResource -ModuleName xDHCPServer, xDnsServer

    #
    # ALL nodes
    #
    Write-Verbose 'Processing: All nodes'
    Node $AllNodes.Where({ $true }).NodeName {

        Write-Verbose "Processing:   $($node.NodeName)"

        # LCM settings
        LocalConfigurationManager {
            RebootNodeIfNeeded   = $true
            AllowModuleOverwrite = $true
            ConfigurationMode    = 'ApplyOnly'
            CertificateID       = $node.Thumbprint
        }

        #
        # Networking
        #
        # If an IP address was defined in our config file, set the adapter's IP address
        if ($node.IPAddress) {
            xIPAddress 'IPAddress' {
                IPAddress      = $node.IPAddress
                InterfaceAlias = 'Ethernet'
                AddressFamily  = $node.AddressFamily
            }
        }

        # If a default gateway was defined in our config file, set it
        if ($node.DefaultGateway) {
            xDefaultGatewayAddress 'PrimaryDefaultGateway' {
                InterfaceAlias = 'Ethernet'
                Address        = $node.DefaultGateway
                AddressFamily  = $node.AddressFamily
            }
        }

        # If a DNS server was defined in our config file, set it
        if ($node.DnsServerAddress) {
            xDnsServerAddress 'PrimaryDNSClient' {
                Address        = $node.DnsServerAddress
                InterfaceAlias = 'Ethernet'
                AddressFamily  = $node.AddressFamily
            }
        }

        # If a DCS connection suffix was defined in our config file, set it
        if ($node.DnsConnectionSuffix) {
            xDnsConnectionSuffix 'PrimaryConnectionSuffix' {
                InterfaceAlias           = 'Ethernet'
                ConnectionSpecificSuffix = $node.DnsConnectionSuffix
            }
        }

    } #end nodes ALL

    #
    # DC nodes
    #
    Write-Verbose "Processing: DC nodes"
    Node $AllNodes.Where({ $_.Role -eq 'DC' }).NodeName {
        Write-Verbose "Processing:   $($node.NodeName)"

        #
        # Roles
        #
        # Add the following roles
        ForEach ($Feature in @(
            'AD-Domain-Services',
            'GPMC',
            'RSAT-AD-Tools',
            'DHCP',
            'RSAT-DHCP'
        )) {
            WindowsFeature $Feature.Replace('-','') {
                Ensure = 'Present'
                Name = $Feature
                IncludeAllSubFeature = $true
            }
        }

        #
        # Active Directory
        #
        # Create the AD domain
        xADDomain 'ADDomain' {
            DomainName                    = $node.DomainName
            SafemodeAdministratorPassword = $Credential
            DomainAdministratorCredential = $Credential
            DependsOn                     = '[WindowsFeature]ADDomainServices'
        }

        # DHCP server
        xDhcpServerAuthorization 'DhcpServerAuthorization' {
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]DHCP','[xADDomain]ADDomain'
        }

        # Create a DCHP scope from 10.0.0.100 - 10.0.0.200
        xDhcpServerScope 'DhcpScope10_0_0_0' {
            Name          = 'Lab Clients'
            IPStartRange  = '10.0.0.100'
            IPEndRange    = '10.0.0.200'
            SubnetMask    = '255.255.255.0'
            LeaseDuration = '00:08:00'
            State         = 'Active'
            AddressFamily = 'IPv4'
            DependsOn     = '[WindowsFeature]DHCP'
        }

        # Add the 'Router' option to the DHCP scope, which defines the default gateway
        xDhcpServerOption 'DhcpScope10_0_0_0_Option' {
            ScopeID            = '10.0.0.0'
            DnsDomain          = $node.DomainName
            DnsServerIPAddress = '10.0.0.1'
            Router             = '10.0.0.254'
            AddressFamily      = 'IPv4'
            DependsOn          = '[xDhcpServerScope]DhcpScope10_0_0_0'
        }

    } #end nodes DC

   
}

# Use the Data.psd1 in the same folder as this script
$ConfigData = ".\data.psd1"

# Create a new credential that we'll pass to BasicServerClient (Required when creating the domain & joining the domain) and to Start-LabConfiguration
$AdministratorCredential = [pscredential]::new('Administrator', ('P@ssW0rd' | ConvertTo-SecureString -AsPlainText -Force))

# Generate the .MOF files that will be injected into our VMs and used to set them up
Write-Host 'Generating MOFs' -ForegroundColor Green
DC01 -ConfigurationData $ConfigData -OutputPath 'C:\Lability\Configurations' -Credential $AdministratorCredential -Verbose

# Verify lab configuration & see what parts of it already exist (if any)
Write-Host 'Verifying lab configuration' -ForegroundColor Green
Test-LabConfiguration -ConfigurationData $ConfigData  -Verbose

# Create the lab from our config
Write-Host 'Creating lab' -ForegroundColor Green
Start-LabConfiguration -ConfigurationData $ConfigData -Verbose -IgnorePendingReboot -Credential $AdministratorCredential

# And once it's created, start the lab environment
Write-Host 'Starting lab!' -ForegroundColor Green
Start-Lab -ConfigurationData $ConfigData -Verbose