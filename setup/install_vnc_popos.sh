#!/bin/bash
# Pop!_OS VNC 서버 설치 (xRDP 대안)

echo "=== VNC 서버 설치 (xRDP 대안) ==="

# 1. TigerVNC 설치
echo "1. TigerVNC 설치..."
sudo apt update
sudo apt install -y tigervnc-standalone-server tigervnc-common

# 2. VNC 암호 설정
echo "2. VNC 암호 설정 (암호 입력 필요)..."
vncpasswd

# 3. VNC 서버 시작
echo "3. VNC 서버 시작..."
vncserver -kill :1 2>/dev/null
vncserver :1 -geometry 1920x1080 -depth 24

# 4. 방화벽 설정
echo "4. 방화벽 포트 열기..."
sudo ufw allow 5901/tcp

echo ""
echo "=== VNC 연결 정보 ==="
echo "VNC Viewer 다운로드: https://www.realvnc.com/download/viewer/"
echo "연결 주소: 10.0.0.2:5901"
echo "암호: 위에서 설정한 VNC 암호"
echo ""
echo "VNC 서버 중지: vncserver -kill :1"
echo "VNC 서버 시작: vncserver :1 -geometry 1920x1080 -depth 24"