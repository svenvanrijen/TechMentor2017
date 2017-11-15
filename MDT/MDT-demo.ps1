Set-Location -Path "C:\Users\rijen002\OneDrive\TechMentor 2017\MDT"

#region Install MDT & ADK

.\MicrosoftDeploymentToolkit_x64.msi

.\adksetup.exe

#endregion Install MDT & AKD

#region create MDT Build Lab

psedit .\MDTBuildLab\Source\CreateMDTBuildLabShare.ps1

Set-Location -Path "C:\Users\rijen002\OneDrive\TechMentor 2017\MDT\MDTBuildLab\Source"

.\CreateMDTBuildLabShare.ps1

#endregion create MDT Build Lab

#region Imagefactory

psedit C:\setup\ImageFactoryV3ForHyper-V\ImageFactoryV3.xml

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

C:\setup\ImageFactoryV3ForHyper-V\ImageFactoryV3-Build.ps1 -UpdateBootImage $false -Verbose

#region Create Hydration Deployment Share

psedit .\HydrationTechMentor2017\Source\CreateHydrationDeploymentShare.ps1

#endregion Create Hydration Deployment Share

#Build HydrationDeploymentShare

Set-Location -Path "C:\Users\rijen002\OneDrive\TechMentor 2017\MDT\HydrationTechMentor2017\Source"

.\CreateHydrationDeploymentShare.ps1

#region Configure Hydration Share

Copy-Item -Path "C:\MDTBuildLab\ds\Captures\REFWS2016-001.wim" `
          -Destination "C:\HydrationTechMentor2017\DS\Operating Systems\WS2016\REFWS2016-001.wim" `
          -Force

#Move-Item -Path "C:\MDTBuildLab\ds\Captures\REFWS2016-001.wim" `
#         -Destination "C:\HydrationTechMentor2017\DS\Operating Systems\WS2016\REFWS2016-001.wim" `
#          -Force


#Update Media

C:\Users\rijen002\OneDrive\TechMentor 2017\MDT\background.bmp

#show config settings
psedit .\Media\Control\CustomSettings_DC01.ini
          
#endregion Configure Hydration Share

#region Build DC01

#in GUI

#DC01
# C:\VMs\
#2048MB
#Gen2
#Default Switch
#100GB
# C:\HydrationTechMentor2017\ISO
#Start VM

#endregion Build DC01

#region Cleanup

Set-Location -Path "C:\Users\rijen002\OneDrive\TechMentor 2017\MDT"

.\RemoveMDTShares.ps1

#endregion Cleanup