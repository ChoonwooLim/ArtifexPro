# ArtifexPro Studio 통합 실행 스크립트
Write-Host "🚀 ArtifexPro Studio 시작..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Pop!_OS 백엔드 서버 시작
Write-Host "`n📡 Pop!_OS 백엔드 서버 시작 중..." -ForegroundColor Yellow
$backend = Start-Process powershell -ArgumentList "-NoExit", "-Command", "ssh popOS 'cd ~/ArtifexPro && source venv/bin/activate && python backend/api/main.py'" -PassThru

# 3초 대기 (백엔드 초기화)
Start-Sleep -Seconds 3

# 백엔드 상태 확인
try {
    $response = Invoke-WebRequest -Uri "http://192.168.219.150:8000/health" -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ 백엔드 서버 실행 완료!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  백엔드 연결 확인 필요" -ForegroundColor Yellow
}

# 프론트엔드 의존성 설치 확인
Write-Host "`n📦 프론트엔드 의존성 확인 중..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "패키지 설치 중..." -ForegroundColor Yellow
    npm install
}

# 프론트엔드 개발 서버 시작
Write-Host "`n🎨 프론트엔드 개발 서버 시작 중..." -ForegroundColor Yellow
$frontend = Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev" -PassThru

# 5초 대기 (Vite 서버 시작)
Start-Sleep -Seconds 5

# 브라우저 열기
Write-Host "`n🌐 브라우저 열기..." -ForegroundColor Yellow
Start-Process "http://localhost:3000"

Write-Host "`n================================" -ForegroundColor Green
Write-Host "✨ ArtifexPro Studio 실행 완료!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "📌 접속 정보:" -ForegroundColor Cyan
Write-Host "   프론트엔드: http://localhost:3000" -ForegroundColor White
Write-Host "   백엔드 API: http://192.168.219.150:8000" -ForegroundColor White
Write-Host "   API 문서: http://192.168.219.150:8000/docs" -ForegroundColor White
Write-Host ""
Write-Host "📌 종료하려면:" -ForegroundColor Cyan
Write-Host "   이 창을 닫거나 Ctrl+C를 누르세요" -ForegroundColor White
Write-Host ""

# 프로세스 모니터링
Write-Host "프로세스 모니터링 중..." -ForegroundColor Gray
while ($true) {
    Start-Sleep -Seconds 10
    if ($frontend.HasExited -or $backend.HasExited) {
        Write-Host "⚠️  프로세스가 종료되었습니다" -ForegroundColor Red
        break
    }
}