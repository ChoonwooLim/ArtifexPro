# Pop!_OS SSH 자동 연결 설정 가이드

## 🚀 빠른 설정 (3단계)

### 1️⃣ Pop!_OS에서 실행
```bash
# SSH로 Pop!_OS 접속 후
cd /path/to/ArtifexPro/setup
bash pop_os_ssh_setup.sh
```

### 2️⃣ Windows에서 실행 (관리자 PowerShell)
```powershell
cd C:\WORK\ArtifexPro\setup
powershell -ExecutionPolicy Bypass -File windows_ssh_config.ps1
```

### 3️⃣ 연결 테스트
```powershell
# PowerShell에서
Connect-PopOS
# 또는
ssh popOS
```

## 📋 설정 내용

### Pop!_OS 설정 (pop_os_ssh_setup.sh)
- ✅ SSH 서비스 자동 시작 설정
- ✅ 방화벽 SSH 포트 허용
- ✅ Avahi mDNS 설치 (호스트명.local 접속)
- ✅ 호스트명을 `popOS-artifex`로 고정
- ✅ SSH 키 권한 자동 설정
- ✅ SSH 연결 유지 설정 (timeout 방지)

### Windows 설정 (windows_ssh_config.ps1)
- ✅ SSH config 파일 자동 생성
- ✅ 여러 연결 방법 설정
- ✅ PowerShell 함수 추가 (`Connect-PopOS`, `Find-PopOS`)
- ✅ 바탕화면에 빠른 연결 파일 생성
- ✅ 자동 IP 검색 기능

## 🔗 연결 방법 (5가지)

재부팅 후에도 다음 방법들로 연결 가능:

### 방법 1: PowerShell 함수
```powershell
popOS
# 또는
Connect-PopOS
```

### 방법 2: SSH 명령
```bash
ssh popOS
ssh popOS-artifex.local
ssh stevenlim@popOS-artifex.local
```

### 방법 3: 바탕화면 바로가기
- `Connect_PopOS.bat` 더블클릭

### 방법 4: IP 직접 연결
```bash
ssh stevenlim@192.168.1.100  # IP는 변경될 수 있음
```

### 방법 5: IP 자동 검색
```powershell
# Pop!_OS IP 찾기
Find-PopOS
```

## 🔧 문제 해결

### 연결이 안 될 때
1. **Pop!_OS 상태 확인**
   - Pop!_OS가 켜져 있는지 확인
   - 같은 네트워크(WiFi/LAN)에 연결되어 있는지 확인

2. **IP 주소 찾기**
   ```powershell
   # Windows PowerShell에서
   Find-PopOS
   ```

3. **수동으로 IP 확인** (Pop!_OS에서)
   ```bash
   hostname -I
   ip addr show
   ```

4. **Windows hosts 파일 업데이트** (관리자 권한)
   ```powershell
   # 예: IP가 192.168.1.105인 경우
   Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.105 popOS-artifex popOS-artifex.local"
   ```

### 고정 IP 설정 (권장)
Pop!_OS에서 고정 IP 설정하면 더 안정적:
1. Settings → Network → 유선/무선 설정
2. IPv4 → Manual
3. Address: `192.168.1.100` (예시)
4. Netmask: `255.255.255.0`
5. Gateway: `192.168.1.1` (라우터 IP)
6. DNS: `8.8.8.8, 8.8.4.4`

## 📌 주요 파일 위치

### Pop!_OS
- SSH 설정: `/etc/ssh/sshd_config.d/99-custom.conf`
- SSH 키: `~/.ssh/authorized_keys`
- 네트워크 정보: `~/network_info.txt`

### Windows
- SSH config: `C:\Users\[사용자명]\.ssh\config`
- PowerShell 프로필: `$PROFILE`
- Hosts 파일: `C:\Windows\System32\drivers\etc\hosts`
- 빠른 연결: `바탕화면\Connect_PopOS.bat`

## ✨ 추가 기능

### 자동 재연결
연결이 끊어져도 자동으로 재연결 시도:
- ServerAliveInterval: 60초마다 연결 확인
- ServerAliveCountMax: 3회 실패 시 연결 종료

### mDNS 지원
IP가 변경되어도 호스트명으로 접속 가능:
- `popOS-artifex.local` 사용
- Bonjour/Avahi 서비스 필요

## 📝 참고사항
- 두 PC가 같은 네트워크에 있어야 함
- 방화벽에서 SSH(포트 22) 허용 필요
- Pop!_OS 재부팅 후 SSH 서비스는 자동 시작됨
- Windows 재부팅 후에도 설정은 유지됨