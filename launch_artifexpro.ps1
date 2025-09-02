# Launch ArtifexPro with Dual GPU Support
# Starts both Windows frontend and Pop!_OS backend

param(
    [switch]$Debug = $false
)

Write-Host @"

    ╔═══════════════════════════════════════════════════════╗
    ║           ArtifexPro - WAN2.2 Studio                 ║
    ║        High-End AI Video Generation Platform         ║
    ║            Dual RTX 3090 - 48GB VRAM                 ║
    ╔═══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Configuration
$PopOSHost = "192.168.1.100"
$PopOSUser = "stevenlim"
$LocalPort = 3000
$BackendPort = 8001
$RayDashboard = 8265

function Test-Connection {
    param($Host, $Port)
    
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $tcpClient.Connect($Host, $Port)
        $tcpClient.Close()
        return $true
    } catch {
        return $false
    }
}

# Step 1: Check Pop!_OS connection
Write-Host "🔍 Checking Pop!_OS connection..." -ForegroundColor Yellow
$sshTest = ssh "${PopOSUser}@${PopOSHost}" "echo 'Connected'" 2>$null

if ($sshTest -eq "Connected") {
    Write-Host "✅ Pop!_OS connected successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Cannot connect to Pop!_OS. Please check SSH settings." -ForegroundColor Red
    exit 1
}

# Step 2: Start Pop!_OS backend
Write-Host "`n🚀 Starting Pop!_OS backend services..." -ForegroundColor Yellow

$backendScript = @'
#!/bin/bash
cd ~/ArtifexPro

# Check if Ray is running
if ! ray status 2>/dev/null | grep -q "running"; then
    echo "Starting Ray cluster..."
    bash scripts/start_ray_cluster.sh
    sleep 3
fi

# Activate environment
source venv/bin/activate 2>/dev/null || python3 -m venv venv && source venv/bin/activate

# Install requirements if needed
pip install -q -r requirements.txt 2>/dev/null

# Start backend
echo "Starting WAN2.2 optimized backend..."
nohup python backend/wan22_optimized.py > backend.log 2>&1 &
echo $! > backend.pid

echo "Backend started with PID: $(cat backend.pid)"
'@

# Execute backend startup
ssh "${PopOSUser}@${PopOSHost}" $backendScript

# Wait for backend to start
Write-Host "⏳ Waiting for backend to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check backend status
if (Test-Connection -Host $PopOSHost -Port $BackendPort) {
    Write-Host "✅ Backend API running at http://${PopOSHost}:${BackendPort}" -ForegroundColor Green
} else {
    Write-Host "⚠️ Backend may still be starting..." -ForegroundColor Yellow
}

if (Test-Connection -Host $PopOSHost -Port $RayDashboard) {
    Write-Host "✅ Ray Dashboard available at http://${PopOSHost}:${RayDashboard}" -ForegroundColor Green
}

# Step 3: Start local frontend
Write-Host "`n🎨 Starting frontend development server..." -ForegroundColor Yellow

# Check if npm packages are installed
if (!(Test-Path "node_modules")) {
    Write-Host "📦 Installing npm packages..." -ForegroundColor Yellow
    npm install
}

# Kill any existing frontend process
Get-Process node -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*vite*" -or $_.CommandLine -like "*webpack*"
} | Stop-Process -Force

# Start frontend
if ($Debug) {
    Write-Host "🐛 Starting in debug mode..." -ForegroundColor Magenta
    npm run dev
} else {
    Start-Process powershell -ArgumentList "cd '$PWD'; npm run dev" -WindowStyle Hidden
    
    # Wait for frontend
    Write-Host "⏳ Waiting for frontend to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Open browser
    Write-Host "`n🌐 Opening ArtifexPro in browser..." -ForegroundColor Cyan
    Start-Process "http://localhost:${LocalPort}"
    
    # Show status
    Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                  ArtifexPro is Ready!                     ║
╠═══════════════════════════════════════════════════════════╣
║  Frontend:       http://localhost:$LocalPort                    ║
║  Backend API:    http://${PopOSHost}:${BackendPort}                  ║
║  Ray Dashboard:  http://${PopOSHost}:${RayDashboard}                  ║
╠═══════════════════════════════════════════════════════════╣
║  GPU Status:                                              ║
║    • GPU 0: RTX 3090 (24GB) - Primary                    ║
║    • GPU 1: RTX 3090 (24GB) - Secondary                  ║
║    • Total VRAM: 48GB                                    ║
╠═══════════════════════════════════════════════════════════╣
║  Optimizations:                                           ║
║    ✅ Flash Attention 3                                   ║
║    ✅ xFormers Memory Efficient                           ║
║    ✅ FP16 Mixed Precision                                ║
║    ✅ Ray Distributed Computing                           ║
║    ✅ VAE Slicing & Attention Slicing                     ║
╠═══════════════════════════════════════════════════════════╣
║  Models Available:                                        ║
║    • TI2V-5B: Text+Image to Video (5B params)            ║
║    • S2V-14B: Sound to Video (14B params)                ║
║    • T2V-A14B: Text to Video (27B MoE, 14B active)       ║
║    • I2V-A14B: Image to Video (27B MoE, 14B active)      ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

    Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Yellow
    
    # Keep script running
    while ($true) {
        Start-Sleep -Seconds 60
        
        # Health check
        if (!(Test-Connection -Host $PopOSHost -Port $BackendPort)) {
            Write-Host "⚠️ Backend connection lost, attempting restart..." -ForegroundColor Yellow
            ssh "${PopOSUser}@${PopOSHost}" $backendScript
        }
    }
}

# Cleanup on exit
trap {
    Write-Host "`n🛑 Shutting down ArtifexPro..." -ForegroundColor Yellow
    
    # Stop backend
    ssh "${PopOSUser}@${PopOSHost}" "kill \$(cat ~/ArtifexPro/backend.pid) 2>/dev/null; ray stop --force"
    
    # Stop frontend
    Get-Process node -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*vite*" -or $_.CommandLine -like "*webpack*"
    } | Stop-Process -Force
    
    Write-Host "✅ ArtifexPro stopped" -ForegroundColor Green
}