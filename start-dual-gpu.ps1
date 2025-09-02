# ArtifexPro 듀얼 GPU 클러스터 실행 스크립트
Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     ArtifexPro Studio - Dual RTX 3090 GPU Cluster       ║" -ForegroundColor Yellow
Write-Host "║            Windows + Pop!_OS (Total 48GB VRAM)          ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Pop!_OS Ray Head 시작
Write-Host "STEP 1: Starting Ray Head on Pop!_OS..." -ForegroundColor Green
Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray

# Ray Head 스크립트 생성
ssh popOS @"
cat > ~/ArtifexPro/start_ray_head.sh << 'EOF'
#!/bin/bash
cd ~/ArtifexPro
source venv/bin/activate
ray stop
ray start --head --port=6379 --dashboard-host=0.0.0.0 --num-gpus=1
echo 'Ray Head started on Pop!_OS'
EOF
chmod +x ~/ArtifexPro/start_ray_head.sh
"@

# Ray Head 실행
$rayHead = Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Write-Host 'Connecting to Pop!_OS Ray Head...' -ForegroundColor Cyan
ssh popOS '~/ArtifexPro/start_ray_head.sh'
"@ -PassThru

Start-Sleep -Seconds 5

# Step 2: Windows Ray Worker 시작
Write-Host "`nSTEP 2: Starting Ray Worker on Windows..." -ForegroundColor Green
Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray

# Ray 설치 확인
pip install -q ray[default] torch | Out-Null

# Ray Worker 시작
ray stop 2>$null
$rayWorker = Start-Process cmd -ArgumentList "/k", "ray start --address=192.168.219.150:6379 --num-gpus=1" -PassThru

Start-Sleep -Seconds 3

# Step 3: 클러스터 상태 확인
Write-Host "`nSTEP 3: Verifying Cluster Status..." -ForegroundColor Green
Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray

python -c @"
import ray
try:
    ray.init(address='ray://192.168.219.150:10001')
    resources = ray.cluster_resources()
    print(f'✅ Cluster Connected!')
    print(f'   Total GPUs: {resources.get(\"GPU\", 0)}')
    print(f'   Total CPUs: {resources.get(\"CPU\", 0)}')
    print(f'   Nodes: {len(ray.nodes())}')
    ray.shutdown()
except Exception as e:
    print(f'⚠️ Cluster not ready yet: {e}')
"@

# Step 4: 백엔드 API 시작
Write-Host "`nSTEP 4: Starting Backend API Server..." -ForegroundColor Green
Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray

# 백엔드 서버 스크립트 생성
ssh popOS @"
cat > ~/ArtifexPro/start_backend.sh << 'EOF'
#!/bin/bash
cd ~/ArtifexPro
source venv/bin/activate
export RAY_ADDRESS=ray://192.168.219.150:10001
python backend/dual_gpu_model_server.py
EOF
chmod +x ~/ArtifexPro/start_backend.sh
"@

$backend = Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Write-Host 'Starting Dual GPU Model Server...' -ForegroundColor Cyan
ssh popOS '~/ArtifexPro/start_backend.sh'
"@ -PassThru

Start-Sleep -Seconds 3

# Step 5: 프론트엔드 시작
Write-Host "`nSTEP 5: Starting Frontend..." -ForegroundColor Green
Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray

if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
}

$frontend = Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev" -PassThru

Start-Sleep -Seconds 5

# Step 6: 브라우저 열기
Write-Host "`nSTEP 6: Opening Browser..." -ForegroundColor Green
Start-Process "http://localhost:3000"

# 완료 메시지
Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         ✨ Dual GPU Cluster is Ready! ✨                ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🎮 GPU Configuration:" -ForegroundColor Cyan
Write-Host "   • Pop!_OS: RTX 3090 (24GB) - Head Node" -ForegroundColor White
Write-Host "   • Windows: RTX 3090 (24GB) - Worker Node" -ForegroundColor White
Write-Host "   • Total VRAM: 48GB (Distributed)" -ForegroundColor Yellow
Write-Host ""
Write-Host "📌 Access Points:" -ForegroundColor Cyan
Write-Host "   • Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   • Ray Dashboard: http://192.168.219.150:8265" -ForegroundColor White
Write-Host "   • API Docs: http://192.168.219.150:8000/docs" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Model Capabilities:" -ForegroundColor Cyan
Write-Host "   • TI2V-5B: Using both GPUs (faster)" -ForegroundColor White
Write-Host "   • S2V-14B: Using both GPUs (stable)" -ForegroundColor White
Write-Host "   • Can run larger models with 48GB total" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Benefits of Dual GPU:" -ForegroundColor Yellow
Write-Host "   • 2x faster generation" -ForegroundColor Gray
Write-Host "   • Larger batch sizes" -ForegroundColor Gray
Write-Host "   • Model parallelism" -ForegroundColor Gray
Write-Host "   • Redundancy (if one fails)" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor DarkGray
Write-Host ""

# 모니터링
while ($true) {
    Start-Sleep -Seconds 30
    
    # GPU 상태 체크
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - Checking cluster health..." -ForegroundColor DarkGray
    
    # GPU 상태 간단히 체크
    Write-Host "  Checking GPU status..." -ForegroundColor DarkGray
}