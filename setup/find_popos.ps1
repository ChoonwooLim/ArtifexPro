# Find Pop!_OS on network
Write-Host "Scanning network for Pop!_OS SSH server..." -ForegroundColor Green
Write-Host "Your Windows IP: 192.168.219.104" -ForegroundColor Cyan
Write-Host ""

$found = $false
$subnet = "192.168.219"

# Common IP ranges for Pop!_OS
$ranges = @(
    @{Start=100; End=110},  # 100-110
    @{Start=140; End=160},  # 140-160 (including 150)
    @{Start=2; End=20},     # 2-20
    @{Start=200; End=254}   # 200-254
)

foreach ($range in $ranges) {
    Write-Host "Scanning $subnet.$($range.Start)-$($range.End)..." -ForegroundColor Yellow
    
    for ($i = $range.Start; $i -le $range.End; $i++) {
        $ip = "$subnet.$i"
        Write-Progress -Activity "Scanning network" -Status "Testing $ip" -PercentComplete (($i - $range.Start) * 100 / ($range.End - $range.Start))
        
        # Quick ping test
        $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
        
        if ($ping) {
            Write-Host "  Found device: $ip" -ForegroundColor Yellow -NoNewline
            
            # Test SSH port
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            try {
                $tcpClient.ConnectAsync($ip, 22).Wait(500) | Out-Null
                if ($tcpClient.Connected) {
                    Write-Host " -> SSH port OPEN!" -ForegroundColor Green
                    $found = $true
                    
                    # Try to connect and get hostname
                    Write-Host "  Testing SSH connection..." -ForegroundColor Cyan
                    $result = ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o PasswordAuthentication=no stevenlim@$ip "hostname" 2>$null
                    if ($result) {
                        Write-Host "  *** FOUND Pop!_OS at $ip (hostname: $result) ***" -ForegroundColor Green -BackgroundColor DarkGreen
                        Write-Host ""
                        Write-Host "To connect:" -ForegroundColor Cyan
                        Write-Host "  ssh stevenlim@$ip" -ForegroundColor White
                        return $ip
                    } else {
                        Write-Host "  SSH available but authentication needed" -ForegroundColor Yellow
                        Write-Host "  Try: ssh stevenlim@$ip" -ForegroundColor White
                    }
                    $tcpClient.Close()
                } else {
                    Write-Host " - No SSH" -ForegroundColor Gray
                }
            } catch {
                Write-Host " - No SSH" -ForegroundColor Gray
            }
        }
    }
    
    if ($found) { break }
}

if (!$found) {
    Write-Host ""
    Write-Host "No SSH servers found in 192.168.219.x network" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check on Pop!_OS:" -ForegroundColor Yellow
    Write-Host "1. Run: ip addr show enp1s0f1" -ForegroundColor White
    Write-Host "2. Look for inet 192.168.219.xxx" -ForegroundColor White
    Write-Host "3. Run: sudo systemctl status ssh" -ForegroundColor White
}