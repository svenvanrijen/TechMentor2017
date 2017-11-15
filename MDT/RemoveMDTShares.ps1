Remove-PSDrive -Name "DS002" -Force -ErrorAction SilentlyContinue

Remove-SmbShare -Name MDTBuildLab$ -Force

Remove-MDTPersistentDrive -Name "DS002"

Remove-Item -Path "C:\MDTBuildLab\" -Recurse -Force

Remove-LocalUser -Name "MDT_BA"

Remove-PSDrive -Name "DS001" -Force -ErrorAction SilentlyContinue

Remove-SmbShare -Name HydrationTechMentor2017$ -Force

Remove-MDTPersistentDrive -Name "DS001"

Remove-Item -Path "C:\HydrationTechMentor2017\" -Recurse -Force