# Windows 10Gbps IP 설정 수정 스크립트
# 관리자 PowerShell에서 실행

Write-Host "=== 10Gbps IP 설정 수정 ===" -ForegroundColor Green
Write-Host ""

# 관리자 권한 확인
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (!$isAdmin) {
    Write-Host "❌ 관리자 권한이 필요합니다!" -ForegroundColor Red
    Write-Host "PowerShell을 관리자 권한으로 다시 실행하세요." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "✅ 관리자 권한 확인됨" -ForegroundColor Green
Write-Host ""

# 현재 상태 확인
Write-Host "현재 이더넷 3 상태:" -ForegroundColor Yellow
Get-NetIPAddress -InterfaceAlias "이더넷 3" -ErrorAction SilentlyContinue | Format-Table IPAddress, PrefixLength

# 기존 IP 제거
Write-Host "기존 IP 설정 제거..." -ForegroundColor Yellow
Remove-NetIPAddress -InterfaceAlias "이더넷 3" -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias "이더넷 3" -Confirm:$false -ErrorAction SilentlyContinue

# DHCP 비활성화 및 고정 IP 설정
Write-Host "10.0.0.1 설정 중..." -ForegroundColor Yellow
Set-NetIPInterface -InterfaceAlias "이더넷 3" -Dhcp Disabled
New-NetIPAddress -InterfaceAlias "이더넷 3" -IPAddress "10.0.0.1" -PrefixLength 24 -Type Unicast

# MTU 설정
Write-Host "MTU 9000 설정..." -ForegroundColor Yellow
Set-NetAdapterAdvancedProperty -Name "이더넷 3" -RegistryKeyword "*JumboPacket" -RegistryValue 9014 -ErrorAction SilentlyContinue

# 확인
Write-Host ""
Write-Host "✅ 설정 완료!" -ForegroundColor Green
Write-Host ""
Write-Host "새 IP 설정:" -ForegroundColor Green
Get-NetIPAddress -InterfaceAlias "이더넷 3" -AddressFamily IPv4 | Format-Table IPAddress, PrefixLength

Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Cyan
Write-Host "1. Pop!_OS에서 IP를 10.0.0.2로 설정" -ForegroundColor White
Write-Host "2. ping 10.0.0.2 테스트" -ForegroundColor White
Write-Host "3. ssh stevenlim@10.0.0.2" -ForegroundColor White