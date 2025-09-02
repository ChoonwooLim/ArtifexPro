# PowerShell Profile Update Script
# Updates the Connect-PopOS function with correct IP

$profileContent = @'

# Pop!_OS SSH Connection Function (Updated)
function Connect-PopOS {
    Write-Host "Connecting to Pop!_OS (192.168.219.150)..." -ForegroundColor Green
    
    # Try direct IP first (fastest)
    Write-Host "1. Trying fixed IP (192.168.219.150)..." -ForegroundColor Yellow
    ssh -o ConnectTimeout=5 stevenlim@192.168.219.150
    if ($LASTEXITCODE -eq 0) { return }
    
    # Try SSH config
    Write-Host "2. Trying SSH config (popOS)..." -ForegroundColor Yellow
    ssh -o ConnectTimeout=5 popOS
    if ($LASTEXITCODE -eq 0) { return }
    
    # Try mDNS
    Write-Host "3. Trying mDNS (popOS-artifex.local)..." -ForegroundColor Yellow
    ssh -o ConnectTimeout=5 popOS-artifex.local
    if ($LASTEXITCODE -eq 0) { return }
    
    Write-Host "`nConnection failed. Check:" -ForegroundColor Red
    Write-Host "1. Pop!_OS is powered on" -ForegroundColor Yellow
    Write-Host "2. Ethernet cable is connected (enp1s0f1)" -ForegroundColor Yellow
    Write-Host "3. IP is 192.168.219.150" -ForegroundColor Yellow
}

# Alias
Set-Alias -Name popOS -Value Connect-PopOS

# Test Pop!_OS Connection
function Test-PopOS {
    Write-Host "Testing Pop!_OS connection..." -ForegroundColor Green
    
    # Ping test
    Write-Host "Ping test to 192.168.219.150..." -ForegroundColor Yellow
    $ping = Test-Connection -ComputerName 192.168.219.150 -Count 2 -Quiet -ErrorAction SilentlyContinue
    
    if ($ping) {
        Write-Host "✓ Ping successful!" -ForegroundColor Green
        
        # SSH port test
        Write-Host "Testing SSH port 22..." -ForegroundColor Yellow
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        try {
            $tcpClient.ConnectAsync("192.168.219.150", 22).Wait(1000) | Out-Null
            if ($tcpClient.Connected) {
                Write-Host "✓ SSH port is open!" -ForegroundColor Green
                Write-Host "Ready to connect. Use: popOS" -ForegroundColor Cyan
                $tcpClient.Close()
                return $true
            }
        } catch {
            Write-Host "✗ SSH port is closed" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ No response from 192.168.219.150" -ForegroundColor Red
        Write-Host "Check if Pop!_OS is running and connected to network" -ForegroundColor Yellow
    }
    return $false
}
'@

# Update PowerShell profile
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# Remove old popOS functions and add new ones
$existingProfile = Get-Content $PROFILE -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch "popOS|Pop!_OS" }
($existingProfile -join "`n") + "`n" + $profileContent | Set-Content $PROFILE -Encoding UTF8

Write-Host "PowerShell profile updated with correct IP (192.168.219.150)" -ForegroundColor Green
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Cyan
Write-Host "  popOS        - Connect to Pop!_OS" -ForegroundColor White
Write-Host "  Test-PopOS   - Test connection" -ForegroundColor White
Write-Host ""

# Load in current session
. $PROFILE 2>$null

Write-Host "Testing connection now..." -ForegroundColor Yellow
Test-PopOS