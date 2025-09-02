$ip = "192.168.219.150"
Write-Host "Testing SSH connection to $ip..." -ForegroundColor Yellow

# Test ping
$ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
if ($ping) {
    Write-Host "✓ Ping successful" -ForegroundColor Green
} else {
    Write-Host "✗ Ping failed" -ForegroundColor Red
}

# Test SSH port
$tcp = New-Object System.Net.Sockets.TcpClient
try {
    $tcp.ConnectAsync($ip, 22).Wait(2000) | Out-Null
    if ($tcp.Connected) {
        Write-Host "✓ SSH Port 22 is OPEN" -ForegroundColor Green
        $tcp.Close()
        
        # Try SSH connection
        Write-Host "`nTrying SSH connection..." -ForegroundColor Yellow
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no stevenlim@$ip "echo 'SSH SUCCESS'; hostname"
    } else {
        Write-Host "✗ SSH Port 22 is CLOSED" -ForegroundColor Red
        Write-Host "`nPossible issues:" -ForegroundColor Yellow
        Write-Host "1. SSH service not running on Pop!_OS" -ForegroundColor White
        Write-Host "   Fix: sudo systemctl start ssh" -ForegroundColor Cyan
        Write-Host "2. Firewall blocking port 22" -ForegroundColor White
        Write-Host "   Fix: sudo ufw allow ssh" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ Cannot connect to SSH port" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Gray
}