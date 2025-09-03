@echo off
echo ========================================
echo   10Gbps Connection Test
echo ========================================
echo.

echo [1] Testing ping to Pop!_OS (10.0.0.2)...
ping -n 4 10.0.0.2

echo.
echo [2] Testing SSH connection...
powershell -Command "Test-PopOS"

echo.
echo [3] If successful, connect with:
echo     ssh popOS
echo     or
echo     powershell -Command Connect-PopOS
echo.
pause