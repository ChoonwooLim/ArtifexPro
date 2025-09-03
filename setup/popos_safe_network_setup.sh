#!/bin/bash
# Pop!_OS 안전한 네트워크 설정 스크립트 (임시)
# 이 스크립트는 재부팅하면 초기화됩니다

echo "======================================"
echo "Pop!_OS 10Gbps Network Setup (Safe)"
echo "======================================"

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 네트워크 인터페이스 확인
echo -e "${YELLOW}Available network interfaces:${NC}"
ip link show | grep -E "^[0-9]+: " | grep -v "lo:"

# 2. enp1s0f0에 IP 설정 (임시)
echo -e "\n${YELLOW}Setting up enp1s0f0...${NC}"
echo "Jiyeon71391796!" | sudo -S ip addr add 10.0.0.2/24 dev enp1s0f0 2>/dev/null
echo "Jiyeon71391796!" | sudo -S ip link set enp1s0f0 mtu 9000
echo "Jiyeon71391796!" | sudo -S ip link set enp1s0f0 up

# 3. SSH 서비스 시작
echo -e "\n${YELLOW}Starting SSH service...${NC}"
echo "Jiyeon71391796!" | sudo -S systemctl start ssh
echo "Jiyeon71391796!" | sudo -S systemctl enable ssh

# 4. 방화벽 설정
echo -e "\n${YELLOW}Configuring firewall...${NC}"
echo "Jiyeon71391796!" | sudo -S ufw allow 22/tcp
echo "Jiyeon71391796!" | sudo -S ufw allow from 10.0.0.1

# 5. 상태 확인
echo -e "\n${GREEN}=== Current Status ===${NC}"
echo -e "${YELLOW}IP Address:${NC}"
ip addr show enp1s0f0 | grep inet

echo -e "\n${YELLOW}SSH Status:${NC}"
systemctl is-active ssh

echo -e "\n${YELLOW}Testing connection to Windows (10.0.0.1):${NC}"
ping -c 3 10.0.0.1

echo -e "\n${GREEN}Setup complete!${NC}"
echo "Windows can now connect using: ssh stevenlim@10.0.0.2"
echo ""
echo "⚠️  Note: This is TEMPORARY configuration"
echo "   It will reset after reboot"
echo "   For permanent setup, use GUI Network Settings"