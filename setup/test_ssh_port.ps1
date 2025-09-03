$tcp = New-Object System.Net.Sockets.TcpClient
try {
    $tcp.ConnectAsync('10.0.0.2', 22).Wait(2000) | Out-Null
    if($tcp.Connected) { 
        Write-Host 'SSH Port 22: OPEN' -ForegroundColor Green
        $tcp.Close() 
    } else { 
        Write-Host 'SSH Port 22: CLOSED' -ForegroundColor Red
    }
} catch { 
    Write-Host 'SSH Port 22: TIMEOUT/ERROR' -ForegroundColor Red
}