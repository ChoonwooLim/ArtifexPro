#!/bin/bash
# Pop!_OS 10Gbps 영구 설정 스크립트
# Windows → Pop!_OS 직접 연결 (10Gbps)

echo "========================================="
echo "Pop!_OS 10Gbps 영구 설정 적용"
echo "========================================="

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 패스워드
PASSWORD="Jiyeon71391796!"

# 1. 현재 설정 확인
echo -e "${YELLOW}현재 네트워크 설정 확인...${NC}"
ip addr show enp1s0f0 | grep "10.0.0.2"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 10.0.0.2 IP가 이미 설정되어 있습니다.${NC}"
else
    echo -e "${RED}✗ 10.0.0.2 IP가 설정되지 않았습니다.${NC}"
fi

# 2. Netplan 설정 생성
echo -e "\n${YELLOW}Netplan 영구 설정 적용 중...${NC}"
echo "$PASSWORD" | sudo -S bash -c 'cat > /etc/netplan/10-direct.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0f0:
      dhcp4: no
      addresses:
        - 10.0.0.2/24
      mtu: 9000
EOF'

# 3. 권한 설정
echo "$PASSWORD" | sudo -S chmod 600 /etc/netplan/10-direct.yaml

# 4. Netplan 적용
echo -e "${YELLOW}Netplan 설정 적용...${NC}"
echo "$PASSWORD" | sudo -S netplan apply

# 5. SSH 서비스 자동 시작 설정
echo -e "\n${YELLOW}SSH 서비스 자동 시작 설정...${NC}"
echo "$PASSWORD" | sudo -S systemctl enable ssh
echo "$PASSWORD" | sudo -S systemctl start ssh

# 6. 설정 확인
echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}설정 완료! 확인 중...${NC}"
echo -e "${GREEN}=========================================${NC}"

# IP 확인
echo -e "\n${YELLOW}1. IP 주소 확인:${NC}"
ip addr show enp1s0f0 | grep inet

# SSH 상태 확인
echo -e "\n${YELLOW}2. SSH 서비스 상태:${NC}"
systemctl is-enabled ssh
systemctl is-active ssh

# Windows 연결 테스트
echo -e "\n${YELLOW}3. Windows(10.0.0.1) 연결 테스트:${NC}"
ping -c 3 10.0.0.1

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ 모든 설정이 완료되었습니다!${NC}"
echo -e "${GREEN}✓ 재부팅 후에도 설정이 유지됩니다.${NC}"
echo -e "${GREEN}=========================================${NC}"

echo -e "\n${YELLOW}Windows에서 연결 테스트:${NC}"
echo "1. PowerShell 열기"
echo "2. 'popOS' 입력"
echo "3. 또는 'ssh stevenlim@10.0.0.2' 입력"