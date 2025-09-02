# Pop!_OS 원격 데스크톱 연결 스크립트
Write-Host "Pop!_OS 원격 데스크톱 연결 시작..." -ForegroundColor Green

# Pop!_OS IP 주소 확인
$popOSIP = ssh popOS "hostname -I | cut -d' ' -f1" 2>$null

if ($popOSIP) {
    Write-Host "Pop!_OS IP 주소: $popOSIP" -ForegroundColor Cyan
    
    # RDP 파일 업데이트
    $rdpFile = "C:\Users\choon\OneDrive\바탕 화면\Pop!_OS Remote.rdp"
    if (Test-Path $rdpFile) {
        $content = Get-Content $rdpFile
        $content = $content -replace "full address:s:.*", "full address:s:${popOSIP}:3389"
        Set-Content $rdpFile $content
        Write-Host "RDP 파일 업데이트 완료" -ForegroundColor Green
    }
    
    # xrdp 서비스 상태 확인
    Write-Host "`nxrdp 서비스 상태 확인 중..." -ForegroundColor Yellow
    $xrdpStatus = ssh popOS "systemctl is-active xrdp 2>/dev/null"
    
    if ($xrdpStatus -eq "active") {
        Write-Host "xrdp 서비스가 실행 중입니다." -ForegroundColor Green
        
        # 원격 데스크톱 연결 시작
        Write-Host "`n원격 데스크톱 연결을 시작합니다..." -ForegroundColor Green
        Start-Process "mstsc" -ArgumentList $rdpFile
        
        Write-Host "`n연결 정보:" -ForegroundColor Cyan
        Write-Host "  IP 주소: $popOSIP" -ForegroundColor White
        Write-Host "  포트: 3389" -ForegroundColor White
        Write-Host "  사용자명: stevenlim" -ForegroundColor White
        Write-Host "  패스워드: Pop!_OS 로그인 패스워드 사용" -ForegroundColor White
    } else {
        Write-Host "xrdp 서비스가 실행되지 않습니다." -ForegroundColor Red
        Write-Host "Pop!_OS에서 다음 명령을 실행하세요:" -ForegroundColor Yellow
        Write-Host "  ~/setup_xrdp.sh" -ForegroundColor White
        Write-Host "또는" -ForegroundColor Yellow
        Write-Host "  sudo apt install xrdp && sudo systemctl start xrdp" -ForegroundColor White
    }
} else {
    Write-Host "Pop!_OS에 연결할 수 없습니다." -ForegroundColor Red
    Write-Host "SSH 연결을 확인하세요: ssh popOS" -ForegroundColor Yellow
}

Write-Host "`n종료하려면 아무 키나 누르세요..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")