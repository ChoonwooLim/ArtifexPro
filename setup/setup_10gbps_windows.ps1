# Windows 10Gbps 직접 연결 설정 스크립트
# 관리자 권한으로 실행 필요

Write-Host "=== Windows 10Gbps 직접 연결 설정 ===" -ForegroundColor Green
Write-Host ""

# 10Gbps 어댑터 찾기
$adapter = Get-NetAdapter | Where-Object {$_.LinkSpeed -eq "10 Gbps"}

if ($adapter) {
    Write-Host "10Gbps 어댑터 발견:" -ForegroundColor Green
    Write-Host "  이름: $($adapter.Name)" -ForegroundColor Cyan
    Write-Host "  설명: $($adapter.InterfaceDescription)" -ForegroundColor Cyan
    Write-Host "  속도: $($adapter.LinkSpeed)" -ForegroundColor Cyan
    Write-Host ""
    
    # 기존 IP 설정 제거
    Write-Host "기존 IP 설정 제거..." -ForegroundColor Yellow
    Remove-NetIPAddress -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
    
    # 새 IP 설정
    Write-Host "새 IP 설정 (10.0.0.1/24)..." -ForegroundColor Yellow
    New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress "10.0.0.1" -PrefixLength 24 -ErrorAction SilentlyContinue
    
    # Jumbo Frame 설정 (9000 MTU)
    Write-Host "Jumbo Frame 설정 (MTU 9000)..." -ForegroundColor Yellow
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Jumbo Packet" -DisplayValue "9014 Bytes" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Jumbo Frame" -DisplayValue "9014 Bytes" -ErrorAction SilentlyContinue
    
    # 현재 설정 확인
    Write-Host ""
    Write-Host "현재 IP 설정:" -ForegroundColor Green
    Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 | Format-Table IPAddress, PrefixLength
    
    Write-Host ""
    Write-Host "=== 설정 완료 ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "다음 단계:" -ForegroundColor Yellow
    Write-Host "1. Pop!_OS에서 IP를 10.0.0.2로 설정" -ForegroundColor White
    Write-Host "2. 연결 테스트: ping 10.0.0.2" -ForegroundColor White
    Write-Host "3. SSH 연결: ssh stevenlim@10.0.0.2" -ForegroundColor White
    
} else {
    Write-Host "10Gbps 어댑터를 찾을 수 없습니다!" -ForegroundColor Red
    Write-Host ""
    Write-Host "사용 가능한 어댑터:" -ForegroundColor Yellow
    Get-NetAdapter | Select-Object Name, Status, LinkSpeed | Format-Table
}