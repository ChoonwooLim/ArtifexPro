# Test Pop!_OS Connection Script
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Testing Pop!_OS Connection" -ForegroundColor Cyan
Write-Host "Target IP: 192.168.219.150" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Cyan

# Test 1: Ping
Write-Host "`n[1] Testing Ping..." -ForegroundColor Green
$pingResult = Test-Connection -ComputerName 192.168.219.150 -Count 2 -Quiet
if ($pingResult) {
    Write-Host "✓ Ping successful!" -ForegroundColor Green
} else {
    Write-Host "✗ Ping failed - Machine may be offline or blocking ICMP" -ForegroundColor Red
}

# Test 2: SSH Port
Write-Host "`n[2] Testing SSH Port (22)..." -ForegroundColor Green
$tcpTest = Test-NetConnection -ComputerName 192.168.219.150 -Port 22 -WarningAction SilentlyContinue
if ($tcpTest.TcpTestSucceeded) {
    Write-Host "✓ SSH port is open!" -ForegroundColor Green
} else {
    Write-Host "✗ SSH port is closed or unreachable" -ForegroundColor Red
}

# Test 3: SSH Connection
Write-Host "`n[3] Testing SSH Connection..." -ForegroundColor Green
try {
    $sshTest = ssh popOS "echo 'Connected' && hostname"
    if ($sshTest) {
        Write-Host "✓ SSH connection successful!" -ForegroundColor Green
        Write-Host "   Response: $sshTest" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ SSH connection failed" -ForegroundColor Red
}

# Test 4: API Ports
Write-Host "`n[4] Testing API Ports..." -ForegroundColor Green
$ports = @(8002, 8003, 8265, 6379)
foreach ($port in $ports) {
    $portTest = Test-NetConnection -ComputerName 192.168.219.150 -Port $port -WarningAction SilentlyContinue
    if ($portTest.TcpTestSucceeded) {
        Write-Host "✓ Port $port is open" -ForegroundColor Green
    } else {
        Write-Host "✗ Port $port is closed" -ForegroundColor Yellow
    }
}

Write-Host "`n==================================" -ForegroundColor Cyan
Write-Host "Connection Test Complete" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan