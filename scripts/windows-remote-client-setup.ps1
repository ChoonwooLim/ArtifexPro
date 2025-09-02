# Windows Remote Desktop Client Setup Script
# Pop!_OS Remote Desktop Client Setup

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Windows Remote Desktop Client Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get correct Desktop path (handles OneDrive redirection)
$DesktopPath = [Environment]::GetFolderPath("Desktop")
Write-Host "Desktop path detected: $DesktopPath" -ForegroundColor Gray

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run as Administrator!" -ForegroundColor Red
    exit
}

# Pop!_OS IP address input
$popOS_IP = Read-Host "Enter Pop!_OS IP address (e.g., 192.168.1.100)"

# Option selection
Write-Host ""
Write-Host "Select client to install:" -ForegroundColor Yellow
Write-Host "1) VNC Viewer (TigerVNC/RealVNC)"
Write-Host "2) Windows Remote Desktop (for xRDP)"
Write-Host "3) NoMachine (Recommended - Best Performance)"
Write-Host "4) Install All"
Write-Host ""
$choice = Read-Host "Choice (1-4)"

# 1. Install VNC Viewer
function Install-VNCViewer {
    Write-Host "Installing VNC Viewer..." -ForegroundColor Green
    
    # TigerVNC 다운로드
    $vncUrl = "https://github.com/TigerVNC/tigervnc/releases/download/v1.13.1/tigervnc64-1.13.1.exe"
    $vncPath = "$env:TEMP\tigervnc-setup.exe"
    
    Write-Host "Downloading TigerVNC..."
    Invoke-WebRequest -Uri $vncUrl -OutFile $vncPath
    
    Write-Host "Installing TigerVNC..."
    Start-Process -FilePath $vncPath -Wait
    
    # Create shortcut
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath\Pop!_OS VNC.lnk")
    $Shortcut.TargetPath = "C:\Program Files\TigerVNC\vncviewer.exe"
    $Shortcut.Arguments = "${popOS_IP}:5901"
    $Shortcut.Save()
    
    Write-Host "VNC Viewer installation complete!" -ForegroundColor Green
}

# 2. Windows RDP Setup
function Setup-RDP {
    Write-Host "Setting up Windows Remote Desktop connection..." -ForegroundColor Green
    
    # RDP 파일 생성
    $rdpContent = @"
screen mode id:i:2
use multimon:i:0
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
winposstr:s:0,3,0,0,800,600
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
full address:s:${popOS_IP}:3390
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:1
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:0
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
"@
    
    $rdpContent | Out-File -FilePath "$DesktopPath\Pop!_OS Remote.rdp" -Encoding UTF8
    
    Write-Host "RDP connection file created on Desktop!" -ForegroundColor Green
}

# 3. Install NoMachine
function Install-NoMachine {
    Write-Host "Installing NoMachine..." -ForegroundColor Green
    
    # NoMachine 다운로드
    $nomachineUrl = "https://download.nomachine.com/download/8.11/Windows/nomachine_8.11.3_4_x64.exe"
    $nomachinePath = "$env:TEMP\nomachine-setup.exe"
    
    Write-Host "Downloading NoMachine..."
    Invoke-WebRequest -Uri $nomachineUrl -OutFile $nomachinePath
    
    Write-Host "Installing NoMachine..."
    Start-Process -FilePath $nomachinePath -Wait
    
    # NoMachine 연결 파일 생성
    $nxsContent = @"
<!DOCTYPE NXClientSettings>
<NXClientSettings application="nxclient" version="1.3">
  <group name="General">
    <option key="Connection Name" value="Pop!_OS AI Server" />
    <option key="Server Host" value="$popOS_IP" />
    <option key="Server Port" value="4000" />
    <option key="Server Protocol" value="NX" />
  </group>
  <group name="Display">
    <option key="Desktop" value="1920x1080" />
    <option key="Fullscreen" value="false" />
    <option key="Quality" value="9" />
  </group>
</NXClientSettings>
"@
    
    $nxsContent | Out-File -FilePath "$DesktopPath\Pop!_OS NoMachine.nxs" -Encoding UTF8
    
    Write-Host "NoMachine installation complete!" -ForegroundColor Green
}

# Install based on choice
switch ($choice) {
    "1" { Install-VNCViewer }
    "2" { Setup-RDP }
    "3" { Install-NoMachine }
    "4" {
        Install-VNCViewer
        Write-Host ""
        Setup-RDP
        Write-Host ""
        Install-NoMachine
    }
    default {
        Write-Host "Invalid choice!" -ForegroundColor Red
        exit
    }
}

# Create SSH tunneling script (for secure connection)
$sshTunnelScript = @"
# SSH Tunneling for Secure Connection (Optional)
# Use this script to connect VNC through SSH tunnel

`$popOS_IP = "$popOS_IP"

Write-Host "Creating SSH tunnel..." -ForegroundColor Yellow
Write-Host "VNC: localhost:5901 -> `$popOS_IP:5901"
Write-Host "RDP: localhost:3390 -> `$popOS_IP:3390"
Write-Host "NoMachine: localhost:4000 -> `$popOS_IP:4000"
Write-Host ""
Write-Host "Press Ctrl+C to exit" -ForegroundColor Red

# Create SSH tunnel
ssh -L 5901:localhost:5901 -L 3390:localhost:3390 -L 4000:localhost:4000 popOS
"@

$sshTunnelScript | Out-File -FilePath "$DesktopPath\SSH-Tunnel-PopOS.ps1" -Encoding UTF8

# Create connection guide
$guideContent = @"
========================================
Pop!_OS Remote Desktop Connection Guide
========================================

Pop!_OS IP: $popOS_IP

Connection Methods:
------------------

1. VNC Connection:
   - Launch TigerVNC Viewer
   - Address: ${popOS_IP}:5901
   - Or use "Pop!_OS VNC" shortcut on Desktop

2. RDP Connection:
   - Run "Pop!_OS Remote.rdp" file on Desktop
   - Or enter ${popOS_IP}:3390 in Remote Desktop Connection

3. NoMachine Connection (Recommended):
   - Launch NoMachine client
   - Run "Pop!_OS NoMachine.nxs" file on Desktop
   - Or enter ${popOS_IP}:4000 in new connection

Secure Connection (SSH Tunnel):
-------------------------------
For more secure connection:
1. Run "SSH-Tunnel-PopOS.ps1" on Desktop
2. Connect to localhost:
   - VNC: localhost:5901
   - RDP: localhost:3390
   - NoMachine: localhost:4000

Performance Tips:
----------------
- Local Network: Use NoMachine (best performance)
- Internet: Use SSH tunnel + VNC (secure)
- Windows Compatibility: Use xRDP

Troubleshooting:
---------------
- Cannot connect: Check firewall
- Screen corruption: Adjust resolution settings
- Slow performance: Switch to NoMachine

========================================
"@

$guideContent | Out-File -FilePath "$DesktopPath\PopOS-Remote-Guide.txt" -Encoding UTF8

# Completion message
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The following files have been created on Desktop:" -ForegroundColor Yellow
Write-Host "  - Pop!_OS VNC.lnk (VNC shortcut)"
Write-Host "  - Pop!_OS Remote.rdp (RDP connection)"
Write-Host "  - Pop!_OS NoMachine.nxs (NoMachine connection)"
Write-Host "  - SSH-Tunnel-PopOS.ps1 (Secure tunnel)"
Write-Host "  - PopOS-Remote-Guide.txt (Connection guide)"
Write-Host ""
Write-Host "Make sure setup-remote-desktop.sh has been run on Pop!_OS!" -ForegroundColor Red
Write-Host ""