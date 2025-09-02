# 🚀 Pop!_OS 자동 시작 설정 가이드

## 📋 설정 완료 사항

### 1. Crontab 자동 시작 (✅ 설정 완료)
재부팅 시 자동으로 실행되는 서비스:
- **Ray Cluster**: 30초 후 시작
- **Backend API**: 45초 후 시작

### 2. 생성된 스크립트들

#### Pop!_OS에 생성된 파일들:
```bash
~/ArtifexPro/
├── setup_autostart.sh    # systemd 서비스 설정 (sudo 필요)
├── setup_crontab.sh       # crontab 자동 시작 설정 (✅ 완료)
├── check_status.sh        # 시스템 상태 확인
├── start_ray.sh          # Ray 클러스터 시작
└── start_api.sh          # Backend API 시작
```

#### Windows에 생성된 파일:
```
C:\WORK\ArtifexPro\
├── test_popos_connection.bat  # 연결 테스트
└── scripts\test-popos-connection.ps1  # PowerShell 테스트
```

## 🔧 사용 방법

### Pop!_OS 재부팅 후 확인

1. **상태 확인** (SSH 연결 후):
```bash
cd ~/ArtifexPro
./check_status.sh
```

2. **수동 시작** (필요 시):
```bash
# Ray 클러스터
./start_ray.sh

# Backend API
./start_api.sh
```

3. **로그 확인**:
```bash
# 시작 로그
tail -f ~/ArtifexPro/logs/ray_startup.log
tail -f ~/ArtifexPro/logs/api_startup.log
```

### Windows에서 테스트

1. **배치 파일 실행**:
```cmd
test_popos_connection.bat
```

2. **PowerShell 테스트**:
```powershell
.\scripts\test-popos-connection.ps1
```

## 📊 시스템 정보

### 네트워크 설정
- **Pop!_OS IP**: 192.168.219.150
- **Windows IP**: 192.168.219.104
- **SSH User**: stevenlim

### 포트 정보
- **22**: SSH
- **6379**: Ray Cluster
- **8002**: Backend API
- **8265**: Ray Dashboard

## 🛠️ 문제 해결

### 재부팅 후 서비스가 시작되지 않을 때

1. **Crontab 확인**:
```bash
crontab -l
```

2. **수동 시작**:
```bash
cd ~/ArtifexPro
source venv/bin/activate
ray start --head --port=6379 --dashboard-host=0.0.0.0 --num-gpus=1
python backend/simple_api.py &
```

3. **Systemd 서비스 설정** (sudo 권한 있을 때):
```bash
cd ~/ArtifexPro
bash setup_autostart.sh
# 암호 입력 필요
```

### Windows에서 연결 실패 시

1. **IP 주소 변경 확인**:
```bash
ssh popOS "hostname -I"
```

2. **방화벽 확인**:
```bash
ssh popOS "sudo ufw status"
```

3. **서비스 상태 확인**:
```bash
ssh popOS "~/ArtifexPro/check_status.sh"
```

## ✅ 설정 완료 확인

재부팅 후 다음 사항이 자동으로 작동해야 함:

- [ ] SSH 접속 가능
- [ ] Ray Cluster 실행 중
- [ ] Backend API 응답 (http://192.168.219.150:8002)
- [ ] GPU 인식 (RTX 3090 24GB)

## 📝 추가 설정 (선택사항)

### IP 고정 설정
Pop!_OS의 IP가 변경되지 않도록 라우터에서 DHCP 예약 설정 권장

### 성능 최적화
```bash
# GPU 성능 모드 설정
sudo nvidia-smi -pm 1
sudo nvidia-smi -pl 350  # Power limit 350W
```

### 모니터링
```bash
# GPU 모니터링
watch -n 1 nvidia-smi

# Ray 모니터링
ray status
```

---

**마지막 업데이트**: 2025-09-02
**설정 상태**: ✅ Crontab 자동 시작 설정 완료