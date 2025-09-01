# Claude Development Notes

## Project Information
- **Project Name**: ArtifexPro Studio
- **Location**: C:\WORK\ArtifexPro
- **Type**: AI 영상 생성/편집 플랫폼 (Node-based + Timeline)
- **Architecture**: 3-Tier + Node System (온디바이스 우선, 클라우드 선택형)

## Development Commands
- `npm run dev` - Start development server
- `npm run build` - Production build
- `npm run test` - Run tests
- `npm run lint` - Lint code
- `npm run typecheck` - Type checking
- `python -m pytest` - Run Python tests
- `python scripts/wan22_setup.py` - Setup Wan2.2 models

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

### GPU 최적화
- **Multi-GPU**: FSDP, Ulysses Attention
- **Memory**: CPU Offloading, Gradient Checkpointing
- **Inference**: TensorRT, ONNX Runtime

## 핵심 기능 모듈

### 1. Node Graph Engine (NGE)
- 실시간 노드 처리 파이프라인
- GPU 가속 프리뷰
- 자동 타입 변환
- 의존성 분석 및 병렬 처리

### 2. Wan2.2 Integration
- 스마트 모델 로딩 (VRAM 기반 자동 최적화)
- 품질 프리셋 (Draft, Preview, Production, Cinema)
- 프롬프트 확장 및 스타일 인코딩
- 멀티 GPU 분산 처리

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

### Generation Speed (RTX 4090 기준)
- T2V 720p 5s: < 2분
- I2V 720p 5s: < 90초
- TI2V 720p 5s: < 60초 (5B model)
- S2V 720p 5s: < 2분

### Memory Requirements
- Minimum: 24GB VRAM
- Optimal: 48GB VRAM
- Enterprise: 80GB+ VRAM

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

## Notes
- 이 파일은 Claude가 ArtifexPro 프로젝트 정보를 기억하는 데 사용됩니다
- Node-based 편집과 Wan2.2 AI 통합이 핵심 기능입니다
- 온디바이스 처리를 우선하며, 필요시 클라우드 확장 가능합니다

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

