@echo off
echo =========================================
echo Pop!_OS 복구 명령어 준비
echo =========================================
echo.
echo 【Pop!_OS 접근 가능해지면 실행할 명령어】
echo.
echo 1. 문제 파일 삭제:
echo    sudo rm /etc/netplan/10-direct.yaml
echo    암호: Jiyeon71391796!
echo.
echo 2. 네트워크 재설정:
echo    sudo systemctl restart NetworkManager
echo.
echo 3. 안전한 네트워크 설정 (GUI 사용):
echo    Settings -^> Network -^> Wired Settings
echo    IPv4: Manual
echo    Address: 10.0.0.2
echo    Netmask: 255.255.255.0
echo    Gateway: (비워둠)
echo.
echo =========================================
echo 【Windows에서 할 수 있는 준비】
echo =========================================
echo.
echo 1. Pop!_OS Live USB 만들기:
echo    https://pop.system76.com/ 에서 ISO 다운로드
echo    Rufus 사용하여 USB 만들기
echo.
echo 2. 10Gbps 연결 상태 확인:
echo    ipconfig /all ^| findstr "10.0.0.1"
echo.
echo 3. SSH 설정 백업:
type C:\Users\choon\.ssh\config | findstr /C:"Host popOS" /C:"HostName" /C:"User"
echo.
echo =========================================
echo 【하드웨어 체크리스트】
echo =========================================
echo.
echo [ ] 전원 케이블 제거 (5분)
echo [ ] CMOS 배터리 제거 (10분)
echo [ ] 10Gbps 네트워크 카드 제거
echo [ ] RAM 최소화 (1개만)
echo [ ] GPU 최소화 (1개만)
echo [ ] 불필요한 USB 장치 제거
echo.
echo =========================================
echo.
echo 복구 명령어가 prepare_recovery_commands.txt에 저장됩니다...
echo.

(
echo # Pop!_OS 복구 명령어 모음
echo # 생성 시간: %date% %time%
echo.
echo ## 1. Live USB에서 실행 (chroot 방식)
echo sudo fdisk -l
echo sudo mount /dev/nvme0n1p2 /mnt
echo sudo mount --bind /dev /mnt/dev
echo sudo mount --bind /proc /mnt/proc  
echo sudo mount --bind /sys /mnt/sys
echo sudo chroot /mnt
echo rm /etc/netplan/10-direct.yaml
echo exit
echo sudo umount /mnt/sys
echo sudo umount /mnt/proc
echo sudo umount /mnt/dev
echo sudo umount /mnt
echo.
echo ## 2. 정상 부팅 후 실행
echo sudo rm /etc/netplan/10-direct.yaml
echo sudo netplan generate
echo sudo netplan apply
echo.
echo ## 3. NetworkManager로 설정
echo nmcli con add type ethernet con-name "10Gbps" ifname enp1s0f0 ip4 10.0.0.2/24
echo nmcli con up "10Gbps"
echo.
echo ## 4. 임시 IP 설정
echo sudo ip addr add 10.0.0.2/24 dev enp1s0f0
echo sudo ip link set enp1s0f0 up
echo sudo ip link set enp1s0f0 mtu 9000
) > prepare_recovery_commands.txt

echo.
echo 파일이 생성되었습니다: prepare_recovery_commands.txt
echo.
pause