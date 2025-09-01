## ArtifexPro 하이엔드 영상 생성·편집 앱 설계서

### 1) 제품 개요
- **포지셔닝**: 오프라인(온디바이스) 우선의 하이엔드 영상 생성·편집 데스크톱 앱(Windows 중심). 상업용 유료 제품 수준의 안정성·성능·UX 목표.
- **핵심 기능**: Wan2.2 기반 T2V, I2V, TI2V, S2V + NLE(논리니어 편집기) + 스타일/룩 관리 + 배치/큐 + 모델 매니저 + 프로젝트/에셋 관리.

### 2) 기술 스택
- **프론트엔드(데스크톱)**: Tauri(권장) 또는 Electron
- **백엔드(API)**: Python + FastAPI(HTTP/WS) + Uvicorn
- **추론 엔진**: PyTorch + CUDA 12.x, xFormers/FlashAttention, `Wan2.2`
- **작업 큐**: 로컬 프로세스 큐 또는 Redis+RQ
- **미디어 I/O**: FFmpeg, PyAV, NVENC/NVDEC
- **저장소**: SQLite(기본) / Postgres(옵션)
- **로깅/텔레메트리**: 로컬 파일 로그, 옵트인 원격 오류 리포트(Sentry 등)
- **패키징**: 백엔드 PyInstaller, 프론트엔드 Tauri 빌드/MSI

### 3) 상위 아키텍처
- **UI 레이어**: 타임라인, 뷰어(프록시/프리뷰), 파라미터 패널, 프롬프트 트랙, 에셋 브라우저
- **응용 서비스**: 프로젝트/에셋/프리셋/스타일 관리, 잡/큐 관리, 모델 매니저
- **추론 서비스**: T2V/I2V/TI2V/S2V 래퍼, VRAM/성능 튜닝, 캐시
- **미디어 서비스**: 디코드/엔코드, 프록시 생성, 오디오 분석(옵션: Whisper)
- **스토리지**: 프로젝트 DB(SQLite) + 미디어/캐시 디렉토리
- **시스템 서비스**: GPU/드라이버 탐지, 업데이트, 라이선싱, 권한/격리

### 4) 디렉토리 구조(제안)
```text
ArtifexPro/
  app/                      # Tauri/Electron 프론트엔드
  backend/
    api/                    # FastAPI 엔드포인트
    inference/              # Wan2.2 래퍼, 파이프라인 구현
    media/                  # FFmpeg, 프록시, 트랜스코딩
    jobs/                   # 잡 모델/큐/워크플로
    models/                 # 모델 매니저(다운로드/버전/무결성)
    storage/                # SQLite, 프로젝트/에셋 매핑
    utils/                  # 공통 도구(성능, 로깅, 권한)
  models/                   # Wan2.2 가중치/리소스(기존 폴더 연결/심링크)
  cache/
  projects/
  installers/
  docs/
```

### 5) 주요 워크플로
- **T2V**: 텍스트 → Wan2.2 T2V → 무손실 이미지 시퀀스 → 프록시 생성 → 최종 렌더(NVENC)
- **I2V/TI2V**: 참조 이미지/키프레임 + 텍스트 → 동일 파이프라인
- **S2V**: 음성 분석(옵션: Whisper) + Wan2.2 S2V → 립싱크/표정 가중치
- **공통**: 프리셋, 시드 고정/랜덤, 모션 강도, 업스케일/디노이즈, 시네마틱 룩
- **NLE 통합**: 생성 결과를 타임라인 클립으로 드롭, **프롬프트 트랙**으로 시간축 기반 스타일 전환

### 6) 백엔드 API(요약)
- Jobs
  - POST `/jobs` → `{type: "t2v|i2v|ti2v|s2v", params..., mediaRefs...}`
  - GET `/jobs/{id}` 상태
  - WS `/jobs/{id}/progress` 진행률/VRAM/ETA
- Media
  - POST `/media/import` 로컬/URL 자산 등록
  - POST `/media/proxy` 프록시 생성
- Models
  - GET `/models` 목록/버전/무결성
  - POST `/models/switch` 활성 모델 변경, 워밍업
- System
  - GET `/system/gpu` GPU/VRAM/드라이버
  - GET `/system/health` 서비스 상태

### 7) 성능 최적화 전략
- 혼합정밀 bf16/fp16 + `channels_last`
- 메모리: attention slicing, CPU 오프로드, 타일드 디퓨전(고해상도)
- 가속: xFormers/FlashAttention, TensorRT(옵션)
- 멀티GPU: 데이터 병렬/파이프라인 분할(옵션)
- 캐싱: 모션/노이즈 시드, 중간 feature(옵션), 프록시 해상도 동적
- 렌더: NVENC CBR/VBR, 10-bit/HDR(옵션)

### 8) 모델 관리
- safetensors index 검사, 해시/크기 검증
- 고/저노이즈 모델 자동 선택 + Warm-up 로드
- 버전 잠금, 프로젝트별 종속성 기록(재현성)

### 9) NLE/UX 하이라이트
- 타임라인: 영상/오디오/프롬프트 트랙, 스냅/마그넷, Ripple 편집
- 뷰어: 프록시/풀퀄리티 토글, 프레임/스코프 표시
- 파라미터 패널: 파이프라인/룩 프리셋, 키프레임 가능
- 배치/큐: 우선순위, 시간대 예약, AC 전원 시 자동 렌더
- 크래시 복구: 잡 체크포인트, 오토세이브
- 컬러/룩: LUT, 노드형 보정(옵션), 업스케일/디노이즈 스테이지

### 10) 보안·안정성
- 백엔드 별도 프로세스 격리, 폴더 접근 화이트리스트
- 실행 정책: 서명/무결성 검사, 자동 업데이트(서명 검증)
- 민감 정보(라이선스 키) OS 보안 스토리지 사용

### 11) 라이선싱/상용화
- 라이선스 서버(옵션): 오프라인 활성화(기간 제한), 온라인 정식 활성화
- 플랜 예시
  - Perpetual + 1년 업데이트
  - 구독(Pro) 월 $15–$25: 자동업데이트/고급 기능(분산 렌더 등)
  - 팀 라이선스 할인
- 트라이얼: 워터마크/해상도 제한, 14일
- 옵트인 텔레메트리: 성능/크래시만 수집, 익명화

### 12) 클라우드 가속(옵션, 비용 투명성)
- 단기 렌더 팜: AWS g5/g6(대략 시간당 $0.7–$2.5)
- 1080p 고품질 1분 T2V 렌더 비용 예시: ~$0.5–$2(설정·재시도에 따라 상이)
- 예산 낮을 때: 로컬 단일 GPU, 야간 배치 렌더 권장

### 13) 초기 하드웨어 권장 사양
- 최소: NVIDIA 12GB VRAM, RAM 32GB, NVMe 1TB
- 권장: 24GB+ VRAM(4090/6000 Ada), RAM 64GB, NVMe 2TB+
- 드라이버/CUDA: 최신 안정 릴리스, 전원/쓰로틀 관리

### 14) 단계별 로드맵
- M1: 백엔드 스캐폴드(FastAPI, 잡/미디어/모델), T2V MVP, FFmpeg I/O
- M2: I2V/TI2V/S2V 통합, 프록시/타임라인 뷰어, 프롬프트 트랙
- M3: 성능 튜닝(xFormers/FlashAttn), 멀티GPU, 캐시, NVENC 파이프라인
- M4: 모델 매니저/프리셋, 크래시 복구, 라이선싱/업데이트
- M5: QA/벤치/프로파일링, MSI 인스톨러, 문서/튜토리얼, 출시

### 15) 법적·라이선스 고려사항
- `Wan2.2` 및 포함 모델/가중치의 상업적 이용 조건 확인(`LICENSE.txt` 준수)
- 제3자 라이브러리(FFmpeg 코덱 등) 라이선스 컴플라이언스 문서화
- 사용자 콘텐츠/프라이버시 정책, EULA 포함

---
본 설계서는 루트 디렉토리의 `Wan2.2*` 리소스를 활용하는 것을 전제로 하며, 모델/가중치 디렉토리는 `models/` 하위에 연결(복사 또는 심링크)하여 일관된 경로 체계를 유지하는 것을 권장합니다.

## Wan2.2 기능·파라미터·최적 성능 설계 (상세)

### A) 파이프라인 기능 총정리
- **Text-to-Video (T2V, A14B)**
  - 파일: `wan/text2video.py`, 설정: `wan/configs/wan_t2v_A14B.py`
  - 입력: `prompt`, 크기 `size=(W,H)`, `frame_num(4n+1)`, `sampling_steps`, `guide_scale(단일/튜플)`, `shift`, `n_prompt`, `seed`
  - 특성: 저노이즈/고노이즈 모델 분기(boundary) + CFG, UniPC 또는 DPM++ 스케줄러
  - VAE: `Wan2_1_VAE` (stride (4,8,8))

- **Image-to-Video (I2V, A14B)**
  - 파일: `wan/image2video.py`, 설정: `wan/configs/wan_i2v_A14B.py`
  - 입력: `prompt`, `img`, `max_area`, `frame_num(4n+1)`, `sampling_steps`, `guide_scale`, `shift`, `n_prompt`, `seed`
  - 특성: 입력 이미지를 중심 크롭/스케일, 마스크를 활용한 첫 프레임 고정 방식, 저/고노이즈 분기
  - 권장: 480p 타깃 시 `shift=3.0`

- **Text&Image-to-Video (TI2V, 5B)**
  - 파일: `wan/textimage2video.py`, 설정: `wan/configs/wan_ti2v_5B.py`
  - 입력: `prompt`, `img(옵션)`, `size` 또는 `max_area`, `frame_num(4n+1)`, `sampling_steps`, `guide_scale`, `shift`, `seed`
  - 특성: 단일 모델(저/고 통합), `Wan2_2_VAE`(stride (4,16,16)), 720p@24fps 최적화

- **Speech-to-Video (S2V, 14B)**
  - 파일: `wan/speech2video.py`, 설정: `wan/configs/wan_s2v_14B.py`
  - 입력: `prompt`, `ref_image_path`, `audio_path`, `pose_video(옵션)`, `num_repeat`, `max_area`, `infer_frames(4n)`, `sampling_steps`, `guide_scale`, `init_first_frame`
  - 특성: Wav2Vec2 기반 오디오 피처 + CausalAudioEncoder, 포즈 구동 옵션, 첫 프레임 고정 가능

### B) 공통 하이퍼파라미터 및 권장값
- **샘플러**: `sample_solver`는 `unipc` 기본(권장), 대안 `dpm++`
- **스텝**: T2V 50, I2V 40, TI2V 50, S2V 40(레포 기본값 기준). 품질 상승 필요 시 +10~+20
- **가이던스**: 단일 스칼라 또는 `(low_noise, high_noise)` 튜플
  - 예: T2V `(3.0, 4.0)`, I2V `(3.5, 3.5)`, S2V `4.5`, TI2V `5.0`
- **프레임 수**: 4n(+1) 제약 준수. 121프레임(약 5초@24fps)이 품질/시간 균형 좋음
- **해상도/영역**: `SUPPORTED_SIZES` 준수. I2V/S2V는 `max_area`로 자동 산출
- **네거티브 프롬프트**: `shared_config.sample_neg_prompt` 활용(과도한 아트 스타일 방지)

### C) 성능 최적화 설계(단일/다중 GPU)
- **데이터 타입/혼합정밀**: `param_dtype=bfloat16` + CUDA autocast. 가능하면 Hopper+FA3
- **오프로드**: `offload_model=True`로 단계별 CPU<->GPU 전환, T5는 `t5_cpu=True` 옵션 병행
- **시퀀스 패러럴(USP)**: `use_sp=True` 시 `sequence_parallel.sp_dit_forward` 경로 적용
- **FSDP**: `dit_fsdp=True`/`t5_fsdp=True`로 블록 단위 샤딩(`distributed/fsdp.py`)
- **Ulysses 어텐션**: `distributed/ulysses.py` 활용. 멀티GPU에서 QKV 분산
- **스케줄러 튜닝**: UniPC에서 `shift` 조절(3.0~5.0)로 동적/노이즈 밸런스 조절
- **메모리**: `init_on_cpu=True`, `convert_model_dtype=True`, 필요 시 `torch.cuda.empty_cache()` 구간 호출 유지

권장 프리셋(예)
- 720p 고품질(T2V): steps=60, guide=(3.0,4.5), frame_num=121, shift=5.0, unipc
- 720p 빠른 미리보기(T2V): steps=36, guide=(2.5,3.5), frame_num=81, shift=4.0
- I2V 480p: max_area=480*832, shift=3.0, steps=40, guide=(3.5,3.5)
- TI2V 720p@24fps: frame_num=121, steps=50, guide=5.0, shift=5.0
- S2V 704x1024: infer_frames=80, steps=40, guide=4.5, pose_video 사용 시 일관 포즈 확보

### D) 입출력/유틸/미디어 파이프라인
- **비디오 저장**: `wan/utils/utils.py::save_video` (imageio/libx264). 후처리 NVENC로 대체 가능
- **오디오 병합**: `merge_video_audio(video,audio)`, 곡선 길이 짧은 쪽에 맞춤
- **비디오 읽기**: `wan/utils/qwen_vl_utils.py`(torchvision/decord 백엔드)
- **사이즈 계산**: `best_output_size()`, stride·패치 정렬 보장

### E) 모델/가중치·구성 관리
- `wan/configs/__init__.py`의 `WAN_CONFIGS`와 `SUPPORTED_SIZES` 사용
- 체크포인트 폴더: `low_noise_model`/`high_noise_model`(14B), 단일 `from_pretrained`(5B)
- T5: `umt5-xxl`, 체크포인트 `models_t5_umt5-xxl-enc-bf16.pth`
- VAE: 2.1(V1) vs 2.2(V2) 구분. TI2V는 `Wan2_2_VAE`

### F) 품질 레시피
- **프롬프트 확장**: 레포 가이드의 Prompt Extension 옵션 사용(품질 상승)
- **시드 전략**: 시드 고정으로 재현성, 시드 스윕으로 베스트 샘플 탐색
- **시간 일관성**: frame_num을 121 등 충분히 확보, steps를 50~70로 올려 잔떨림 최소화
- **컬러/노이즈**: 네거티브 프롬프트 유지, 필요 시 후처리(디노이즈/샤프닝)

### G) 멀티GPU 실행 프리셋(레포 기준)
- FSDP+Ulysses: `torchrun --nproc_per_node=8 generate.py --task t2v-A14B --size 1280*720 --ckpt_dir ./Wan2.2-T2V-A14B --dit_fsdp --t5_fsdp --ulysses_size 8 --prompt "..."`
- S2V 포즈+오디오: `torchrun --nproc_per_node=8 generate.py --task s2v-14B --size 1024*704 --ckpt_dir ./Wan2.2-S2V-14B --dit_fsdp --t5_fsdp --ulysses_size 8 --prompt "..." --image examples/pose.png --audio examples/sing.MP3 --pose_video examples/pose.mp4`

### H) 통합 설계 가이드(앱 적용)
- 백엔드 잡 파라미터에 공통 필드 포함: `solver`, `steps`, `guide`, `shift`, `frame_num`, `seed`, `offload`, `dtype`
- UI 프리셋: 위 권장 프리셋을 버튼·템플릿화. 고급 설정은 드롭다운
- 모델 스위처: `WAN_CONFIGS` 키 기준으로 동적 로드 및 워밍업
- 장애 대응: VRAM 부족 시 자동 `offload_model=True`, `t5_cpu=True`, `convert_model_dtype`



