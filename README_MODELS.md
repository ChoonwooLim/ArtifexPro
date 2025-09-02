# 🎉 Wan2.2 모델 준비 완료!

## ✅ 모델 상태
- **Wan2.2-TI2V-5B** (32GB) - Pop!_OS에 설치 완료 ✅
  - 경로: `/home/stevenlim/ArtifexPro/models/Wan2.2-TI2V-5B`
  - 파일: 3개의 safetensors 파일 (9.2GB + 9.3GB + 0.2GB)
  
- **Wan2.2-S2V-14B** (31GB) - Pop!_OS에 설치 완료 ✅
  - 경로: `/home/stevenlim/ArtifexPro/models/Wan2.2-S2V-14B`
  - 파일: 4개의 safetensors 파일 (9.3GB + 9.2GB + 9.3GB + 2.6GB)

## 🚀 실행 방법

### 1. 백엔드 서버 시작 (Pop!_OS)
```bash
cd ~/ArtifexPro
source venv/bin/activate
python backend/api/ti2v_s2v_api.py
```

### 2. 프론트엔드 시작 (Windows)
```powershell
.\start-ti2v-s2v.ps1
```

## 🎮 RTX 3090 호환성
- **TI2V-5B**: ✅ 완벽 호환 (단일 GPU로 충분)
- **S2V-14B**: ✅ CPU 오프로딩으로 실행 가능

## 📝 API 엔드포인트
- `POST /api/ti2v/generate` - Text+Image to Video
- `POST /api/s2v/generate` - Audio to Video
- `GET /api/job/{job_id}` - 작업 상태 확인
- `WS /ws/updates` - 실시간 진행률

## 💡 팁
- TI2V: 720p, 5-10초 클립이 최적
- S2V: 오디오 길이에 자동 맞춤
- Quality: "balanced" 추천 (속도/품질 균형)