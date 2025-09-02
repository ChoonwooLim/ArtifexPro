# Pop!_OS 원격 데스크톱 설정 가이드

## 🖥️ 개요
Windows PC에서 Pop!_OS의 화면을 원격으로 보고 제어할 수 있는 환경을 구축합니다.

## 📋 사전 요구사항
- SSH 연결 설정 완료 (이미 완료됨 ✅)
- Pop!_OS IP 주소: 192.168.1.100 (예시)
- 두 PC가 같은 네트워크에 연결됨

## 🚀 빠른 설정 (권장: NoMachine)

### NoMachine을 사용한 원격 연결 (최고 성능)

#### Pop!_OS에서:
```bash
# 스크립트 실행
cd ~/ArtifexPro/scripts
chmod +x setup-remote-desktop.sh
./setup-remote-desktop.sh
# 옵션 3 선택 (NoMachine)
```

#### Windows에서:
```powershell
# 관리자 권한 PowerShell에서 실행
cd C:\WORK\ArtifexPro\scripts
.\windows-remote-client-setup.ps1
# 옵션 3 선택 (NoMachine)
```

## 📊 연결 방법 비교

| 방법 | 성능 | 화질 | 설정 난이도 | 보안 | 용도 |
|------|------|------|------------|------|------|
| **NoMachine** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | AI 개발, 동영상 |
| VNC | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | 일반 작업 |
| xRDP | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | Windows 친화적 |

## 🔧 상세 설정

### 1. VNC (Virtual Network Computing)

#### Pop!_OS 설정:
```bash
# TigerVNC 서버 설치
sudo apt update
sudo apt install -y tigervnc-standalone-server

# VNC 비밀번호 설정
vncpasswd

# VNC 서버 시작
vncserver :1 -geometry 1920x1080 -depth 24

# 서비스로 등록 (자동 시작)
sudo systemctl enable vncserver@1.service
sudo systemctl start vncserver@1.service
```

#### Windows 연결:
1. TigerVNC Viewer 설치
2. 연결 주소: `192.168.1.100:5901`
3. 비밀번호 입력

### 2. xRDP (Windows Remote Desktop Protocol)

#### Pop!_OS 설정:
```bash
# xRDP 설치
sudo apt install -y xrdp xorgxrdp

# 포트 변경 (충돌 방지)
sudo sed -i 's/3389/3390/g' /etc/xrdp/xrdp.ini

# 서비스 시작
sudo systemctl enable xrdp
sudo systemctl restart xrdp
```

#### Windows 연결:
1. Windows 원격 데스크톱 연결 실행 (`mstsc`)
2. 컴퓨터: `192.168.1.100:3390`
3. 사용자명/비밀번호 입력

### 3. NoMachine (권장)

#### Pop!_OS 설정:
```bash
# NoMachine 다운로드 및 설치
wget https://download.nomachine.com/download/8.11/Linux/nomachine_8.11.3_4_amd64.deb
sudo dpkg -i nomachine_8.11.3_4_amd64.deb

# 서비스 확인
sudo /etc/NX/nxserver --status
```

#### Windows 연결:
1. [NoMachine 다운로드](https://www.nomachine.com/download)
2. 설치 후 실행
3. 새 연결 → `192.168.1.100:4000`
4. 사용자명/비밀번호 입력

## 🔒 보안 연결 (SSH 터널)

더 안전한 연결을 위해 SSH 터널을 사용할 수 있습니다:

```powershell
# Windows PowerShell에서
ssh -L 5901:localhost:5901 -L 4000:localhost:4000 popOS

# 이제 localhost로 연결
# VNC: localhost:5901
# NoMachine: localhost:4000
```

## ⚡ 성능 최적화

### NoMachine 최적화:
1. Display 설정에서:
   - Quality: 9 (최고 품질)
   - Resolution: Native
   - Hardware encoding 활성화

### VNC 최적화:
```bash
# Pop!_OS에서
vncserver -kill :1
vncserver :1 -geometry 1920x1080 -depth 24 -dpi 96
```

### 네트워크 최적화:
```bash
# Pop!_OS에서 MTU 크기 조정
sudo ip link set dev eth0 mtu 9000
```

## 🎮 GPU 가속 활성화

### NoMachine에서 GPU 가속:
```bash
# Pop!_OS에서
sudo nano /usr/NX/etc/node.cfg

# 다음 설정 추가/수정:
EnableHardwareAcceleration 1
EnableGLX 1
```

## 🔍 문제 해결

### 연결이 안 될 때:
```bash
# Pop!_OS에서 방화벽 확인
sudo ufw status
sudo ufw allow 5901/tcp  # VNC
sudo ufw allow 3390/tcp  # RDP
sudo ufw allow 4000/tcp  # NoMachine

# 서비스 상태 확인
sudo systemctl status vncserver@1
sudo systemctl status xrdp
sudo /etc/NX/nxserver --status
```

### 화면이 검은색일 때:
```bash
# Pop!_OS에서
export DISPLAY=:0
gnome-session --session=pop
```

### 느린 성능:
1. NoMachine으로 전환
2. 해상도 낮춤 (1280x720)
3. 색상 깊이 감소 (16bit)

## 📱 모바일에서 접속

### Android/iOS:
- VNC: RealVNC Viewer 앱
- RDP: Microsoft Remote Desktop 앱
- NoMachine: NoMachine 앱

## 🚦 상태 모니터링

```bash
# Pop!_OS에서 실시간 모니터링
watch -n 1 'netstat -an | grep -E "5901|3390|4000"'

# 연결된 세션 확인
who
w
```

## 💡 추천 시나리오

### AI 모델 학습 모니터링:
- **NoMachine** 사용 (GPU 상태 실시간 확인 가능)
- SSH 터널로 보안 강화
- 화질 우선 설정

### 코드 편집 및 개발:
- **VS Code Remote SSH** 사용 (이미 설정됨)
- 보조로 NoMachine 사용

### 시스템 관리:
- **xRDP** 사용 (Windows 친화적)
- 또는 SSH + tmux 조합

## 📝 자동화 스크립트

### 원격 데스크톱 자동 시작 (Pop!_OS):
```bash
# /etc/rc.local에 추가
#!/bin/bash
su - stevenlim -c "vncserver :1"
/etc/NX/nxserver --restart
exit 0
```

### Windows 자동 연결:
```powershell
# 시작 시 자동 연결
$action = New-ScheduledTaskAction -Execute "C:\Program Files\NoMachine\bin\nxplayer.exe" `
    -Argument "--session C:\Users\choon\Desktop\PopOS-NoMachine.nxs"
$trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "PopOS Remote"
```

## ✅ 체크리스트

- [ ] Pop!_OS에 원격 서버 설치
- [ ] Windows에 클라이언트 설치
- [ ] 방화벽 규칙 설정
- [ ] 연결 테스트
- [ ] 성능 최적화
- [ ] 보안 설정 (SSH 터널)
- [ ] 자동 시작 설정

## 🎯 다음 단계

1. **즉시 시작**: NoMachine 설치 및 연결
2. **보안 강화**: SSH 터널 설정
3. **성능 튜닝**: GPU 가속 활성화
4. **자동화**: 시작 시 자동 연결 설정