# Data.psd1

@{
    AllNodes = @(
        # All nodes
        @{
            NodeName                  = '*'
            DomainName                = 'TechMentor2017.com'

            # Networking
            Lability_SwitchName       = 'TechMentor2017'
            DefaultGateway            = '10.0.1.254'
            SubnetMask                = 24
            AddressFamily             = 'IPv4'
            DnsServerAddress          = '10.0.0.1'
            DnsConnectionSuffix       = 'TechMentor2017.com'

            # DSC related
            CertificateFile = "$env:AllUsersProfile\Lability\Certificates\LabClient.cer"
            Thumbprint = '5940d7352ab397bfb2f37856aa062bb471b43e5e'

        }

        # DC01
        @{
            # Basic details
            NodeName                  = 'DC01'
            Lability_ProcessorCount   = 2
            Role                      = 'DC'
            Lability_Media            = '2016_x64_Standard_EN_Eval'

            # Networking
            IPAddress                 = '10.0.0.1'
            DnsServerAddress          = '127.0.0.1'

            # Lability extras
            Lability_CustomBootstrap  = @'

'@
        }

    )

    NonNodeData = @{
        OrganisationName = 'TechMentor2017'

        Lability = @{
            DSCResource = @(
            @{ Name = 'xComputerManagement'; MinimumVersion = '1.3.0.0'; Provider = 'PSGallery' }
            @{ Name = 'xNetworking'; MinimumVersion = '2.7.0.0' }
            @{ Name = 'xActiveDirectory'; MinimumVersion = '2.9.0.0' }
            @{ Name = 'xDnsServer'; MinimumVersion = '1.5.0.0' }
            @{ Name = 'xDhcpServer'; MinimumVersion = '1.3.0.0' }
            )

            Media = @()

        }
    }
}