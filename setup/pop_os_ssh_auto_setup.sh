#!/bin/bash
# Pop!_OS SSH 자동 설정 스크립트
# 비밀번호 자동 입력 포함

echo "=== Pop!_OS SSH 자동 설정 시작 ==="
echo ""

# 비밀번호 설정
PASSWORD="Jiyeon71391796!"

# 1. SSH 서버 설치 확인 및 설치
echo "1. SSH 서버 확인 및 설치..."
echo $PASSWORD | sudo -S apt update
echo $PASSWORD | sudo -S apt install -y openssh-server

# 2. SSH 서비스 시작 및 자동 시작 설정
echo ""
echo "2. SSH 서비스 시작..."
echo $PASSWORD | sudo -S systemctl start ssh
echo $PASSWORD | sudo -S systemctl enable ssh

# 3. 방화벽 설정
echo ""
echo "3. 방화벽 SSH 허용..."
echo $PASSWORD | sudo -S ufw allow ssh
echo $PASSWORD | sudo -S ufw allow 22/tcp
echo $PASSWORD | sudo -S ufw --force enable

# 4. SSH 상태 확인
echo ""
echo "4. SSH 서비스 상태 확인..."
echo $PASSWORD | sudo -S systemctl status ssh --no-pager

# 5. 네트워크 정보 확인
echo ""
echo "5. 네트워크 정보..."
echo "호스트명: $(hostname)"
echo "IP 주소:"
ip addr show enp1s0f1 | grep inet

# 6. SSH 포트 확인
echo ""
echo "6. SSH 포트 확인 (22번 포트)..."
echo $PASSWORD | sudo -S netstat -tlnp | grep :22

echo ""
echo "=== 설정 완료! ==="
echo ""
echo "Windows에서 연결하기:"
echo "ssh stevenlim@192.168.219.150"
echo ""
echo "연결 테스트:"
echo "ssh stevenlim@localhost"