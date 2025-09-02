# Claude Development Notes

## Project Information
- **Project Name**: ArtifexPro Studio
- **Location**: C:\WORK\ArtifexPro
- **Type**: AI 영상 생성/편집 플랫폼 (Node-based + Timeline)
- **Architecture**: 3-Tier + Node System (온디바이스 우선, 클라우드 선택형)
- **⚡ 듀얼 GPU 필수**: 모든 기능들에서 GPU 듀얼모드 반드시 사용 (2x RTX 3090, 48GB VRAM Total)

## Development Commands
- `npm run dev` - Start development server
- `npm run build` - Production build
- `npm run test` - Run tests
- `npm run lint` - Lint code
- `npm run typecheck` - Type checking
- `python -m pytest` - Run Python tests
- `python scripts/wan22_setup.py` - Setup Wan2.2 models
- `python backend/dual_gpu_api.py` - **듀얼 GPU 백엔드 시작 (Port 8002)**

## Project Structure
- `src/` - Source code
  - `core/` - 핵심 엔진 (Node Graph Engine, GPU Manager)
  - `nodes/` - 노드 구현체 (Input, Process, Effect, Output 등)
  - `wan22/` - Wan2.2 통합 모듈 (T2V, I2V, TI2V, S2V)
  - `ui/` - UI 컴포넌트 (Timeline, Node Editor, AI Studio)
  - `api/` - API 레이어
  - `utils/` - 유틸리티 함수
- `models/` - AI 모델 저장소 (Wan2.2 체크포인트)
- `assets/` - 정적 자원
- `tests/` - 테스트 코드
- `scripts/` - 빌드 및 배포 스크립트

## 기술 스택

### 프론트엔드
- **Framework**: React/Vue.js + TypeScript
- **UI Library**: Ant Design / Material-UI
- **Node Editor**: React Flow / Rete.js
- **Timeline**: Custom Canvas-based Timeline
- **State Management**: Redux Toolkit / Zustand
- **Video Player**: Video.js with custom controls

### 백엔드
- **Runtime**: Node.js + Python (FastAPI)
- **Database**: PostgreSQL + Redis
- **Queue**: RabbitMQ / Celery
- **Storage**: MinIO (S3 compatible)
- **WebSocket**: Socket.io

### AI/ML
- **Wan2.2 Models**: 
  - T2V-A14B (27B MoE, 14B active)
  - I2V-A14B (27B MoE)
  - TI2V-5B (5B Dense)
  - S2V-14B
- **Framework**: PyTorch 2.0+
- **Optimization**: Flash Attention, xFormers, torch.compile
- **Quantization**: BitsAndBytes, GPTQ

### GPU 최적화 (듀얼 GPU 필수)
- **Ray Cluster**: 듀얼 GPU 분산 처리 (2x RTX 3090)
- **Multi-GPU**: FSDP, Ulysses Attention, Ray Remote Workers
- **Memory**: CPU Offloading, Gradient Checkpointing, 48GB VRAM 활용
- **Inference**: TensorRT, ONNX Runtime, Flash Attention 3
- **Load Balancing**: 프레임 분할 병렬 처리

## 핵심 기능 모듈

### 1. Node Graph Engine (NGE)
- 실시간 노드 처리 파이프라인
- GPU 가속 프리뷰
- 자동 타입 변환
- 의존성 분석 및 병렬 처리

### 2. Wan2.2 Integration (듀얼 GPU 필수)
- 스마트 모델 로딩 (VRAM 기반 자동 최적화, 48GB 활용)
- 품질 프리셋 (Draft, Preview, Production, Cinema)
- 프롬프트 확장 및 스타일 인코딩
- **Ray Cluster**: 비디오 프레임 분할 병렬 처리 (GPU-0: 전반부, GPU-1: 후반부)
- **Flash Attention 3**: RTX 3090 최적화로 속도 향상

### 3. Timeline Editor
- 999 트랙 지원
- 실시간 협업
- 버전 관리 (Git LFS)
- 자동 프록시 생성

### 4. Render System
- 로컬/클라우드 하이브리드 렌더링
- 렌더 팜 통합 (SLURM)
- 배치 처리 및 큐 관리
- 자동 품질 체크

## 개발 가이드라인

### 코드 컨벤션
- **Python**: PEP 8, Type Hints 필수
- **TypeScript**: ESLint + Prettier
- **Naming**: 
  - 컴포넌트/클래스: PascalCase
  - 함수/변수: camelCase
  - 상수: UPPER_SNAKE_CASE
  - 파일명: kebab-case

### 노드 개발 규칙
```python
class CustomNode(BaseNode):
    """노드 개발 템플릿"""
    
    category = "process"  # input/generator/process/effect/output
    inputs = {
        'video': VideoStream,
        'params': Dict[str, Any]
    }
    outputs = {
        'video': VideoStream,
        'metadata': Dict
    }
    
    def process(self, inputs: Dict) -> Dict:
        # GPU 처리 로직
        pass
```

### 성능 최적화 체크리스트
- [ ] GPU 메모리 프로파일링
- [ ] 배치 처리 가능 여부 확인
- [ ] 캐싱 전략 구현
- [ ] 병렬 처리 최적화
- [ ] 메모리 누수 체크

### Git 워크플로우
- Feature Branch: `feature/node-name`
- Bugfix Branch: `bugfix/issue-number`
- Release Branch: `release/v1.0.0`
- Commit Message: `type(scope): description`
  - feat: 새 기능
  - fix: 버그 수정
  - perf: 성능 개선
  - refactor: 리팩토링
  - docs: 문서 수정

## 성능 벤치마크 타겟

### Generation Speed (듀얼 RTX 3090 기준)
- T2V 720p 5s: < 90초 (듀얼 GPU 병렬 처리)
- I2V 720p 5s: < 75초 (듀얼 GPU 병렬 처리)
- TI2V 720p 5s: < 45초 (TI2V-5B + 듀얼 GPU)
- S2V 720p 5s: < 90초 (S2V-14B + 듀얼 GPU)

### Memory Requirements (듀얼 GPU 구성)
- **Current Setup**: 48GB VRAM (2x RTX 3090 24GB)
- **Load Balancing**: Ray 클러스터로 자동 메모리 분배
- **Minimum**: 24GB VRAM (싱글 GPU 폴백 모드, 권장하지 않음)
- **Optimal**: 48GB VRAM (현재 구성, 듀얼 GPU 병렬 처리)
- **Enterprise**: 80GB+ VRAM (향후 확장)

### Quality Metrics
- Temporal Consistency: > 0.95
- Motion Quality: > 0.92
- Aesthetic Score: > 7.5/10

## 환경 변수 설정
```bash
# Wan2.2 Models
WAN22_MODEL_PATH=/models/wan22
WAN22_CACHE_DIR=/cache/wan22

# GPU Settings
CUDA_VISIBLE_DEVICES=0,1
TORCH_CUDA_ARCH_LIST=8.0;8.6;9.0

# API Keys (필요시)
HF_TOKEN=your_token_here

# Performance
ENABLE_FLASH_ATTENTION=true
USE_XFORMERS=true
TORCH_COMPILE=true
```

## 테스트 커맨드
```bash
# Unit Tests
python -m pytest tests/unit -v

# Integration Tests
python -m pytest tests/integration -v

# Node Tests
python -m pytest tests/nodes -v

# Wan2.2 Tests
python -m pytest tests/wan22 -v --gpu

# Performance Tests
python scripts/benchmark.py --model t2v --quality production
```

## 디버깅 도구
- GPU Monitor: `nvidia-smi -l 1`
- Memory Profiler: `python -m memory_profiler`
- Node Graph Visualizer: `npm run visualize`
- Timeline Debugger: `npm run debug:timeline`

## 🚀 듀얼 PC 개발 환경 구축 가이드

### 개발 PC 정보
- **Windows PC**: C:\WORK\ArtifexPro (메인 개발, UI/프론트엔드)
- **Pop!_OS PC**: ~/ArtifexPro (AI/GPU 처리, 백엔드)
  - **로그인 정보**: username: `stevenlim` / password: `Jiyeon71391796!`
- **SSH 연결**: Windows → Pop!_OS (설정 완료)

### STEP 1: SSH 연결 설정 ✅

#### 1.1 Pop!_OS에서 SSH 서버 설정
```bash
# SSH 서버 설치 및 시작
sudo apt update
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# 방화벽 허용
sudo ufw allow ssh

# IP 주소 확인 (예: 192.168.1.100)
hostname -I
```

#### 1.2 Windows에서 SSH 키 생성
```powershell
# SSH 키 생성
ssh-keygen -t rsa -b 4096
# Enter 3번 (기본 경로, 패스프레이즈 없음)

# 공개키 내용 복사
type C:\Users\choon\.ssh\id_rsa.pub
```

#### 1.3 Pop!_OS에 공개키 등록
```bash
# stevenlim 사용자로 로그인 후
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Windows 공개키 붙여넣기, Ctrl+X, Y, Enter
chmod 600 ~/.ssh/authorized_keys
```

#### 1.4 Windows SSH config 설정
```powershell
# C:\Users\choon\.ssh\config 파일 생성 (확장자 없음!)
New-Item -Path C:\Users\choon\.ssh\config -ItemType File -Force
notepad C:\Users\choon\.ssh\config
```

config 파일 내용:
```
Host popOS
    HostName 192.168.1.100  # Pop!_OS IP 주소
    User stevenlim
    Port 22
```

테스트: `ssh popOS`

### STEP 2: Git 저장소 설정

#### 2.1 Windows에서 Git 초기화
```powershell
cd C:\WORK\ArtifexPro
git init
git add .
git commit -m "Initial commit"

# GitHub 원격 저장소 생성 후
git remote add origin https://github.com/[username]/ArtifexPro.git
git push -u origin main
```

#### 2.2 Pop!_OS에서 클론
```bash
cd ~
git clone https://github.com/[username]/ArtifexPro.git
cd ArtifexPro
```

### STEP 3: 개발 환경 구축

#### 3.1 Pop!_OS 백엔드 환경
```bash
# Python 환경 설정
cd ~/ArtifexPro
python3 -m venv venv
source venv/bin/activate

# requirements.txt 생성
cat > requirements.txt << EOF
fastapi==0.104.1
uvicorn[standard]==0.24.0
torch==2.1.0
transformers==4.35.0
numpy==1.24.3
opencv-python==4.8.1
pillow==10.1.0
redis==5.0.1
celery==5.3.4
pytest==7.4.3
EOF

pip install -r requirements.txt

# 백엔드 서버 스크립트
cat > start-backend.sh << 'EOF'
#!/bin/bash
cd ~/ArtifexPro
source venv/bin/activate
uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000
EOF
chmod +x start-backend.sh
```

#### 3.2 Windows 프론트엔드 환경
```powershell
cd C:\WORK\ArtifexPro

# package.json 생성 (Pop!_OS 백엔드 연결)
@"
{
  "name": "artifexpro-frontend",
  "version": "0.1.0",
  "private": true,
  "proxy": "http://192.168.1.100:8000",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "lint": "eslint src",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-flow-renderer": "^10.3.17",
    "axios": "^1.6.0",
    "socket.io-client": "^4.5.4"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "@types/react": "^18.2.0",
    "typescript": "^5.2.0",
    "eslint": "^8.50.0"
  }
}
"@ | Out-File -Encoding UTF8 package.json

npm install
```

### STEP 4: 자동 동기화 설정

#### 4.1 Pop!_OS 자동 pull 스크립트
```bash
cat > ~/sync-artifex.sh << 'EOF'
#!/bin/bash
cd ~/ArtifexPro
while true; do
    git pull origin main
    sleep 10
done
EOF
chmod +x ~/sync-artifex.sh
```

#### 4.2 Windows 자동 push 함수
```powershell
# PowerShell 프로필에 추가
notepad $PROFILE

# 추가할 내용:
function Sync-ArtifexPro {
    cd C:\WORK\ArtifexPro
    git add .
    git commit -m "Auto sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git push origin main
}
```

### STEP 5: VS Code Remote 설정

#### 5.1 Windows VS Code 설정
1. VS Code 설치
2. Remote-SSH 확장 설치
3. `F1` → "Remote-SSH: Connect to Host" → `popOS` 선택
4. Pop!_OS 파일 직접 편집 가능

### STEP 6: 통합 개발 스크립트

#### 6.1 Pop!_OS 통합 실행 스크립트
```bash
cat > ~/artifex-dev.sh << 'EOF'
#!/bin/bash
echo "ArtifexPro 백엔드 시작..."

# tmux 세션 시작
tmux new-session -d -s artifex

# 백엔드 서버
tmux send-keys -t artifex "cd ~/ArtifexPro && ./start-backend.sh" C-m

# GPU 모니터링
tmux new-window -t artifex -n gpu
tmux send-keys -t artifex:gpu "watch -n 1 nvidia-smi" C-m

# Git 동기화
tmux new-window -t artifex -n sync
tmux send-keys -t artifex:sync "~/sync-artifex.sh" C-m

# 로그 모니터링
tmux new-window -t artifex -n logs
tmux send-keys -t artifex:logs "tail -f ~/ArtifexPro/logs/*.log" C-m

echo "실행 완료! 접속: tmux attach -t artifex"
EOF
chmod +x ~/artifex-dev.sh
```

#### 6.2 Windows 통합 실행 함수
```powershell
# PowerShell 프로필에 추가
function Start-ArtifexDev {
    Write-Host "ArtifexPro 개발 환경 시작..." -ForegroundColor Green
    
    # Pop!_OS 백엔드 시작
    Start-Process powershell -ArgumentList "ssh popOS '~/artifex-dev.sh'"
    
    # 3초 대기
    Start-Sleep -Seconds 3
    
    # 로컬 프론트엔드 시작
    cd C:\WORK\ArtifexPro
    Start-Process powershell -ArgumentList "npm run dev"
    
    # VS Code 열기
    code C:\WORK\ArtifexPro
    
    # 브라우저 열기
    Start-Sleep -Seconds 5
    Start-Process "http://localhost:3000"
    
    Write-Host "모든 서비스 실행 완료!" -ForegroundColor Green
}

# 종료 함수
function Stop-ArtifexDev {
    ssh popOS "tmux kill-session -t artifex"
    Get-Process node | Stop-Process -Force
    Write-Host "ArtifexPro 종료 완료" -ForegroundColor Yellow
}
```

### STEP 7: 파일 동기화 (Syncthing)

#### 7.1 양쪽 PC에 Syncthing 설치
```powershell
# Windows
winget install Syncthing.Syncthing
```

```bash
# Pop!_OS
sudo apt install syncthing
syncthing
```

#### 7.2 설정
1. Windows: http://localhost:8384
2. Pop!_OS: http://localhost:8384
3. Device ID 교환
4. ArtifexPro 폴더 공유 설정

### STEP 8: 실행 및 테스트

#### 전체 시작 (Windows PowerShell)
```powershell
Start-ArtifexDev
```

#### 개별 테스트
```powershell
# SSH 연결 테스트
ssh popOS "echo 'Connection OK'"

# 백엔드 API 테스트
curl http://192.168.1.100:8000/health

# Git 동기화 테스트
Sync-ArtifexPro
```

#### 모니터링
```bash
# Pop!_OS에서
tmux attach -t artifex
# Ctrl+B, 숫자키로 창 전환
```

### 트러블슈팅

#### SSH 연결 실패
```powershell
# Windows에서
ssh -vvv popOS  # 디버그 모드
ssh-keygen -R 192.168.1.100  # 기존 키 제거
```

#### Git 충돌
```bash
# Pop!_OS에서
git stash
git pull origin main
git stash pop
```

#### 포트 충돌
```bash
# 사용 중인 포트 확인
sudo lsof -i :8000
sudo kill -9 [PID]
```

## ⚡ 듀얼 GPU 아키텍처

### GPU 구성
- **GPU 0**: RTX 3090 24GB (cuda:0)
- **GPU 1**: RTX 3090 24GB (cuda:1)
- **Total VRAM**: 48GB
- **Ray Cluster**: 2개 GPU 워커로 분산 처리

### 병렬 처리 방식
1. **프레임 분할**: 총 프레임을 절반으로 나누어 각 GPU에 할당
2. **GPU 0**: 전반부 프레임 (0 ~ mid_frame)
3. **GPU 1**: 후반부 프레임 (mid_frame ~ total_frames)
4. **병렬 실행**: Ray의 future로 두 GPU가 동시 처리
5. **결과 병합**: 완료 후 결과를 하나로 통합

### 핵심 코드
```python
# Ray 클러스터 초기화
ray.init(ignore_reinit_error=True, num_gpus=2)

@ray.remote(num_gpus=1)
class GPUWorker:
    def __init__(self, gpu_id: int):
        self.device = torch.device(f"cuda:{gpu_id}")

# 듀얼 GPU 워커
gpu_worker_0 = GPUWorker.remote(0)
gpu_worker_1 = GPUWorker.remote(1)

# 병렬 처리
future1 = gpu_worker_0.process_video_chunk.remote(0, mid_frame, params)
future2 = gpu_worker_1.process_video_chunk.remote(mid_frame, total_frames, params)
result1, result2 = ray.get([future1, future2])
```

## 🔥 실제 WAN2.2 모델 위치 (중요! 반드시 확인!)

### Windows PC (C:\WORK\ArtifexPro)
```
C:\WORK\ArtifexPro\
├── Wan2.2-T2V-A14B\            # Text-to-Video 14B 모델
│   ├── models_t5_umt5-xxl-enc-bf16.pth (11.3GB)
│   ├── Wan2.1_VAE.pth (507MB)
│   ├── high_noise_model\
│   └── low_noise_model\
├── Wan2.2-I2V-A14B\            # Image-to-Video 14B 모델  
│   ├── high_noise_model\
│   └── assets\
├── Wan2.2-TI2V-5B\             # Text/Image-to-Video 5B 모델 ⭐
│   ├── diffusion_pytorch_model-00001-of-00003.safetensors (9.8GB)
│   ├── diffusion_pytorch_model-00002-of-00003.safetensors (9.9GB)
│   ├── diffusion_pytorch_model-00003-of-00003.safetensors (178MB)
│   ├── models_t5_umt5-xxl-enc-bf16.pth (11.3GB)
│   └── Wan2.2_VAE.pth (2.8GB)
├── Wan2.2-S2V-14B\             # Sound-to-Video 14B 모델
│   ├── diffusion_pytorch_model-00001-of-00004.safetensors (9.9GB)
│   ├── diffusion_pytorch_model-00002-of-00004.safetensors (9.8GB)
│   ├── diffusion_pytorch_model-00003-of-00004.safetensors (9.9GB)
│   ├── diffusion_pytorch_model-00004-of-00004.safetensors (2.7GB)
│   └── Wan2.1_VAE.pth (507MB)
└── Wan2.2\                     # WAN2.2 코어 라이브러리
    └── wan\
        └── configs\
            ├── wan_ti2v_5B.py
            ├── wan_t2v_A14B.py
            ├── wan_i2v_A14B.py
            └── wan_s2v_14B.py
```

### Pop!_OS PC (~/ArtifexPro/models)
```
/home/stevenlim/ArtifexPro/
└── models/
    ├── Wan2.2-TI2V-5B/         # TI2V 5B 모델 ⭐
    │   ├── diffusion_pytorch_model-00001-of-00003.safetensors
    │   ├── diffusion_pytorch_model-00002-of-00003.safetensors
    │   ├── diffusion_pytorch_model-00003-of-00003.safetensors
    │   ├── models_t5_umt5-xxl-enc-bf16.pth
    │   └── Wan2.2_VAE.pth
    └── Wan2.2-S2V-14B/         # S2V 14B 모델
        ├── diffusion_pytorch_model-00001-of-00004.safetensors
        ├── diffusion_pytorch_model-00002-of-00004.safetensors
        ├── diffusion_pytorch_model-00003-of-00004.safetensors
        ├── diffusion_pytorch_model-00004-of-00004.safetensors
        └── Wan2.1_VAE.pth
```

## 💡 중요 파일들

### 실제 모델 추론 코드
- `backend/wan22_actual_inference.py` - 실제 WAN2.2 모델 로드 및 추론
- `backend/wan22_real_inference.py` - WAN2.2 실제 모델 추론 모듈
- `backend/wan22_optimized.py` - 최적화된 WAN2.2 추론
- `backend/real_video_generator.py` - 실제 AI 비디오 생성 모듈

### 분산 처리 백엔드
- `backend/distributed_gpu_api.py` - Windows + Pop!_OS 분산 GPU 처리 (포트 8003)
- `backend/dual_gpu_api.py` - 듀얼 GPU 백엔드 (포트 8002)
- `backend/simple_api.py` - 기본 API 서버 (포트 8001)

### 프론트엔드
- `src/components/Wan22Professional.tsx` - WAN2.2 전문가 UI
- `src/services/api.ts` - API 서비스 (분산 GPU 지원)

## Notes
- 이 파일은 Claude가 ArtifexPro 프로젝트 정보를 기억하는 데 사용됩니다
- **⚡ 모든 기능들에서 GPU 듀얼모드를 반드시 사용해야 합니다**
- Node-based 편집과 Wan2.2 AI 통합이 핵심 기능입니다
- 온디바이스 처리를 우선하며, 필요시 클라우드 확장 가능합니다
- Windows(UI/프론트) + Pop!_OS(AI/백엔드) 듀얼 PC 개발 환경 구축 완료
- Ray Cluster로 2x RTX 3090 GPU를 활용한 병렬 처리 필수
- **실제 WAN2.2 모델들이 이미 다운로드되어 있음! 위 경로 참조!**

## 클로드 코드에서의 mcp-installer를 사용한 MCP (Model Context Protocol) 설치 및 설정 가이드 
공통 주의사항
1. 현재 사용 환경을 확인할 것. 모르면 사용자에게 물어볼 것. 
2. OS(윈도우,리눅스,맥) 및 환경들(WSL,파워셀,명령프롬프트등)을 파악해서 그에 맞게 세팅할 것. 모르면 사용자에게 물어볼 것.
3. mcp-installer을 이용해 필요한 MCP들을 설치할 것
   (user 스코프로 설치 및 적용할것)
4. 특정 MCP 설치시, 바로 설치하지 말고, WebSearch 도구로 해당 MCP의 공식 사이트 확인하고 현재 OS 및 환경 매치하여, 공식 설치법부터 확인할 것
5. 공식 사이트 확인 후에는 context7 MCP 존재하는 경우, context7으로 다시 한번 확인할 것
6. MCP 설치 후, task를 통해 디버그 모드로 서브 에이전트 구동한 후, /mcp 를 통해 실제 작동여부를 반드시 확인할 것 
7. 설정 시, API KEY 환경 변수 설정이 필요한 경우, 가상의 API 키로 디폴트로 설치 및 설정 후, 올바른 API 키 정보를 입력해야 함을 사용자에게 알릴 것
8. Mysql MCP와 같이 특정 서버가 구동중 상태여만 정상 작동한 것은 에러가 나도 재설치하지 말고, 정상 구동을 위한 조건을 사용자에게 알릴 것
9. 현재 클로드 코드가 실행되는 환경이야.
10. 설치 요청 받은 MCP만 설치하면 돼. 혹시 이미 설치된 다른 MCP 에러 있어도, 그냥 둘 것
11. 일단, 터미널에서 설치하려는 MCP 작동 성공한 경우, 성공 시의 인자 및 환경 변수 이름을 활용해, 올바른 위치의 json 파일에 MCP 설정을 직접할 것
12. WSL sudo 패스워드: qsc1445!   

*윈도우에서의 주의사항*
1. 설정 파일 직접 세팅시, Windows 경로 구분자는 백슬래시(\)이며, JSON 내에서는 반드시 이스케이프 처리(\\\\)해야 해.
** OS 공통 주의사항**
1. Node.js가 %PATH%에 등록되어 있는지, 버전이 최소 v18 이상인지 확인할 것
2. npx -y 옵션을 추가하면 버전 호환성 문제를 줄일 수 있음

### MCP 서버 설치 순서

1. 기본 설치
	mcp-installer를 사용해 설치할 것

2. 설치 후 정상 설치 여부 확인하기	
	claude mcp list 으로 설치 목록에 포함되는지 내용 확인한 후,
	task를 통해 디버그 모드로 서브 에이전트 구동한 후 (claude --debug), 최대 2분 동안 관찰한 후, 그 동안의 디버그 메시지(에러 시 관련 내용이 출력됨)를 확인하고 /mcp 를 통해(Bash(echo "/mcp" | claude --debug)) 실제 작동여부를 반드시 확인할 것

3. 문제 있을때 다음을 통해 직접 설치할 것

	*User 스코프로 claude mcp add 명령어를 통한 설정 파일 세팅 예시*
	예시1:
	claude mcp add --scope user youtube-mcp \
	  -e YOUTUBE_API_KEY=$YOUR_YT_API_KEY \

	  -e YOUTUBE_TRANSCRIPT_LANG=ko \
	  -- npx -y youtube-data-mcp-server


4. 정상 설치 여부 확인 하기
	claude mcp list 으로 설치 목록에 포함되는지 내용 확인한 후,
	task를 통해 디버그 모드로 서브 에이전트 구동한 후 (claude --debug), 최대 2분 동안 관찰한 후, 그 동안의 디버그 메시지(에러 시 관련 내용이 출력됨)를 확인하고, /mcp 를 통해(Bash(echo "/mcp" | claude --debug)) 실제 작동여부를 반드시 확인할 것


5. 문제 있을때 공식 사이트 다시 확인후 권장되는 방법으로 설치 및 설정할 것
	(npm/npx 패키지를 찾을 수 없는 경우) pm 전역 설치 경로 확인 : npm config get prefix
	권장되는 방법을 확인한 후, npm, pip, uvx, pip 등으로 직접 설치할 것

	#### uvx 명령어를 찾을 수 없는 경우
	# uv 설치 (Python 패키지 관리자)
	curl -LsSf https://astral.sh/uv/install.sh | sh

	#### npm/npx 패키지를 찾을 수 없는 경우
	# npm 전역 설치 경로 확인
	npm config get prefix


	#### uvx 명령어를 찾을 수 없는 경우
	# uv 설치 (Python 패키지 관리자)
	curl -LsSf https://astral.sh/uv/install.sh | sh


	## 설치 후 터미널 상에서 작동 여부 점검할 것 ##
	
	## 위 방법으로, 터미널에서 작동 성공한 경우, 성공 시의 인자 및 환경 변수 이름을 활용해서, 클로드 코드의 올바른 위치의 json 설정 파일에 MCP를 직접 설정할 것 ##


	설정 예시
		(설정 파일 위치)
		**리눅스, macOS 또는 윈도우 WSL 기반의 클로드 코드인 경우**
		- **User 설정**: `~/.claude/` 디렉토리
		- **Project 설정**: 프로젝트 루트/.claude

		**윈도우 네이티브 클로드 코드인 경우**
		- **User 설정**: `C:\Users\{사용자명}\.claude` 디렉토리
		- *User 설정파일*  C:\Users\{사용자명}\.claude.json
		- **Project 설정**: 프로젝트 루트\.claude

		1. npx 사용

		{
		  "youtube-mcp": {
		    "type": "stdio",
		    "command": "npx",
		    "args": ["-y", "youtube-data-mcp-server"],
		    "env": {
		      "YOUTUBE_API_KEY": "YOUR_API_KEY_HERE",
		      "YOUTUBE_TRANSCRIPT_LANG": "ko"
		    }
		  }
		}


		2. cmd.exe 래퍼 + 자동 동의)
		{
		  "mcpServers": {
		    "mcp-installer": {
		      "command": "cmd.exe",
		      "args": ["/c", "npx", "-y", "@anaisbetts/mcp-installer"],
		      "type": "stdio"
		    }
		  }
		}

		3. 파워셀예시
		{
		  "command": "powershell.exe",
		  "args": [
		    "-NoLogo", "-NoProfile",
		    "-Command", "npx -y @anaisbetts/mcp-installer"
		  ]
		}

		4. npx 대신 node 지정
		{
		  "command": "node",
		  "args": [
		    "%APPDATA%\\npm\\node_modules\\@anaisbetts\\mcp-installer\\dist\\index.js"
		  ]
		}

		5. args 배열 설계 시 체크리스트
		토큰 단위 분리: "args": ["/c","npx","-y","pkg"] 와
			"args": ["/c","npx -y pkg"] 는 동일해보여도 cmd.exe 내부에서 따옴표 처리 방식이 달라질 수 있음. 분리가 안전.
		경로 포함 시: JSON에서는 \\ 두 번. 예) "C:\\tools\\mcp\\server.js".
		환경변수 전달:
			"env": { "UV_DEPS_CACHE": "%TEMP%\\uvcache" }
		타임아웃 조정: 느린 PC라면 MCP_TIMEOUT 환경변수로 부팅 최대 시간을 늘릴 수 있음 (예: 10000 = 10 초) 

**중요사항**
	윈도우 네이티브 환경이고 MCP 설정에 어려움이 있는데 npx 환경이라면, cmd나 node 등으로 다음과 같이 대체해 볼것:
	{
	"mcpServers": {
	      "context7": {
		 "command": "cmd",
		 "args": ["/c", "npx", "-y", "@upstash/context7-mcp@latest"]
	      }
	   }
	}

	claude mcp add-json context7 -s user '{"type":"stdio","command":"cmd","args": ["/c", "npx", "-y", "@upstash/context7-mcp@latest"]}'

(설치 및 설정한 후는 항상 아래 내용으로 검증할 것)
	claude mcp list 으로 설치 목록에 포함되는지 내용 확인한 후,
	task를 통해 디버그 모드로 서브 에이전트 구동한 후 (claude --debug), 최대 2분 동안 관찰한 후, 그 동안의 디버그 메시지(에러 시 관련 내용이 출력됨)를 확인하고 /mcp 를 통해 실제 작동여부를 반드시 확인할 것

ㅊㅇ 
		
** MCP 서버 제거가 필요할 때 예시: **
claude mcp remove youtube-mcp


## 윈도우 네이티브 클로드 코드에서 클로드 데스크탑의 MCP 가져오는 방법 ###
"C:\Users\<사용자이름>\AppData\Roaming\Claude\claude_desktop_config.json" 이 파일이 존재한다면 클로드 데스크탑이 설치된 상태야.
이 파일의 mcpServers 내용을 클로드 코드 설정 파일(C:\Users\{사용자명}\.claude.json)의 user 스코프 위치(projects 항목에 속하지 않은 mcpServers가 user 스코프에 해당)로 그대로 가지고 오면 돼.
가지고 온 후, task를 통해 디버그 모드로 서브 에이전트 구동하여 (claude --debug) 클로드 코드에 문제가 없는지 확인할 것

