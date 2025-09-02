@echo off
echo === Windows 10Gbps IP 설정 ===
echo.

REM 관리자 권한 확인
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 관리자 권한이 필요합니다!
    echo 이 파일을 우클릭하고 "관리자 권한으로 실행"을 선택하세요.
    pause
    exit /b 1
)

echo 10Gbps 어댑터 (이더넷 3)에 IP 설정 중...
echo.

REM 기존 IP 제거
netsh interface ip set address "이더넷 3" dhcp >nul 2>&1

REM 새 IP 설정
netsh interface ip set address "이더넷 3" static 10.0.0.1 255.255.255.0

REM MTU 설정
netsh interface ipv4 set subinterface "이더넷 3" mtu=9000 store=persistent

echo 설정 완료!
echo.
echo 현재 설정:
netsh interface ip show addresses "이더넷 3"
echo.
echo ========================================
echo Pop!_OS 설정 후 테스트:
echo   ping 10.0.0.2
echo   ssh stevenlim@10.0.0.2
echo ========================================
pause