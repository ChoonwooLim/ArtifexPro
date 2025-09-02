# Windows SSH 설정 스크립트
# 관리자 권한으로 실행 필요
# 실행: powershell -ExecutionPolicy Bypass -File windows_ssh_config.ps1

Write-Host "=== Windows SSH 설정 시작 ===" -ForegroundColor Green

# 1. mDNS 지원 확인 (Bonjour 서비스)
Write-Host "1. mDNS(Bonjour) 서비스 확인..." -ForegroundColor Yellow
$bonjourService = Get-Service -Name "Bonjour Service" -ErrorAction SilentlyContinue
if ($bonjourService) {
    Write-Host "   Bonjour 서비스가 설치되어 있습니다." -ForegroundColor Green
} else {
    Write-Host "   Bonjour 서비스가 없습니다. iTunes 또는 Bonjour Print Services 설치를 권장합니다." -ForegroundColor Yellow
    Write-Host "   다운로드: https://support.apple.com/downloads/bonjour-print-services-windows" -ForegroundColor Cyan
}

# 2. SSH config 파일 생성/업데이트
Write-Host "`n2. SSH config 파일 설정..." -ForegroundColor Yellow
$sshConfigPath = "$env:USERPROFILE\.ssh\config"
$sshDir = "$env:USERPROFILE\.ssh"

# .ssh 디렉토리 생성
if (!(Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    Write-Host "   .ssh 디렉토리 생성됨" -ForegroundColor Green
}

# 기존 config 백업
if (Test-Path $sshConfigPath) {
    $backupPath = "$sshConfigPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $sshConfigPath $backupPath
    Write-Host "   기존 config 백업: $backupPath" -ForegroundColor Green
}

# SSH config 내용 준비
$sshConfig = @"
# Pop!_OS ArtifexPro Server - 여러 방법으로 접속 가능
Host popOS popOS-artifex popOS-artifex.local
    HostName popOS-artifex.local
    User stevenlim
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# IP 주소로 직접 접속 (IP가 변경되면 수정 필요)
Host popOS-ip
    HostName 192.168.1.100
    User stevenlim
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
"@

# config 파일에 쓰기
$sshConfig | Out-File -FilePath $sshConfigPath -Encoding UTF8 -Force
Write-Host "   SSH config file created/updated" -ForegroundColor Green

# 3. hosts 파일 업데이트 (관리자 권한 필요)
Write-Host "`n3. hosts 파일 설정 확인..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($isAdmin) {
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $hostsBackup = "$env:SystemRoot\System32\drivers\etc\hosts.backup.$(Get-Date -Format 'yyyyMMdd')"
    
    # hosts 파일 백업
    Copy-Item $hostsPath $hostsBackup -Force
    Write-Host "   hosts 파일 백업: $hostsBackup" -ForegroundColor Green
    
    # hosts 파일에서 기존 popOS 엔트리 제거
    $hostsContent = Get-Content $hostsPath | Where-Object { $_ -notmatch "popOS" }
    
    # 새 엔트리 추가 (IP 주소는 나중에 업데이트 필요)
    $newEntry = "`n# Pop!_OS ArtifexPro Server`n# IP 주소는 Pop!_OS에서 'hostname -I' 명령으로 확인 후 수정`n# 192.168.1.100 popOS-artifex popOS-artifex.local"
    
    ($hostsContent -join "`n") + $newEntry | Set-Content $hostsPath -Encoding UTF8
    Write-Host "   hosts 파일에 popOS 엔트리 추가됨 (IP 주소 수동 설정 필요)" -ForegroundColor Yellow
} else {
    Write-Host "   관리자 권한이 필요합니다. hosts 파일을 수동으로 편집하세요." -ForegroundColor Yellow
    Write-Host "   파일 위치: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Cyan
}

# 4. 연결 테스트 함수 생성
Write-Host "`n4. PowerShell 프로필에 함수 추가..." -ForegroundColor Yellow

$profileContent = @'

# Pop!_OS SSH 연결 함수
function Connect-PopOS {
    Write-Host "Pop!_OS 연결 시도..." -ForegroundColor Green
    
    # 방법 1: mDNS (.local) 사용
    Write-Host "1. mDNS로 연결 시도 (popOS-artifex.local)..." -ForegroundColor Yellow
    ssh -o ConnectTimeout=5 popOS-artifex.local 2>$null
    if ($LASTEXITCODE -eq 0) { return }
    
    # 방법 2: 호스트명으로 시도
    Write-Host "2. 호스트명으로 연결 시도 (popOS)..." -ForegroundColor Yellow
    ssh -o ConnectTimeout=5 popOS 2>$null
    if ($LASTEXITCODE -eq 0) { return }
    
    # 방법 3: IP 스캔 (192.168.1.x 대역)
    Write-Host "3. 네트워크에서 Pop!_OS 검색 중..." -ForegroundColor Yellow
    $subnet = "192.168.1"
    for ($i = 100; $i -le 110; $i++) {
        $ip = "$subnet.$i"
        Write-Host "   $ip 확인 중..." -NoNewline
        $result = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($result) {
            Write-Host " 응답!" -ForegroundColor Green
            Write-Host "   SSH 연결 시도: $ip" -ForegroundColor Cyan
            ssh stevenlim@$ip
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n성공! 다음에 빠른 연결을 위해 hosts 파일 업데이트를 권장합니다." -ForegroundColor Green
                Write-Host "관리자 PowerShell에서: Add-Content C:\Windows\System32\drivers\etc\hosts '$ip popOS-artifex popOS-artifex.local'" -ForegroundColor Cyan
                return
            }
        } else {
            Write-Host " 응답 없음" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n연결 실패. Pop!_OS가 켜져 있고 같은 네트워크에 있는지 확인하세요." -ForegroundColor Red
}

# 별칭 설정
Set-Alias -Name popOS -Value Connect-PopOS

# Pop!_OS IP 찾기 함수
function Find-PopOS {
    Write-Host "네트워크에서 Pop!_OS 검색 중..." -ForegroundColor Green
    $subnet = "192.168.1"
    $found = $false
    
    for ($i = 1; $i -le 254; $i++) {
        $ip = "$subnet.$i"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            Write-Host "장치 발견: $ip" -ForegroundColor Yellow
            # SSH 포트 확인
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            try {
                $tcpClient.ConnectAsync($ip, 22).Wait(100) | Out-Null
                if ($tcpClient.Connected) {
                    Write-Host "  -> SSH 서버 발견! $ip" -ForegroundColor Green
                    $found = $true
                    $tcpClient.Close()
                    
                    # 연결 테스트
                    Write-Host "  -> 연결 테스트 중..." -ForegroundColor Cyan
                    ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no stevenlim@$ip "hostname" 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  -> Pop!_OS 확인됨! IP: $ip" -ForegroundColor Green
                        return $ip
                    }
                }
            } catch {
                # 연결 실패는 무시
            }
        }
    }
    
    if (!$found) {
        Write-Host "SSH 서버를 찾을 수 없습니다." -ForegroundColor Red
    }
}
'@

# PowerShell 프로필에 추가
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# 기존 프로필에서 Pop!_OS 관련 함수 제거
$existingProfile = Get-Content $PROFILE -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch "Pop!?OS" }
($existingProfile -join "`n") + "`n" + $profileContent | Set-Content $PROFILE -Encoding UTF8

Write-Host "   PowerShell 프로필 업데이트 완료" -ForegroundColor Green

# 5. 빠른 연결 배치 파일 생성
Write-Host "`n5. 바탕화면에 빠른 연결 파일 생성..." -ForegroundColor Yellow

$desktopPath = [Environment]::GetFolderPath("Desktop")
$batchContent = @'
@echo off
title Pop!_OS SSH Connection
echo === Pop!_OS SSH Connection ===
echo.
echo Attempting connection...
echo.

REM Method 1: mDNS
echo [1] Trying mDNS (popOS-artifex.local)...
ssh -o ConnectTimeout=5 stevenlim@popOS-artifex.local
if %errorlevel% == 0 goto :end

REM Method 2: SSH config
echo [2] Trying SSH config (popOS)...
ssh -o ConnectTimeout=5 popOS
if %errorlevel% == 0 goto :end

REM Method 3: Direct IP
echo [3] Trying direct IP...
echo     If IP unknown, run Find-PopOS in PowerShell
ssh stevenlim@192.168.1.100
if %errorlevel% == 0 goto :end

echo.
echo Connection failed! Check if Pop!_OS is running.
echo Use Find-PopOS command in PowerShell to find IP.
pause

:end
'@

$batchPath = "$desktopPath\Connect_PopOS.bat"
$batchContent | Out-File -FilePath $batchPath -Encoding ASCII
Write-Host "   Desktop shortcut created: Connect_PopOS.bat" -ForegroundColor Green

# 6. 테스트 및 안내
Write-Host "`n=== 설정 완료 ===" -ForegroundColor Green
Write-Host ""
Write-Host "사용 가능한 연결 방법:" -ForegroundColor Cyan
Write-Host "1. PowerShell: popOS" -ForegroundColor White
Write-Host "2. PowerShell: Connect-PopOS" -ForegroundColor White
Write-Host "3. CMD/PowerShell: ssh popOS" -ForegroundColor White
Write-Host "4. CMD/PowerShell: ssh popOS-artifex.local" -ForegroundColor White
Write-Host "5. 바탕화면: Connect_PopOS.bat 더블클릭" -ForegroundColor White
Write-Host ""
Write-Host "Pop!_OS IP 찾기:" -ForegroundColor Cyan
Write-Host "PowerShell: Find-PopOS" -ForegroundColor White
Write-Host ""
Write-Host "주의사항:" -ForegroundColor Yellow
Write-Host "- Pop!_OS와 Windows가 같은 네트워크에 있어야 합니다" -ForegroundColor White
Write-Host "- Pop!_OS에서 pop_os_ssh_setup.sh 스크립트를 먼저 실행하세요" -ForegroundColor White
Write-Host "- IP가 자주 변경되면 Pop!_OS에 고정 IP 설정을 권장합니다" -ForegroundColor White

# 현재 세션에서 함수 로드
. $PROFILE 2>$null

Write-Host "`nTo test now, type 'Connect-PopOS'" -ForegroundColor Green