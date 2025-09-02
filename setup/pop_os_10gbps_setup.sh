#!/bin/bash
# Pop!_OS 10Gbps 직접 연결 설정
# Windows와 10Gbps로 직접 연결

echo "=== Pop!_OS 10Gbps 직접 연결 설정 ==="
echo ""
echo "Windows IP: 10.0.0.1"
echo "Pop!_OS IP: 10.0.0.2"
echo ""

# 비밀번호
PASSWORD="Jiyeon71391796!"

# 1. 네트워크 인터페이스 찾기
echo "1. 네트워크 인터페이스 확인..."
ip link show | grep -E "^[0-9]+: " | grep -v "lo:"

# 10Gbps 인터페이스 자동 감지 (보통 enp로 시작)
INTERFACE=$(ip link show | grep -E "^[0-9]+: enp" | head -1 | cut -d: -f2 | tr -d ' ')

if [ -z "$INTERFACE" ]; then
    echo "네트워크 인터페이스를 찾을 수 없습니다!"
    echo "수동으로 설정하세요:"
    echo "  INTERFACE=enp5s0  (예시)"
    read -p "인터페이스 이름 입력: " INTERFACE
fi

echo "사용할 인터페이스: $INTERFACE"
echo ""

# 2. 기존 네트워크 설정 백업
echo "2. 기존 설정 백업..."
echo $PASSWORD | sudo -S cp -r /etc/netplan /etc/netplan.backup.$(date +%Y%m%d) 2>/dev/null

# 3. 새 네트워크 설정 생성
echo "3. 10Gbps 직접 연결 설정..."
echo $PASSWORD | sudo -S bash -c "cat > /etc/netplan/10-direct-10gbps.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - 10.0.0.2/24
      mtu: 9000
EOF"

# 4. Netplan 적용
echo "4. 네트워크 설정 적용..."
echo $PASSWORD | sudo -S netplan apply

# 5. 설정 확인
echo "5. IP 설정 확인..."
ip addr show $INTERFACE | grep inet
echo ""

# 6. SSH 설치 및 시작
echo "6. SSH 서비스 설정..."
echo $PASSWORD | sudo -S apt update
echo $PASSWORD | sudo -S apt install -y openssh-server
echo $PASSWORD | sudo -S systemctl stop ssh
echo $PASSWORD | sudo -S systemctl start ssh
echo $PASSWORD | sudo -S systemctl enable ssh

# 7. 방화벽 설정
echo "7. 방화벽 설정..."
echo $PASSWORD | sudo -S ufw allow from 10.0.0.1 to any port 22
echo $PASSWORD | sudo -S ufw --force enable

# 8. SSH 상태 확인
echo "8. SSH 서비스 상태..."
echo $PASSWORD | sudo -S systemctl status ssh --no-pager | head -10

# 9. 연결 테스트
echo ""
echo "9. Windows로 ping 테스트..."
ping -c 3 10.0.0.1

echo ""
echo "=== 설정 완료! ==="
echo ""
echo "Windows에서 연결:"
echo "  ping 10.0.0.2"
echo "  ssh stevenlim@10.0.0.2"
echo ""
echo "비밀번호: Jiyeon71391796!"
echo ""

# 10. 성능 테스트 준비
echo "성능 테스트 도구 설치 (선택):"
echo "  sudo apt install iperf3"
echo "  iperf3 -s  # 서버 시작"