# ArtifexPro TI2V & S2V 전용 실행 스크립트
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "       ArtifexPro Studio - TI2V & S2V Edition         " -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 모델 상태 확인
Write-Host "📊 Model Status Check:" -ForegroundColor Green
Write-Host "  • Wan2.2-TI2V-5B (32GB) - RTX 3090 Ready ✅" -ForegroundColor White
Write-Host "  • Wan2.2-S2V-14B (31GB) - RTX 3090 Ready ✅" -ForegroundColor White
Write-Host ""

# Pop!_OS 백엔드 시작
Write-Host "🚀 Starting Backend Server (Pop!_OS)..." -ForegroundColor Yellow
$backend = Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
Write-Host 'Connecting to Pop!_OS...' -ForegroundColor Cyan
ssh popOS 'cd ~/ArtifexPro && source venv/bin/activate && echo ''Starting TI2V/S2V API...'' && python backend/api/ti2v_s2v_api.py'
"@ -PassThru

Start-Sleep -Seconds 3

# 백엔드 연결 확인
Write-Host "🔍 Checking backend connection..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://192.168.219.150:8000/" -TimeoutSec 5
    Write-Host "✅ Backend connected! GPU: $($response.gpu)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Backend not responding yet (may still be loading)" -ForegroundColor Yellow
}

# 프론트엔드 시작
Write-Host "`n🎨 Starting Frontend..." -ForegroundColor Yellow

# 의존성 확인
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
}

$frontend = Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev" -PassThru

Start-Sleep -Seconds 5

# 브라우저 열기
Write-Host "`n🌐 Opening browser..." -ForegroundColor Yellow
Start-Process "http://localhost:3000"

# 정보 출력
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "           ✨ ArtifexPro Studio is Ready!             " -ForegroundColor Green  
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📌 Access Points:" -ForegroundColor Cyan
Write-Host "   • Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   • Backend API: http://192.168.219.150:8000" -ForegroundColor White
Write-Host "   • API Docs: http://192.168.219.150:8000/docs" -ForegroundColor White
Write-Host ""
Write-Host "🎮 Available Models:" -ForegroundColor Cyan
Write-Host "   • TI2V-5B: Text + Image → Video (32GB)" -ForegroundColor White
Write-Host "   • S2V-14B: Audio → Video (31GB)" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor Yellow
Write-Host "   • TI2V works best with 720p, 5-10 second clips" -ForegroundColor Gray
Write-Host "   • S2V automatically syncs with audio duration" -ForegroundColor Gray
Write-Host "   • Use 'balanced' quality for best speed/quality ratio" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Gray
Write-Host ""

# 프로세스 모니터링
while ($true) {
    Start-Sleep -Seconds 10
    if ($frontend.HasExited -or $backend.HasExited) {
        Write-Host "`n⚠️ A process has stopped" -ForegroundColor Red
        break
    }
}