# Windows SSH Setup Script for Pop!_OS Connection
# Run as Administrator: powershell -ExecutionPolicy Bypass -File windows_ssh_setup.ps1

Write-Host "=== Windows SSH Setup ===" -ForegroundColor Green

# 1. Check mDNS support
Write-Host "1. Checking mDNS (Bonjour) service..." -ForegroundColor Yellow
$bonjourService = Get-Service -Name "Bonjour Service" -ErrorAction SilentlyContinue
if ($bonjourService) {
    Write-Host "   Bonjour service found." -ForegroundColor Green
} else {
    Write-Host "   Bonjour service not found. Consider installing iTunes or Bonjour Print Services." -ForegroundColor Yellow
}

# 2. Setup SSH config
Write-Host "`n2. Setting up SSH config..." -ForegroundColor Yellow
$sshConfigPath = "$env:USERPROFILE\.ssh\config"
$sshDir = "$env:USERPROFILE\.ssh"

# Create .ssh directory
if (!(Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    Write-Host "   Created .ssh directory" -ForegroundColor Green
}

# Backup existing config
if (Test-Path $sshConfigPath) {
    $backupPath = "$sshConfigPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $sshConfigPath $backupPath
    Write-Host "   Backed up existing config: $backupPath" -ForegroundColor Green
}

# Create SSH config
$sshConfig = @"
# Pop!_OS ArtifexPro Server
Host popOS popOS-artifex popOS-artifex.local
    HostName popOS-artifex.local
    User stevenlim
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Direct IP connection (update IP as needed)
Host popOS-ip
    HostName 192.168.1.100
    User stevenlim
    Port 22
"@

$sshConfig | Out-File -FilePath $sshConfigPath -Encoding UTF8 -Force
Write-Host "   SSH config created/updated" -ForegroundColor Green

# 3. Create PowerShell functions
Write-Host "`n3. Adding PowerShell functions..." -ForegroundColor Yellow

$profileContent = @'

# Pop!_OS SSH Connection Function
function Connect-PopOS {
    Write-Host "Connecting to Pop!_OS..." -ForegroundColor Green
    
    # Try mDNS first
    Write-Host "1. Trying mDNS (popOS-artifex.local)..." -ForegroundColor Yellow
    ssh -o ConnectTimeout=5 popOS-artifex.local 2>$null
    if ($LASTEXITCODE -eq 0) { return }
    
    # Try hostname
    Write-Host "2. Trying hostname (popOS)..." -ForegroundColor Yellow
    ssh -o ConnectTimeout=5 popOS 2>$null
    if ($LASTEXITCODE -eq 0) { return }
    
    # Scan network
    Write-Host "3. Scanning network for Pop!_OS..." -ForegroundColor Yellow
    $subnet = "192.168.1"
    for ($i = 100; $i -le 110; $i++) {
        $ip = "$subnet.$i"
        Write-Host "   Checking $ip..." -NoNewline
        $result = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($result) {
            Write-Host " Found!" -ForegroundColor Green
            Write-Host "   Trying SSH: $ip" -ForegroundColor Cyan
            ssh stevenlim@$ip
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`nSuccess! Consider updating hosts file for faster connection." -ForegroundColor Green
                return
            }
        } else {
            Write-Host " No response" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nConnection failed. Check if Pop!_OS is running and on the same network." -ForegroundColor Red
}

# Alias
Set-Alias -Name popOS -Value Connect-PopOS

# Find Pop!_OS IP
function Find-PopOS {
    Write-Host "Searching for Pop!_OS on network..." -ForegroundColor Green
    $subnet = "192.168.1"
    
    for ($i = 1; $i -le 254; $i++) {
        $ip = "$subnet.$i"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            Write-Host "Device found: $ip" -ForegroundColor Yellow
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            try {
                $tcpClient.ConnectAsync($ip, 22).Wait(100) | Out-Null
                if ($tcpClient.Connected) {
                    Write-Host "  -> SSH server found! $ip" -ForegroundColor Green
                    $tcpClient.Close()
                    return $ip
                }
            } catch {}
        }
    }
    
    Write-Host "No SSH servers found." -ForegroundColor Red
}
'@

# Update PowerShell profile
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$existingProfile = Get-Content $PROFILE -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch "popOS" }
($existingProfile -join "`n") + "`n" + $profileContent | Set-Content $PROFILE -Encoding UTF8

Write-Host "   PowerShell profile updated" -ForegroundColor Green

# 4. Create desktop shortcut
Write-Host "`n4. Creating desktop shortcut..." -ForegroundColor Yellow

$desktopPath = [Environment]::GetFolderPath("Desktop")
$batchContent = @'
@echo off
title Pop!_OS SSH Connection
echo === Pop!_OS SSH Connection ===
echo.

echo [1] Trying mDNS (popOS-artifex.local)...
ssh -o ConnectTimeout=5 stevenlim@popOS-artifex.local
if %errorlevel% == 0 goto :end

echo [2] Trying SSH config (popOS)...
ssh -o ConnectTimeout=5 popOS
if %errorlevel% == 0 goto :end

echo [3] Trying direct IP...
ssh stevenlim@192.168.1.100

:end
pause
'@

$batchPath = "$desktopPath\Connect_PopOS.bat"
$batchContent | Out-File -FilePath $batchPath -Encoding ASCII
Write-Host "   Created: Connect_PopOS.bat" -ForegroundColor Green

# 5. Display instructions
Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Connection methods:" -ForegroundColor Cyan
Write-Host "1. PowerShell: popOS or Connect-PopOS" -ForegroundColor White
Write-Host "2. CMD/PowerShell: ssh popOS" -ForegroundColor White
Write-Host "3. Desktop: Double-click Connect_PopOS.bat" -ForegroundColor White
Write-Host ""
Write-Host "To find Pop!_OS IP:" -ForegroundColor Cyan
Write-Host "PowerShell: Find-PopOS" -ForegroundColor White
Write-Host ""
Write-Host "Important:" -ForegroundColor Yellow
Write-Host "- Run pop_os_ssh_setup.sh on Pop!_OS first" -ForegroundColor White
Write-Host "- Both PCs must be on the same network" -ForegroundColor White

# Load functions in current session
. $PROFILE 2>$null

Write-Host "`nType 'Connect-PopOS' to test now" -ForegroundColor Green