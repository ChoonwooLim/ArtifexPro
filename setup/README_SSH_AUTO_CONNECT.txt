========================================
Pop!_OS SSH 자동 연결 설정 완료!
========================================

[설정 완료 내용]
✓ Windows SSH config 설정 완료
✓ PowerShell 자동 연결 함수 추가
✓ 바탕화면에 빠른 연결 파일 생성

========================================
Pop!_OS 재부팅 후에도 연결되도록 설정하기
========================================

【Pop!_OS에서 실행할 것】

1. Pop!_OS 터미널 열기
2. 다음 명령 실행:
   
   # SSH 서비스 자동 시작 설정
   sudo systemctl enable ssh
   sudo systemctl start ssh
   
   # Avahi (mDNS) 설치 - 호스트명으로 접속 가능
   sudo apt install -y avahi-daemon
   sudo systemctl enable avahi-daemon
   sudo systemctl start avahi-daemon
   
   # 호스트명 설정
   sudo hostnamectl set-hostname popOS-artifex
   
   # 방화벽 SSH 허용
   sudo ufw allow ssh
   sudo ufw --force enable

3. 재부팅 테스트:
   sudo reboot

========================================
【Windows에서 연결하는 방법】
========================================

방법 1: 바탕화면 바로가기
   → "Connect_PopOS.bat" 더블클릭

방법 2: PowerShell
   → popOS 입력 (또는 Connect-PopOS)

방법 3: 일반 SSH 명령
   → ssh popOS
   → ssh popOS-artifex.local
   → ssh stevenlim@popOS-artifex.local

========================================
【문제 해결】
========================================

Q: 연결이 안 될 때?
A: 1) Pop!_OS가 켜져 있는지 확인
   2) 같은 네트워크(WiFi/LAN)인지 확인
   3) PowerShell에서 Find-PopOS 실행하여 IP 찾기

Q: IP 주소가 계속 바뀐다면?
A: Pop!_OS에서 고정 IP 설정:
   Settings → Network → 유선/무선 → IPv4 → Manual
   - Address: 192.168.1.100
   - Netmask: 255.255.255.0
   - Gateway: 192.168.1.1 (라우터 IP)
   - DNS: 8.8.8.8

Q: "Host key verification failed" 오류?
A: ssh-keygen -R popOS-artifex.local 실행 후 재시도

========================================
【스크립트 파일 위치】
========================================

- Pop!_OS 설정: C:\WORK\ArtifexPro\setup\pop_os_ssh_setup.sh
- Windows 설정: C:\WORK\ArtifexPro\setup\windows_ssh_setup.ps1
- 이 파일: C:\WORK\ArtifexPro\setup\README_SSH_AUTO_CONNECT.txt

========================================
준비 완료! 이제 Pop!_OS를 재부팅해도 
항상 ssh popOS 명령이 작동합니다.
========================================