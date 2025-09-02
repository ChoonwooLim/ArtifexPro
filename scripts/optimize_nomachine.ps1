# NoMachine 화면 품질 최적화 스크립트
Write-Host "NoMachine 화면 품질 최적화 설정" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# NoMachine 설정 파일 경로
$nxPlayerConfig = "$env:USERPROFILE\.nx\config\player.cfg"
$nxClientConfig = "$env:USERPROFILE\.nx\config\client.cfg"

Write-Host "`n1. Windows 클라이언트 설정 조정..." -ForegroundColor Yellow

# Windows 클라이언트 최적화 설정
$optimizedSettings = @"
# NoMachine 고품질 설정

## 디스플레이 품질 설정
<option key="Display quality" value="9" />
<option key="Use adaptive quality" value="0" />
<option key="Disable JPEG compression" value="1" />
<option key="Disable video streaming" value="0" />
<option key="Use hardware encoding" value="1" />

## 해상도 및 색상
<option key="Color depth" value="32" />
<option key="Resolution" value="native" />
<option key="Use custom resolution" value="0" />
<option key="Resize remote screen" value="0" />

## 성능 최적화
<option key="Disable network adaptive quality" value="1" />
<option key="Link speed" value="lan" />
<option key="Cache size" value="128" />
<option key="Disable bandwidth limit" value="1" />

## 비디오 코덱
<option key="Video encoding" value="H264" />
<option key="Use VP8 codec" value="0" />
<option key="Use H264 codec" value="1" />
"@

Write-Host "  - 고품질 디스플레이 설정 생성 완료" -ForegroundColor Green

Write-Host "`n2. Pop!_OS 서버 설정 최적화 명령..." -ForegroundColor Yellow

# Pop!_OS 서버 설정 스크립트 생성
$serverScript = @'
#!/bin/bash
echo "NoMachine 서버 최적화 설정"
echo "=========================="

# NoMachine 서버 설정 파일 경로
SERVER_CFG="/usr/NX/etc/server.cfg"
NODE_CFG="/usr/NX/etc/node.cfg"

# 백업 생성
sudo cp $SERVER_CFG ${SERVER_CFG}.backup
sudo cp $NODE_CFG ${NODE_CFG}.backup

echo "1. 디스플레이 품질 최적화..."

# 서버 설정 최적화
sudo sed -i 's/DisplayQuality .*/DisplayQuality 9/g' $SERVER_CFG
sudo sed -i 's/DisplayEncoding .*/DisplayEncoding "H264"/g' $SERVER_CFG
sudo sed -i 's/EnableAdaptiveQuality .*/EnableAdaptiveQuality 0/g' $SERVER_CFG
sudo sed -i 's/EnableJPEGCompression .*/EnableJPEGCompression 0/g' $SERVER_CFG

# 노드 설정 최적화
sudo sed -i 's/DisplayServerVideoFrameRate .*/DisplayServerVideoFrameRate 60/g' $NODE_CFG
sudo sed -i 's/DisplayServerVideoBitrate .*/DisplayServerVideoBitrate 50/g' $NODE_CFG
sudo sed -i 's/AgentVideoCompressionLevel .*/AgentVideoCompressionLevel 0/g' $NODE_CFG

echo "2. 네트워크 설정 최적화..."
sudo sed -i 's/LinkSpeed .*/LinkSpeed lan/g' $SERVER_CFG
sudo sed -i 's/ClientConnectionMethod .*/ClientConnectionMethod NX/g' $SERVER_CFG

echo "3. 하드웨어 가속 활성화..."
sudo sed -i 's/EnableHardwareAcceleration .*/EnableHardwareAcceleration 1/g' $SERVER_CFG
sudo sed -i 's/EnableGPUAcceleration .*/EnableGPUAcceleration 1/g' $SERVER_CFG

# 서비스 재시작
echo "4. NoMachine 서비스 재시작..."
sudo /usr/NX/bin/nxserver --restart

echo ""
echo "최적화 완료!"
echo ""
echo "권장 클라이언트 설정:"
echo "  - Display Quality: Best (9)"
echo "  - Resolution: Match client resolution"
echo "  - Color Depth: 32 bit"
echo "  - Disable adaptive quality"
echo "  - Use H264 encoding"
'@

# SSH를 통해 Pop!_OS에 스크립트 전송
ssh popOS "cat > ~/optimize_nomachine.sh << 'EOF'
$serverScript
EOF
chmod +x ~/optimize_nomachine.sh"

Write-Host "  - Pop!_OS 최적화 스크립트 생성 완료" -ForegroundColor Green
Write-Host "`n3. 수동 설정 가이드:" -ForegroundColor Yellow

Write-Host @"

Windows NoMachine 클라이언트 설정:
====================================
1. NoMachine 연결 창에서 설정(톱니바퀴) 클릭
2. Display 탭:
   - Quality: Best quality (슬라이더 오른쪽 끝)
   - Resolution: Match the client resolution 선택
   - Use custom resolution: 체크 해제
   - Resize remote screen: 체크 해제

3. Performance 탭:
   - Disable network adaptive quality: 체크
   - Disable client side image post-processing: 체크 해제
   - Disable multi-pass encoding: 체크 해제

4. Advanced 탭:
   - Video encoding: H264 선택
   - Color depth: 32 bit
   - Request a specific frame rate: 60 FPS

Pop!_OS 서버 최적화:
===================
터미널에서 실행:
  ~/optimize_nomachine.sh

추가 최적화 (선택사항):
=====================
1. 디스플레이 설정 조정:
   - Pop!_OS 디스플레이 설정에서 스케일링 100%로 설정
   - 해상도를 1920x1080 또는 원하는 해상도로 고정

2. GPU 가속 확인:
   ssh popOS "nvidia-smi"
   - NVIDIA 드라이버가 정상 작동하는지 확인

3. 네트워크 최적화:
   - 가능하면 유선 LAN 연결 사용
   - Wi-Fi 사용 시 5GHz 대역 사용

"@ -ForegroundColor White

Write-Host "`n설정 적용 후 NoMachine을 재시작하세요!" -ForegroundColor Green