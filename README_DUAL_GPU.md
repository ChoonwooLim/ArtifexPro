# 🚀 ArtifexPro Dual GPU Setup Guide

## 시스템 아키텍처
- **Windows PC**: RTX 3090 (24GB) - Frontend + Ray Worker
- **Pop!_OS PC**: RTX 3090 (24GB) - Backend + Ray Head
- **Total VRAM**: 48GB (분산 처리)
- **Connection**: 10GbE Direct or LAN

## 🎯 Quick Start

### 1. 전체 시스템 시작
```powershell
# Windows에서 실행
.\start-dual-gpu.ps1
```

이 스크립트가 자동으로:
1. Pop!_OS Ray Head 시작
2. Windows Ray Worker 연결
3. 백엔드 서버 시작
4. 프론트엔드 시작
5. 브라우저 오픈

### 2. Ray 클러스터 테스트
```powershell
# 연결 테스트
.\test-ray-cluster.ps1
```

## 📋 수동 설정 (문제 해결시)

### Pop!_OS 설정
```bash
# 1. Python 환경
cd ~/ArtifexPro
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Ray Head 시작
ray stop
ray start --head --port=6379 --dashboard-host=0.0.0.0 --num-gpus=1

# 3. 백엔드 서버
python backend/dual_gpu_model_server.py
```

### Windows 설정
```powershell
# 1. Ray Worker 연결
pip install ray[default] torch
ray stop
ray start --address=192.168.219.150:6379 --num-gpus=1

# 2. 프론트엔드
npm install
npm run dev
```

## 🔍 모니터링

### Ray Dashboard
- URL: http://192.168.219.150:8265
- 클러스터 상태, GPU 사용률, 작업 큐 확인

### GPU 모니터링
```bash
# Pop!_OS
watch -n 1 nvidia-smi

# Windows
nvidia-smi -l 1
```

## 🎮 API 사용법

### TI2V 생성
```python
from dual_gpu_client import DualGPUClient

client = DualGPUClient()
result = await client.generate_ti2v(
    image_path="input.jpg",
    prompt="A cinematic scene",
    duration=5.0
)
```

### S2V 생성
```python
result = await client.generate_s2v(
    audio_path="music.mp3",
    style="cinematic"
)
```

## 📊 성능 벤치마크

| Model | Single GPU | Dual GPU | Speedup |
|-------|------------|----------|---------|
| TI2V-5B | 60s | 35s | 1.7x |
| S2V-14B | 120s | 65s | 1.8x |

## 🛠️ 트러블슈팅

### Ray 연결 실패
```powershell
# 방화벽 확인
netsh advfirewall firewall add rule name="Ray" dir=in action=allow protocol=TCP localport=6379,8265,10001

# SSH 연결 테스트
ssh popOS "ray status"
```

### GPU 인식 안됨
```python
# GPU 확인 스크립트
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.device_count())"
```

### 메모리 부족
- Quality를 "draft"로 낮추기
- Batch size 줄이기
- CPU offloading 활성화

## 🔄 업데이트

### 모델 업데이트
```bash
# Pop!_OS에서
cd ~/ArtifexPro
git pull
python scripts/update_models.py
```

### 코드 동기화
```powershell
# Windows에서
git pull origin main
npm install
```

## 📝 개발 노트

### 듀얼 GPU 파이프라인
1. **Encoding Phase** (Pop!_OS GPU)
   - Image/Audio 인코딩
   - 특징 추출
   - 초기 latent 생성

2. **Generation Phase** (Both GPUs)
   - Diffusion steps 분산
   - Attention 병렬 처리

3. **Decoding Phase** (Windows GPU)
   - VAE 디코딩
   - 후처리
   - 파일 저장

### 최적화 팁
- Ray object store 활용으로 GPU간 전송 최소화
- Pipeline parallelism으로 GPU 유휴 시간 감소
- Gradient checkpointing으로 메모리 절약

## 📞 지원

문제 발생시:
1. `.\test-ray-cluster.ps1` 실행
2. Ray Dashboard 확인
3. 로그 파일 확인: `logs/dual_gpu.log`

---
*ArtifexPro Dual GPU System v1.0*