# NoMachine 4K Ultra HD 설정 스크립트
Write-Host "NoMachine 4K Ultra HD 최적화 설정" -ForegroundColor Magenta
Write-Host "===================================" -ForegroundColor Magenta
Write-Host ""

# Pop!_OS 4K 설정 스크립트 생성
$setup4K = @'
#!/bin/bash
echo "==================================="
echo "NoMachine 4K Ultra HD 서버 설정"
echo "==================================="
echo ""

# 현재 디스플레이 정보 확인
echo "현재 디스플레이 정보:"
xrandr | grep -E "connected|current"
echo ""

# 4K 해상도 추가 및 설정
echo "1. 4K 해상도 모드 추가..."

# 4K 해상도 옵션들
# 3840x2160 (4K UHD) @ 60Hz
xrandr --newmode "3840x2160_60" 712.75 3840 4160 4576 5312 2160 2163 2168 2237 -hsync +vsync 2>/dev/null || true
xrandr --addmode HDMI-0 "3840x2160_60" 2>/dev/null || true
xrandr --addmode DP-0 "3840x2160_60" 2>/dev/null || true

# 3840x2160 @ 30Hz (대역폭 절약)
xrandr --newmode "3840x2160_30" 297.00 3840 4016 4104 4400 2160 2168 2178 2250 +hsync +vsync 2>/dev/null || true
xrandr --addmode HDMI-0 "3840x2160_30" 2>/dev/null || true
xrandr --addmode DP-0 "3840x2160_30" 2>/dev/null || true

# 2560x1440 (2K/QHD) @ 60Hz
xrandr --newmode "2560x1440_60" 241.50 2560 2608 2640 2720 1440 1443 1448 1481 +hsync -vsync 2>/dev/null || true
xrandr --addmode HDMI-0 "2560x1440_60" 2>/dev/null || true
xrandr --addmode DP-0 "2560x1440_60" 2>/dev/null || true

echo "2. NoMachine 서버 4K 최적화..."

# NoMachine 설정 파일
SERVER_CFG="/usr/NX/etc/server.cfg"
NODE_CFG="/usr/NX/etc/node.cfg"

# 백업
sudo cp $SERVER_CFG ${SERVER_CFG}.4k_backup 2>/dev/null
sudo cp $NODE_CFG ${NODE_CFG}.4k_backup 2>/dev/null

# 4K 최적화 설정
sudo tee /tmp/nomachine_4k.conf > /dev/null << EOF
# 4K Display Settings
DisplayQuality 9
DisplayEncoding "H264"
EnableAdaptiveQuality 0
EnableJPEGCompression 0
DisplayServerVideoFrameRate 60
DisplayServerVideoBitrate 100
AgentVideoCompressionLevel 0
MaxSessionFrameRate 60

# 4K Resolution Support
PhysicalDesktopResolution 3840x2160
VirtualDesktopResolution 3840x2160
AvailableResolutions "640x480,800x600,1024x768,1280x720,1280x1024,1366x768,1600x900,1920x1080,2560x1440,3840x2160"
DefaultResolution 3840x2160

# Network Optimization for 4K
LinkSpeed wan
SessionBandwidth 100000
ClientConnectionMethod TCP
EnableTCPNoDelay 1
EnableTCPKeepAlive 1

# GPU Acceleration
EnableHardwareAcceleration 1
EnableGPUAcceleration 1
UseHardwareDecoding 1
UseHardwareEncoding 1

# Buffer Settings for 4K
DisplayBuffer 256
ImageCacheSize 256
DiskCacheSize 2048
EOF

# 설정 적용
echo "3. 설정 적용 중..."
sudo bash -c "grep -v '^#' /tmp/nomachine_4k.conf | while read line; do
    if [ ! -z \"\$line\" ]; then
        key=\$(echo \$line | cut -d' ' -f1)
        value=\$(echo \$line | cut -d' ' -f2-)
        sed -i \"s/^\$key .*$/\$key \$value/g\" $SERVER_CFG 2>/dev/null
        sed -i \"s/^\$key .*$/\$key \$value/g\" $NODE_CFG 2>/dev/null
    fi
done"

# Virtual Display 생성 (물리 모니터 없이도 4K 지원)
echo "4. Virtual Display 설정..."
sudo tee /etc/X11/xorg.conf.d/10-dummy.conf > /dev/null << EOF
Section "Device"
    Identifier  "Configured Video Device"
    Driver      "nvidia"
    Option      "UseDisplayDevice" "None"
    Option      "CustomEDID" "DFP-0:/etc/X11/edid.bin"
EndSection

Section "Monitor"
    Identifier  "Configured Monitor"
    HorizSync   30-300
    VertRefresh 30-300
    Modeline "3840x2160_60" 712.75 3840 4160 4576 5312 2160 2163 2168 2237 -hsync +vsync
    Modeline "3840x2160_30" 297.00 3840 4016 4104 4400 2160 2168 2178 2250 +hsync +vsync
    Modeline "2560x1440_60" 241.50 2560 2608 2640 2720 1440 1443 1448 1481 +hsync -vsync
EndSection

Section "Screen"
    Identifier  "Default Screen"
    Monitor     "Configured Monitor"
    Device      "Configured Video Device"
    DefaultDepth 24
    SubSection "Display"
        Depth    24
        Modes    "3840x2160" "2560x1440" "1920x1080"
    EndSubSection
EndSection
EOF

# NVIDIA 설정 (RTX 3090)
echo "5. NVIDIA GPU 최적화..."
nvidia-xconfig --enable-all-gpus 2>/dev/null || true
nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1" 2>/dev/null || true

# NoMachine 서비스 재시작
echo "6. 서비스 재시작..."
sudo /usr/NX/bin/nxserver --restart

echo ""
echo "✅ 4K 설정 완료!"
echo ""
echo "사용 가능한 해상도:"
echo "  - 3840x2160 (4K UHD) @ 60Hz / 30Hz"
echo "  - 2560x1440 (QHD) @ 60Hz"
echo "  - 1920x1080 (FHD) @ 60Hz"
echo ""
echo "권장 네트워크:"
echo "  - 최소 100Mbps 연결 (4K@30Hz)"
echo "  - 최소 200Mbps 연결 (4K@60Hz)"
echo "  - 가급적 유선 LAN 사용"
'@

# Pop!_OS에 스크립트 전송
ssh popOS "cat > ~/setup_4k_nomachine.sh << 'EOF'
$setup4K
EOF
chmod +x ~/setup_4k_nomachine.sh"

Write-Host "Pop!_OS 4K 설정 스크립트 생성 완료!" -ForegroundColor Green
Write-Host ""

# Windows 클라이언트 설정 가이드
Write-Host "Windows NoMachine 클라이언트 4K 설정:" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host @"

1. NoMachine 연결 설정:
   ▶ Display 탭:
     - Quality: Best (9)
     - Resolution: Custom 선택
     - Width: 3840, Height: 2160
     - Use custom resolution: ✓ 체크
     - Color depth: True color (32 bit)
     
   ▶ Performance 탭:  
     - Disable network adaptive quality: ✓ 체크
     - Request specific frame rate: 30 FPS (안정성) 또는 60 FPS (성능)
     
   ▶ Advanced 탭:
     - Video encoding: H.264
     - Use hardware decoding: ✓ 체크
     - Cache size on disk: 2048 MB
     
2. Windows 디스플레이 설정:
   - 디스플레이 설정 > 크기 조정: 100% (4K 모니터)
   - 디스플레이 설정 > 크기 조정: 150-200% (일반 모니터에서 4K 콘텐츠)

3. 네트워크 최적화:
   - 유선 기가비트 LAN 연결 권장
   - Wi-Fi 사용 시 Wi-Fi 6 (802.11ax) 권장
   
"@ -ForegroundColor White

Write-Host "Pop!_OS에서 실행할 명령:" -ForegroundColor Yellow
Write-Host "  ~/setup_4k_nomachine.sh" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  주의사항:" -ForegroundColor Red
Write-Host "  - 4K@60Hz는 높은 대역폭 필요 (200Mbps+)" -ForegroundColor White
Write-Host "  - GPU 가속이 활성화되어야 원활한 성능" -ForegroundColor White
Write-Host "  - RTX 3090이 정상 작동하는지 확인 필요" -ForegroundColor White