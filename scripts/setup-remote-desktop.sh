#!/bin/bash

# Pop!_OS Remote Desktop Setup Script
# 이 스크립트는 Pop!_OS에서 실행해야 합니다

echo "========================================="
echo "Pop!_OS Remote Desktop Setup"
echo "========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 상태 메시지 출력
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 옵션 선택
echo ""
echo "원격 데스크톱 옵션을 선택하세요:"
echo "1) VNC (TigerVNC) - 표준 옵션"
echo "2) xRDP - Windows Remote Desktop 호환"
echo "3) NoMachine - 고성능 (권장)"
echo "4) 모두 설치"
echo ""
read -p "선택 (1-4): " choice

# 1. VNC 서버 설치 (TigerVNC)
install_vnc() {
    print_status "TigerVNC 서버 설치 중..."
    sudo apt update
    sudo apt install -y tigervnc-standalone-server tigervnc-common tigervnc-xorg-extension

    # VNC 비밀번호 설정
    print_status "VNC 비밀번호 설정..."
    vncpasswd

    # VNC 설정 파일 생성
    mkdir -p ~/.vnc
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="GNOME"

# GNOME 세션 시작
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey

# Pop!_OS 데스크톱 환경 시작
gnome-session &
EOF

    chmod +x ~/.vnc/xstartup

    # systemd 서비스 생성
    sudo tee /etc/systemd/system/vncserver@.service << 'EOF'
[Unit]
Description=Start TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=stevenlim
Group=stevenlim
WorkingDirectory=/home/stevenlim

PIDFile=/home/stevenlim/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

    # 서비스 활성화
    sudo systemctl daemon-reload
    sudo systemctl enable vncserver@1.service
    sudo systemctl start vncserver@1.service

    print_status "VNC 서버가 포트 5901에서 실행 중입니다"
}

# 2. xRDP 설치 (Windows RDP 호환)
install_xrdp() {
    print_status "xRDP 설치 중..."
    sudo apt update
    sudo apt install -y xrdp xorgxrdp

    # xRDP 설정
    sudo sed -i 's/3389/3390/g' /etc/xrdp/xrdp.ini
    sudo adduser xrdp ssl-cert

    # Pop!_OS를 위한 설정
    cat > ~/startwm.sh << 'EOF'
#!/bin/bash
if [ -r /etc/default/locale ]; then
    . /etc/default/locale
    export LANG LANGUAGE
fi

# Pop!_OS GNOME 세션 시작
export XDG_CURRENT_DESKTOP=GNOME
export GNOME_SHELL_SESSION_MODE=pop
exec /usr/bin/gnome-session
EOF

    sudo mv ~/startwm.sh /etc/xrdp/
    sudo chmod +x /etc/xrdp/startwm.sh

    # 서비스 시작
    sudo systemctl enable xrdp
    sudo systemctl restart xrdp

    print_status "xRDP가 포트 3390에서 실행 중입니다"
}

# 3. NoMachine 설치 (고성능)
install_nomachine() {
    print_status "NoMachine 다운로드 및 설치 중..."
    
    # 최신 버전 다운로드
    wget -O ~/nomachine.deb https://download.nomachine.com/download/8.11/Linux/nomachine_8.11.3_4_amd64.deb
    
    # 설치
    sudo dpkg -i ~/nomachine.deb
    sudo apt-get install -f -y
    
    # 서비스 시작
    sudo /etc/NX/nxserver --restart
    
    print_status "NoMachine이 포트 4000에서 실행 중입니다"
    print_status "Windows에서 NoMachine 클라이언트를 다운로드하세요: https://www.nomachine.com/download"
}

# 선택에 따른 설치
case $choice in
    1)
        install_vnc
        ;;
    2)
        install_xrdp
        ;;
    3)
        install_nomachine
        ;;
    4)
        install_vnc
        echo ""
        install_xrdp
        echo ""
        install_nomachine
        ;;
    *)
        print_error "잘못된 선택입니다"
        exit 1
        ;;
esac

# 방화벽 설정
print_status "방화벽 규칙 추가 중..."
sudo ufw allow 5901/tcp  # VNC
sudo ufw allow 3390/tcp  # xRDP
sudo ufw allow 4000/tcp  # NoMachine
sudo ufw reload

# IP 주소 확인
IP=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================="
echo -e "${GREEN}설치 완료!${NC}"
echo "========================================="
echo ""
echo "Pop!_OS IP 주소: $IP"
echo ""
echo "연결 방법:"
echo "  VNC: $IP:5901"
echo "  RDP: $IP:3390"
echo "  NoMachine: $IP:4000"
echo ""
echo "Windows에서 연결하려면:"
echo "  VNC: TigerVNC Viewer 또는 RealVNC Viewer 사용"
echo "  RDP: Windows 원격 데스크톱 연결 사용"
echo "  NoMachine: NoMachine 클라이언트 사용 (권장)"
echo "========================================="