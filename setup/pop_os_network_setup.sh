#!/bin/bash
# Pop!_OS Ethernet Fixed IP Configuration
# Interface: enp1s0f1
# Fixed IP: 192.168.219.150

echo "=== Pop!_OS 네트워크 설정 ==="
echo "인터페이스: enp1s0f1"
echo "고정 IP: 192.168.219.150"
echo ""

# 1. 현재 네트워크 상태 확인
echo "1. 현재 네트워크 상태..."
ip addr show enp1s0f1
echo ""

# 2. Netplan 설정 파일 생성 (Pop!_OS는 Ubuntu 기반이므로 Netplan 사용)
echo "2. Netplan 설정 파일 생성..."
sudo tee /etc/netplan/01-ethernet-fixed.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0f1:
      dhcp4: no
      addresses:
        - 192.168.219.150/24
      gateway4: 192.168.219.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF

echo "Netplan 설정 파일 생성 완료"
echo ""

# 3. Netplan 적용
echo "3. Netplan 설정 적용..."
sudo netplan apply
echo "네트워크 설정 적용 완료"
echo ""

# 4. SSH 서비스 확인 및 시작
echo "4. SSH 서비스 상태 확인..."
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh --no-pager
echo ""

# 5. 방화벽 설정
echo "5. 방화벽 SSH 허용..."
sudo ufw allow ssh
sudo ufw --force enable
sudo ufw status
echo ""

# 6. 호스트명 설정
echo "6. 호스트명 설정..."
sudo hostnamectl set-hostname popOS-artifex
echo "호스트명: $(hostname)"
echo ""

# 7. Avahi (mDNS) 설정
echo "7. Avahi mDNS 서비스 설정..."
if ! command -v avahi-daemon &> /dev/null; then
    echo "Avahi 설치..."
    sudo apt update
    sudo apt install -y avahi-daemon avahi-utils
fi
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon
echo "mDNS 서비스 활성화 완료"
echo ""

# 8. 네트워크 정보 저장
echo "8. 네트워크 정보 저장..."
cat > ~/network_info.txt <<EOF
=== Pop!_OS 네트워크 정보 ===
날짜: $(date)
호스트명: $(hostname)
인터페이스: enp1s0f1
고정 IP: 192.168.219.150
게이트웨이: 192.168.219.1
DNS: 8.8.8.8, 8.8.4.4

현재 IP 주소:
$(ip addr show enp1s0f1 | grep inet)

라우팅 테이블:
$(ip route)

SSH 서비스 상태:
$(systemctl is-active ssh)

Windows에서 연결:
ssh stevenlim@192.168.219.150
ssh stevenlim@popOS-artifex.local
EOF

echo "네트워크 정보가 ~/network_info.txt에 저장되었습니다."
cat ~/network_info.txt
echo ""

# 9. 연결 테스트
echo "9. 연결 테스트..."
echo "게이트웨이 ping 테스트..."
ping -c 3 192.168.219.1
echo ""
echo "외부 연결 테스트..."
ping -c 3 8.8.8.8
echo ""

echo "=== 설정 완료 ==="
echo "고정 IP: 192.168.219.150"
echo "Windows에서 연결: ssh stevenlim@192.168.219.150"
echo "또는: ssh popOS"