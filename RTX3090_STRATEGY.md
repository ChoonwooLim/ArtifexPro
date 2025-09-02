# RTX 3090 x2 (48GB VRAM) 실행 전략

## 📊 하드웨어 현황
- **Pop!_OS PC**: RTX 3090 (24GB VRAM)
- **Windows PC**: RTX 3090 (24GB VRAM)
- **총 VRAM**: 48GB
- **네트워크**: 10GbE 직결 연결

## 🎯 모델별 실행 가능성

### ✅ 안정적 실행 가능
1. **Wan2.2-TI2V-5B (32GB)**
   - 단일 GPU에서도 실행 가능
   - FP16 사용시 실제 ~16GB VRAM 사용
   - 가장 안정적이고 빠른 실행

2. **Wan2.2-S2V-14B (31GB)**
   - 단일 GPU + CPU 오프로딩으로 실행
   - 또는 듀얼 GPU 분산 실행

### ⚠️ 제한적 실행 가능
3. **Wan2.2-I2V-A14B (54GB)**
   - 듀얼 GPU 필수
   - Accelerate device_map="balanced" 사용
   - 일부 CPU 오프로딩 필요

4. **Wan2.2-T2V-A14B (118GB)**
   - 8-bit 양자화 필수 (품질 약간 저하)
   - DeepSpeed ZeRO-3 + CPU 오프로딩
   - 처리 속도 느림

## 🚀 실행 방법

### 방법 1: TI2V-5B 단독 실행 (권장)
```python
# 단일 GPU에서 안정적 실행
from diffusers import DiffusionPipeline

pipeline = DiffusionPipeline.from_pretrained(
    "Wan2.2-TI2V-5B",
    torch_dtype=torch.float16,
    use_safetensors=True
).to("cuda")

# 메모리 최적화
pipeline.enable_xformers_memory_efficient_attention()
pipeline.enable_vae_slicing()
```

### 방법 2: 듀얼 GPU 분산 (I2V/S2V)
```python
# Accelerate 사용
pipeline = DiffusionPipeline.from_pretrained(
    "Wan2.2-I2V-A14B",
    torch_dtype=torch.float16,
    device_map="balanced",  # GPU 0과 1에 자동 분배
    max_memory={0: "22GB", 1: "22GB", "cpu": "32GB"}
)
```

### 방법 3: Ray 클러스터 (Pop!_OS + Windows)
```bash
# Pop!_OS (Head)
ray start --head --num-gpus=1

# Windows (Worker)
ray start --address='192.168.219.150:6379' --num-gpus=1
```

### 방법 4: 8-bit 양자화 (대형 모델)
```python
from transformers import BitsAndBytesConfig

quantization_config = BitsAndBytesConfig(
    load_in_8bit=True,
    llm_int8_threshold=6.0
)

pipeline = DiffusionPipeline.from_pretrained(
    "Wan2.2-T2V-A14B",
    quantization_config=quantization_config,
    device_map="auto"
)
```

## 📌 권장 워크플로우

### 초급자/안정성 우선
1. **TI2V-5B 사용** (가장 안정적)
2. 단일 GPU 실행
3. 품질: 720p, 5초 클립

### 중급자/균형
1. **TI2V-5B + S2V-14B 조합**
2. 듀얼 GPU 활용
3. 품질: 720p-1080p, 10초 클립

### 고급자/최고 품질
1. **모든 모델 활용**
2. Ray 클러스터 + 양자화
3. 품질: 1080p+, 긴 클립
4. 배치 처리 + 큐 시스템

## 🔧 최적화 팁

1. **메모리 절약**
   - `enable_model_cpu_offload()`
   - `enable_vae_slicing()`
   - `enable_vae_tiling()`
   - Gradient checkpointing

2. **속도 향상**
   - xFormers 사용
   - Flash Attention 2
   - torch.compile()
   - CUDA graphs

3. **안정성**
   - 배치 크기 1 사용
   - FP16 대신 BF16 (A100용)
   - 온도 모니터링
   - 자동 재시작 스크립트

## 💡 실용적 조언

RTX 3090 x2로는:
- **TI2V-5B**: 완벽하게 실행 ✅
- **S2V-14B**: 잘 실행됨 ✅
- **I2V-A14B**: 실행 가능 (느림) ⚠️
- **T2V-A14B**: 매우 제한적 (권장 안함) ❌

**최선의 선택: TI2V-5B를 메인으로 사용하고, 필요시 S2V-14B 추가 활용**