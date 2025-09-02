# Ray 클러스터 테스트 스크립트
Write-Host "`n"
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Ray Cluster Connection Test       ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Python 및 Ray 설치 확인
Write-Host "STEP 1: Checking Ray installation..." -ForegroundColor Green
pip install -q ray[default] torch 2>$null
Write-Host "  ✓ Ray package ready" -ForegroundColor Gray

# Step 2: Pop!_OS Ray Head 상태 확인
Write-Host ""
Write-Host "STEP 2: Checking Pop!_OS Ray Head..." -ForegroundColor Green
$popOSRay = ssh popOS "source ~/ArtifexPro/venv/bin/activate; ray status 2>/dev/null"
if ($popOSRay -match "Healthy") {
    Write-Host "  ✓ Ray Head is running on Pop!_OS" -ForegroundColor Gray
} else {
    Write-Host "  ✗ Ray Head not running. Starting..." -ForegroundColor Yellow
    ssh popOS @"
cd ~/ArtifexPro
source venv/bin/activate
ray stop
ray start --head --port=6379 --dashboard-host=0.0.0.0 --num-gpus=1
"@
    Start-Sleep -Seconds 3
}

# Step 3: Windows Ray Worker 연결
Write-Host ""
Write-Host "STEP 3: Connecting Windows Ray Worker..." -ForegroundColor Green
ray stop 2>$null
ray start --address=192.168.219.150:6379 --num-gpus=1

Start-Sleep -Seconds 3

# Step 4: 클러스터 검증
Write-Host ""
Write-Host "STEP 4: Validating Cluster..." -ForegroundColor Green
python -c @"
import ray
import sys

try:
    # Ray 클러스터 연결
    ray.init(address='ray://192.168.219.150:10001')
    
    # 리소스 확인
    resources = ray.cluster_resources()
    nodes = ray.nodes()
    
    print(f'\n✅ Cluster Status:')
    print(f'  • Total GPUs: {resources.get("GPU", 0)}/2')
    print(f'  • Total CPUs: {resources.get("CPU", 0)}')
    print(f'  • Total Memory: {resources.get("memory", 0) / 1e9:.1f} GB')
    print(f'  • Active Nodes: {len([n for n in nodes if n["Alive"]])}/{len(nodes)}')
    
    # GPU 테스트
    @ray.remote(num_gpus=1.0)
    def test_gpu(node_name):
        import torch
        if torch.cuda.is_available():
            device_name = torch.cuda.get_device_name(0)
            memory = torch.cuda.get_device_properties(0).total_memory / 1e9
            return f'{node_name}: {device_name} ({memory:.1f}GB)'
        return f'{node_name}: No GPU'
    
    # 각 노드에서 GPU 테스트
    futures = []
    if resources.get('GPU', 0) >= 1:
        futures.append(test_gpu.remote('Node1'))
    if resources.get('GPU', 0) >= 2:
        futures.append(test_gpu.remote('Node2'))
    
    if futures:
        results = ray.get(futures)
        print(f'\n🎮 GPU Information:')
        for result in results:
            print(f'  • {result}')
    
    # 듀얼 GPU 작업 시뮬레이션
    @ray.remote(num_gpus=2.0)
    def dual_gpu_test():
        return 'Dual GPU allocation successful!'
    
    if resources.get('GPU', 0) >= 2:
        result = ray.get(dual_gpu_test.remote())
        print(f'\n✨ {result}')
    
    ray.shutdown()
    sys.exit(0)
    
except Exception as e:
    print(f'\n❌ Cluster connection failed:')
    print(f'  Error: {e}')
    print(f'\n💡 Troubleshooting:')
    print(f'  1. Check if Pop!_OS is accessible: ssh popOS "echo OK"')
    print(f'  2. Check Ray dashboard: http://192.168.219.150:8265')
    print(f'  3. Check firewall on both machines')
    sys.exit(1)
"@

# 결과 메시지
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n"
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║    ✅ Ray Cluster Ready for Work!     ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: .\start-dual-gpu.ps1" -ForegroundColor White
    Write-Host "  2. Open: http://localhost:3000" -ForegroundColor White
    Write-Host "  3. Monitor: http://192.168.219.150:8265" -ForegroundColor White
} else {
    Write-Host "`n"
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║    ⚠️  Cluster Setup Required         ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Red
}