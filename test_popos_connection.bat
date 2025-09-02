@echo off
echo ========================================
echo ArtifexPro Pop!_OS Connection Test
echo ========================================
echo.

echo [1] Testing SSH Connection...
ssh popOS "echo 'SSH OK' && hostname" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo    [OK] SSH Connected
) else (
    echo    [FAIL] SSH Connection Failed
)

echo.
echo [2] Testing Ray Dashboard...
curl -s http://192.168.219.150:8265 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Ray Dashboard Available
) else (
    echo    [WARN] Ray Dashboard Not Available
)

echo.
echo [3] Testing Backend API...
curl -s http://192.168.219.150:8002/ >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Backend API Running
    echo    URL: http://192.168.219.150:8002
) else (
    echo    [FAIL] Backend API Not Running
)

echo.
echo [4] Quick System Info:
ssh popOS "nvidia-smi --query-gpu=name,memory.free --format=csv,noheader" 2>nul

echo.
echo ========================================
echo Test Complete!
echo ========================================
pause