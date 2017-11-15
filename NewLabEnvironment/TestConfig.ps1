configuration TechMentor2017_domain
 {
     Node WebServer
     {
         WindowsFeature IIS
         {
             Ensure               = 'Present'
             Name                 = 'Web-Server'
             IncludeAllSubFeature = $true

         }
     }

     Node NotWebServer
     {
         WindowsFeature IIS
         {
             Ensure               = 'Absent'
             Name                 = 'Web-Server'

         }
     }
     }