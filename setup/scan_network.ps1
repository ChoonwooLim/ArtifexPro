# Scan network for SSH servers
Write-Host "Scanning 192.168.219.x network for SSH servers..." -ForegroundColor Yellow
Write-Host ""

$sshHosts = @()

# Check devices from ARP table
$arpOutput = arp -a | Select-String "192.168.219" | Where-Object { $_ -notmatch "255|224\.|239\." }

foreach ($line in $arpOutput) {
    if ($line -match "(\d+\.\d+\.\d+\.\d+)\s+([0-9a-f-]+)\s+") {
        $ip = $matches[1]
        $mac = $matches[2]
        
        Write-Host "Checking $ip (MAC: $mac)..." -NoNewline
        
        # Test SSH port
        $tcp = New-Object System.Net.Sockets.TcpClient
        try {
            $tcp.ConnectAsync($ip, 22).Wait(500) | Out-Null
            if ($tcp.Connected) {
                Write-Host " SSH FOUND!" -ForegroundColor Green
                $sshHosts += $ip
                $tcp.Close()
            } else {
                Write-Host " No SSH" -ForegroundColor Gray
            }
        } catch {
            Write-Host " No SSH" -ForegroundColor Gray
        }
    }
}

Write-Host ""
if ($sshHosts.Count -gt 0) {
    Write-Host "Found SSH servers:" -ForegroundColor Green
    foreach ($host in $sshHosts) {
        Write-Host "  ssh stevenlim@$host" -ForegroundColor Cyan
    }
} else {
    Write-Host "No SSH servers found in the network" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "1. Pop!_OS SSH service not started" -ForegroundColor White
    Write-Host "2. Pop!_OS firewall blocking connections" -ForegroundColor White
    Write-Host "3. Pop!_OS using different IP address" -ForegroundColor White
}