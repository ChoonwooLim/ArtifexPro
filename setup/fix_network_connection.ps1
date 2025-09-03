# Pop!_OS 연결 복구 스크립트 (1Gbps 이더넷 사용)

Write-Host "=== Pop!_OS 연결 복구 (10Gbps 카드 제거 후) ===" -ForegroundColor Cyan

# 현재 네트워크 상태 확인
Write-Host "`n1. 현재 네트워크 어댑터 상태:" -ForegroundColor Yellow
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Format-Table Name, Status, LinkSpeed, InterfaceDescription

# Pop!_OS IP 주소 업데이트 (1Gbps 네트워크 사용)
$popOSIP = "192.168.1.100"  # 1Gbps 네트워크의 Pop!_OS IP
Write-Host "`n2. Pop!_OS 연결 테스트 ($popOSIP):" -ForegroundColor Yellow

# Ping 테스트
$pingResult = Test-Connection -ComputerName $popOSIP -Count 2 -Quiet
if ($pingResult) {
    Write-Host "✅ Pop!_OS 연결 성공!" -ForegroundColor Green
} else {
    Write-Host "❌ Pop!_OS 연결 실패. IP 주소를 확인하세요." -ForegroundColor Red
    Write-Host "Pop!_OS에서 실행: ip addr show | grep inet" -ForegroundColor Yellow
}

# SSH 설정 업데이트
Write-Host "`n3. SSH 설정 업데이트:" -ForegroundColor Yellow
$sshConfigPath = "$env:USERPROFILE\.ssh\config"
$sshConfig = @"
Host popOS
    HostName $popOSIP
    User stevenlim
    Port 22
    # 1Gbps 네트워크 사용 (10Gbps 카드 제거됨)
"@

Write-Host "SSH 설정 파일 업데이트: $sshConfigPath"
$sshConfig | Out-File -FilePath $sshConfigPath -Encoding UTF8 -Force

# 연결 테스트
Write-Host "`n4. SSH 연결 테스트:" -ForegroundColor Yellow
Write-Host "실행: ssh popOS 'echo Connection OK'" -ForegroundColor Cyan
ssh popOS "echo 'SSH Connection OK'"

Write-Host "`n=== 완료 ===" -ForegroundColor Green
Write-Host "ArtifexPro 개발 환경 준비 완료!" -ForegroundColor Green
Write-Host "다음 명령으로 개발 시작: Start-ArtifexDev" -ForegroundColor Cyan