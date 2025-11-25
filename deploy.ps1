# Script untuk prepare deployment
Write-Host "Cleaning old web-deploy folder..."
if (Test-Path "web-deploy") {
    Remove-Item -Recurse -Force web-deploy
}

Write-Host "Creating web-deploy folder..."
New-Item -ItemType Directory -Force -Path web-deploy | Out-Null

Write-Host "Copying build/web contents to web-deploy..."
Copy-Item -Path "build/web/*" -Destination "web-deploy/" -Recurse -Force

Write-Host "Copying vercel.json to web-deploy..."
Copy-Item -Path "vercel.json" -Destination "web-deploy/vercel.json" -Force

Write-Host "`nDeployment folder ready at: web-deploy/"
Write-Host "Files copied:"
Get-ChildItem web-deploy -Name
