#!/bin/bash
# Pop!_OS xRDP 문제 해결 스크립트

echo "=== Pop!_OS xRDP 문제 해결 ==="

# 1. xrdp 서비스 중지
echo "1. 기존 xrdp 서비스 중지..."
sudo systemctl stop xrdp
sudo systemctl stop xrdp-sesman

# 2. xrdp 설정 파일 수정
echo "2. xrdp 설정 수정..."
sudo sed -i 's/port=3389/port=3389/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/use_vsock=true/use_vsock=false/g' /etc/xrdp/xrdp.ini

# 3. SSL 인증서 문제 해결
echo "3. SSL 인증서 재생성..."
sudo rm -f /etc/xrdp/rsakeys.ini
sudo rm -f /etc/xrdp/*.pem
sudo xrdp-keygen xrdp auto

# 4. 권한 설정
echo "4. 권한 설정..."
sudo adduser xrdp ssl-cert
sudo chown xrdp:xrdp /etc/xrdp/rsakeys.ini
sudo chmod 600 /etc/xrdp/rsakeys.ini

# 5. 사용자를 xrdp 그룹에 추가
echo "5. 사용자 권한 추가..."
sudo usermod -a -G xrdp stevenlim

# 6. xrdp 재시작
echo "6. xrdp 서비스 재시작..."
sudo systemctl restart xrdp
sudo systemctl restart xrdp-sesman

# 7. 상태 확인
echo "7. 서비스 상태 확인..."
sudo systemctl status xrdp --no-pager
echo ""
sudo netstat -tlnp | grep 3389

echo ""
echo "=== 완료 ==="
echo "Windows에서 다시 연결 시도하세요."
echo "만약 여전히 안 되면 다음 명령 실행:"
echo "sudo apt remove --purge xrdp"
echo "sudo apt install xrdp"