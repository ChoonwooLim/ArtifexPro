# 10Gbps 연결 재부팅 후 유지 가이드

## ✅ Windows (이미 영구 설정됨)
- **IP**: 10.0.0.1
- **인터페이스**: 이더넷 3 (Intel X550)
- **상태**: ✅ 재부팅 후에도 자동 유지

## ⚠️ Pop!_OS (영구 설정 필요)

### 현재 상태
- **IP**: 10.0.0.2 (임시 설정)
- **인터페이스**: enp1s0f0
- **상태**: ⚠️ 재부팅하면 초기화됨

### 영구 설정 방법

#### 방법 1: 스크립트 실행 (권장) ✨
Pop!_OS 터미널에서:
```bash
# 1. 스크립트 복사 (Windows → Pop!_OS)
scp stevenlim@10.0.0.2:/home/stevenlim/apply_permanent_10gbps.sh ~/

# 2. 실행 권한 부여
chmod +x ~/apply_permanent_10gbps.sh

# 3. 스크립트 실행
./apply_permanent_10gbps.sh
```

#### 방법 2: 직접 명령 실행
Pop!_OS 터미널에서:
```bash
echo "Jiyeon71391796!" | sudo -S bash -c 'cat > /etc/netplan/10-direct.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0f0:
      dhcp4: no
      addresses:
        - 10.0.0.2/24
      mtu: 9000
EOF
chmod 600 /etc/netplan/10-direct.yaml
netplan apply'
```

## 🔄 재부팅 테스트

### Pop!_OS 재부팅
```bash
sudo reboot
```

### Windows에서 연결 확인
```powershell
# PowerShell에서
popOS
# 또는
Test-PopOS
```

## ✅ 설정 완료 확인 사항

### Windows
- [x] PowerShell 프로필 업데이트 완료
- [x] SSH config 파일 업데이트 완료
- [x] 10.0.0.1 IP 영구 설정 완료
- [x] 방화벽 예외 설정 완료

### Pop!_OS (설정 후)
- [ ] Netplan 설정 파일 생성 (/etc/netplan/10-direct.yaml)
- [ ] SSH 서비스 자동 시작 설정
- [ ] 10.0.0.2 IP 영구 설정
- [ ] MTU 9000 (Jumbo Frames) 설정

## 📊 성능
- **속도**: 10Gbps
- **지연시간**: <1ms
- **MTU**: 9000 (Jumbo Frames)

## 🚀 빠른 연결
Windows PowerShell/Terminal에서:
```powershell
popOS
```

## 📝 참고사항
- Windows 설정은 이미 영구적입니다
- Pop!_OS만 위 방법으로 영구 설정하면 됩니다
- 재부팅 후에도 자동으로 연결됩니다