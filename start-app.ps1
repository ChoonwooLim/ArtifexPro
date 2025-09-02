# ArtifexPro 간단 실행 스크립트
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "    ArtifexPro Studio Starting...   " -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 프론트엔드만 먼저 실행
Write-Host "Starting Frontend..." -ForegroundColor Green

# npm 설치 확인
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# 개발 서버 시작
Write-Host "Launching development server..." -ForegroundColor Green
npm run dev

Write-Host ""
Write-Host "Frontend is running at: http://localhost:3000" -ForegroundColor Cyan