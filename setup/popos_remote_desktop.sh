#!/bin/bash
# Pop!_OS 원격 데스크톱 설정 스크립트

echo "=== Pop!_OS 원격 데스크톱 설정 ==="

# 1. xRDP 설치 (Windows 원격 데스크톱 연결용)
echo "1. xRDP 설치 중..."
sudo apt update
sudo apt install -y xrdp

# 2. xRDP 서비스 활성화
echo "2. xRDP 서비스 시작..."
sudo systemctl enable xrdp
sudo systemctl start xrdp

# 3. 방화벽 설정
echo "3. 방화벽 포트 열기..."
sudo ufw allow 3389/tcp

# 4. xRDP 상태 확인
echo "4. xRDP 상태:"
sudo systemctl status xrdp

# 5. 현재 IP 주소 표시
echo ""
echo "=== 연결 정보 ==="
echo "IP 주소: 10.0.0.2"
echo "포트: 3389"
echo "사용자: stevenlim"
echo ""
echo "Windows에서 연결:"
echo "1. Win+R → mstsc 입력"
echo "2. 컴퓨터: 10.0.0.2"
echo "3. 사용자 이름: stevenlim"
echo ""

# 6. VNC 옵션 (대체 방법)
echo "=== VNC 설치 (선택사항) ==="
echo "VNC를 설치하려면 다음 명령 실행:"
echo "sudo apt install -y tigervnc-standalone-server"
echo "vncserver -geometry 1920x1080 -depth 24"