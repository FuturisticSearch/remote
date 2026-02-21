# ------------------------------
# Remote VNC Installer + Autorun with Logging
# ------------------------------

# Auto-elevate
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"

# Installer base
$installerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Join-Path $installerDir "remote"
$logFile = Join-Path $installerDir "installer-log.txt"

# Function to log messages
function Log {
    param([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$time] $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

Log "=== Remote VNC Installer Started ==="

# ------------------------------
# Clone repository
# ------------------------------
if (-not (Test-Path (Join-Path $repoDir ".git"))) {
    Log "Cloning repository..."
    git clone https://github.com/FuturisticSearch/remote $repoDir | Out-Null
} else {
    Log "Repository already cloned."
}

# ------------------------------
# Node.js check
# ------------------------------
$nodeCheck = Get-Command node -ErrorAction SilentlyContinue
$npmCheck  = Get-Command npm  -ErrorAction SilentlyContinue

if (-not $nodeCheck -or -not $npmCheck) {
    Log "Node.js not found. Installing Node.js LTS via winget..."
    Start-Process -FilePath "winget" -ArgumentList "install OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
} else {
    Log "Node.js already installed."
}

# ------------------------------
# Install websockify globally
# ------------------------------
try {
    Log "Installing websockify globally..."
    & npm install -g @maximegris/node-websockify 2>&1 | ForEach-Object { Log $_ }
    Log "Websockify installed."
} catch {
    Log "Failed to install websockify: $_"
}

# ------------------------------
# TightVNC
# ------------------------------
$tvncCheck = Get-Command tvnserver -ErrorAction SilentlyContinue
if (-not $tvncCheck) {
    Log "Installing TightVNC..."
    $tvncUrl = "https://www.tightvnc.com/download/2.8.81/tightvnc-2.8.81-gpl-setup-64bit.msi"
    $tvncInstaller = Join-Path $env:TEMP "tightvnc.msi"
    Invoke-WebRequest -Uri $tvncUrl -OutFile $tvncInstaller
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tvncInstaller`" /quiet /norestart" -Wait -NoNewWindow
    Remove-Item $tvncInstaller -Force
    Log "TightVNC installed."
} else {
    Log "TightVNC already installed."
}

# ------------------------------
# Nginx
# ------------------------------
$nginxDir = "C:\nginx"
if (-not (Test-Path (Join-Path $nginxDir "nginx.exe"))) {
    Log "Installing Nginx..."
    $nginxZipUrl = "http://nginx.org/download/nginx-1.26.1.zip"
    $nginxZip = Join-Path $env:TEMP "nginx.zip"
    $tempExtract = Join-Path $env:TEMP "nginx_temp"
    Invoke-WebRequest -Uri $nginxZipUrl -OutFile $nginxZip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($nginxZip, $tempExtract)
    $subFolder = Get-ChildItem -Path $tempExtract | Where-Object {$_.PSIsContainer} | Select-Object -First 1
    if (-not (Test-Path $nginxDir)) { New-Item -ItemType Directory -Force -Path $nginxDir | Out-Null }
    Get-ChildItem $subFolder.FullName | ForEach-Object { Move-Item -Path $_.FullName -Destination $nginxDir -Force }
    Remove-Item $nginxZip, $tempExtract -Recurse -Force
    Log "Nginx installed."
} else {
    Log "Nginx already installed."
}

# ------------------------------
# Task Scheduler autorun
# ------------------------------
$runBat = Join-Path $repoDir "vnc.bat"
$taskName = "RemoteVNC_Autorun"
$taskExists = schtasks /Query /TN $taskName 2>$null
if (-not $taskExists) {
    Log "Creating scheduled task for vnc.bat..."
    schtasks /Create /TN $taskName /TR "`"$runBat`"" /SC ONSTART /RL HIGHEST /F
    Log "Scheduled task created."
} else {
    Log "Scheduled task already exists."
}

# ------------------------------
# Run vnc.bat immediately
# ------------------------------
if (Test-Path $runBat) {
    Log "Starting vnc.bat..."
    Start-Process -FilePath $runBat -WindowStyle Hidden
    Log "vnc.bat started. Setup complete."
} else {
    Log "Error: vnc.bat not found in repo folder!"
}

Log "=== Remote VNC Installer Finished ==="