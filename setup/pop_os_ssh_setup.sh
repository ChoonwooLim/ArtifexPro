#!/bin/bash
# Pop!_OS SSH 영구 설정 스크립트
# 실행: bash pop_os_ssh_setup.sh

echo "=== Pop!_OS SSH 영구 설정 시작 ==="

# 1. SSH 서비스 자동 시작 설정
echo "1. SSH 서비스 자동 시작 설정..."
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh --no-pager

# 2. 방화벽 영구 설정
echo "2. 방화벽 SSH 허용..."
sudo ufw allow ssh
sudo ufw --force enable
sudo ufw status

# 3. Avahi (mDNS) 설치 및 설정 - 호스트명으로 접속 가능하게
echo "3. Avahi mDNS 설치 및 설정..."
sudo apt update
sudo apt install -y avahi-daemon avahi-utils
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# 4. 호스트명 설정 (popOS-artifex로 고정)
echo "4. 호스트명 설정..."
CURRENT_HOSTNAME=$(hostname)
echo "현재 호스트명: $CURRENT_HOSTNAME"
sudo hostnamectl set-hostname popOS-artifex
echo "새 호스트명: popOS-artifex"

# 5. 네트워크 정보 저장
echo "5. 네트워크 정보 수집..."
echo "=== 네트워크 정보 ===" > ~/network_info.txt
echo "호스트명: $(hostname)" >> ~/network_info.txt
echo "호스트명.local: $(hostname).local" >> ~/network_info.txt
echo "IP 주소들:" >> ~/network_info.txt
ip addr show | grep "inet " | grep -v "127.0.0.1" >> ~/network_info.txt
echo "MAC 주소:" >> ~/network_info.txt
ip link show | grep "link/ether" >> ~/network_info.txt

# 6. SSH 키 권한 확인
echo "6. SSH 키 권한 설정..."
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/known_hosts 2>/dev/null || true

# 7. SSH 설정 백업
echo "7. SSH 설정 백업..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# 8. SSH 설정 최적화
echo "8. SSH 설정 최적화..."
sudo tee /etc/ssh/sshd_config.d/99-custom.conf > /dev/null <<EOF
# Custom SSH Configuration
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
ClientAliveInterval 60
ClientAliveCountMax 3
UseDNS no
EOF

# 9. SSH 서비스 재시작
echo "9. SSH 서비스 재시작..."
sudo systemctl restart ssh

# 10. 고정 IP 설정 (선택사항)
echo "10. 고정 IP 설정 안내..."
echo "=== 고정 IP 설정 (선택사항) ==="
echo "네트워크 관리자에서 고정 IP를 설정하려면:"
echo "1. Settings → Network → 유선/무선 설정 → IPv4"
echo "2. Manual 선택"
echo "3. Address: 192.168.1.100 (예시)"
echo "4. Netmask: 255.255.255.0"
echo "5. Gateway: 192.168.1.1 (라우터 IP)"
echo "6. DNS: 8.8.8.8, 8.8.4.4"

# 결과 출력
echo ""
echo "=== 설정 완료 ==="
echo "Windows에서 다음 방법으로 접속 가능:"
echo "1. ssh stevenlim@popOS-artifex.local"
echo "2. ssh stevenlim@$(hostname -I | awk '{print $1}')"
echo ""
echo "네트워크 정보가 ~/network_info.txt에 저장되었습니다."
cat ~/network_info.txt