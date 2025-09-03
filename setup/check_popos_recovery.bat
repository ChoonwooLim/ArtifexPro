@echo off
title Pop!_OS Recovery Check
color 0A
echo ==========================================
echo     Pop!_OS 복구 상태 체크
echo ==========================================
echo.

:MENU
echo [1] 기존 네트워크 (192.168.219.150) 체크
echo [2] 10Gbps 직접 연결 (10.0.0.2) 체크
echo [3] 양쪽 모두 체크
echo [4] 종료
echo.
set /p choice="선택 (1-4): "

if "%choice%"=="1" goto OLD_NETWORK
if "%choice%"=="2" goto DIRECT_10G
if "%choice%"=="3" goto BOTH
if "%choice%"=="4" exit

:OLD_NETWORK
echo.
echo === 기존 네트워크 체크 ===
ping -n 2 192.168.219.150
if %errorlevel% == 0 (
    echo.
    color 0A
    echo [성공] Pop!_OS가 기존 네트워크로 응답합니다!
    echo SSH 연결: ssh stevenlim@192.168.219.150
    echo.
    echo 문제 파일 삭제 명령:
    echo sudo rm /etc/netplan/10-direct.yaml
) else (
    color 0C
    echo [실패] 응답 없음
)
echo.
pause
cls
goto MENU

:DIRECT_10G
echo.
echo === 10Gbps 직접 연결 체크 ===
ping -n 2 10.0.0.2
if %errorlevel% == 0 (
    echo.
    color 0A
    echo [성공] Pop!_OS가 10Gbps로 응답합니다!
    echo SSH 연결: ssh popOS
) else (
    color 0C
    echo [실패] 응답 없음 - 10Gbps 카드 제거 필요
)
echo.
pause
cls
goto MENU

:BOTH
echo.
echo === 모든 네트워크 체크 중... ===
echo.
echo [1/2] 기존 네트워크 (192.168.219.150)...
ping -n 1 -w 1000 192.168.219.150 >nul 2>&1
if %errorlevel% == 0 (
    echo      ✓ 연결됨
    set OLD_NET=OK
) else (
    echo      ✗ 연결 안됨
    set OLD_NET=FAIL
)

echo [2/2] 10Gbps 직접 연결 (10.0.0.2)...
ping -n 1 -w 1000 10.0.0.2 >nul 2>&1
if %errorlevel% == 0 (
    echo      ✓ 연결됨
    set DIRECT_NET=OK
) else (
    echo      ✗ 연결 안됨
    set DIRECT_NET=FAIL
)

echo.
echo ==========================================
if "%OLD_NET%"=="OK" (
    color 0A
    echo 기존 네트워크로 연결 가능!
    echo ssh stevenlim@192.168.219.150
) else if "%DIRECT_NET%"=="OK" (
    color 0A
    echo 10Gbps로 연결 가능!
    echo ssh popOS
) else (
    color 0C
    echo 모든 연결 실패 - 하드웨어 복구 필요
    echo.
    echo 해야 할 일:
    echo 1. 10Gbps 카드 제거
    echo 2. CMOS 리셋
    echo 3. 최소 하드웨어로 부팅
)
echo ==========================================
echo.
pause
cls
goto MENU