# ------------------------------
# Remote VNC Installer + Autorun
# ------------------------------

Write-Host "=== Remote VNC Installer + Autorun ===" -ForegroundColor Cyan

# Base installer folder
$installerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Join-Path $installerDir "remote"

# ------------------------------
# Clone GitHub repository
# ------------------------------
Write-Host "Cloning repository..."
if (-not (Test-Path (Join-Path $repoDir ".git"))) {
    git clone https://github.com/FuturisticSearch/remote $repoDir
} else {
    Write-Host "Repository already cloned."
}

# ------------------------------
# Download Node.js LTS portable
# ------------------------------
$nodeZipUrl = "https://nodejs.org/dist/v20.6.1/node-v20.6.1-win-x64.zip"
$nodeZipPath = Join-Path $installerDir "node.zip"
$nodeDir = Join-Path $installerDir "node"

Write-Host "Downloading Node.js..."
Invoke-WebRequest -Uri $nodeZipUrl -OutFile $nodeZipPath

Write-Host "Extracting Node.js..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($nodeZipPath, $nodeDir)
Remove-Item $nodeZipPath
Write-Host "Node.js installed to $nodeDir"

$nodeExe = Join-Path $nodeDir "node.exe"
$npmExe = Join-Path $nodeDir "npm.cmd"

# ------------------------------
# Install websockify globally
# ------------------------------
Write-Host "Installing websockify..."
Start-Process -FilePath $nodeExe -ArgumentList "$npmExe install -g @maximegris/node-websockify" -Wait

# ------------------------------
# Install TightVNC
# ------------------------------
$tvncUrl = "https://www.tightvnc.com/download/2.8.81/tightvnc-2.8.81-gpl-setup-64bit.msi"
$tvncInstaller = Join-Path $installerDir "tightvnc.msi"

Write-Host "Downloading TightVNC..."
Invoke-WebRequest -Uri $tvncUrl -OutFile $tvncInstaller

Write-Host "Installing TightVNC silently..."
Start-Process msiexec.exe -ArgumentList "/i `"$tvncInstaller`" /quiet /norestart" -Wait

# ------------------------------
# Install Nginx
# ------------------------------
$nginxZipUrl = "http://nginx.org/download/nginx-1.26.1.zip"
$nginxZip = Join-Path $installerDir "nginx.zip"
$nginxDir = Join-Path $installerDir "nginx"
$tempExtract = Join-Path $installerDir "nginx_temp"

Write-Host "Downloading Nginx..."
Invoke-WebRequest -Uri $nginxZipUrl -OutFile $nginxZip

Write-Host "Extracting Nginx..."
[System.IO.Compression.ZipFile]::ExtractToDirectory($nginxZip, $tempExtract)

# Move extracted files up one level to nginx folder
$subFolder = Get-ChildItem -Path $tempExtract | Where-Object {$_.PSIsContainer} | Select-Object -First 1
Get-ChildItem $subFolder.FullName | ForEach-Object { Move-Item -Path $_.FullName -Destination $nginxDir -Force }

# Cleanup temp files
Remove-Item $nginxZip, $tempExtract -Recurse -Force
Write-Host "Nginx installed to $nginxDir"

# ------------------------------
# Task Scheduler autorun
# ------------------------------
$runBat = Join-Path $repoDir "run.bat"
$taskName = "RemoteVNC_Autorun"
$taskExists = schtasks /Query /TN $taskName 2>$null

if (-not $taskExists) {
    Write-Host "Creating scheduled task for run.bat on system startup..."
    schtasks /Create /TN $taskName /TR "`"$runBat`"" /SC ONSTART /RL HIGHEST /F
    Write-Host "Scheduled task created: $taskName"
} else {
    Write-Host "Scheduled task already exists."
}

# ------------------------------
# Run run.bat immediately
# ------------------------------
Write-Host "Starting run.bat now..."
Start-Process -FilePath $runBat -WindowStyle Hidden
Write-Host "run.bat started hidden. Setup complete."