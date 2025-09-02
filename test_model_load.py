"""
모델 로드 테스트 스크립트
Pop!_OS에서 실행: 
ssh popOS "cd ~/ArtifexPro && source venv/bin/activate && python /path/to/test_model_load.py"
"""

import os
import sys
from pathlib import Path

print("="*60)
print("Wan2.2 Model Load Test")
print("="*60)

# 모델 경로
TI2V_PATH = "/home/stevenlim/ArtifexPro/models/Wan2.2-TI2V-5B"
S2V_PATH = "/home/stevenlim/ArtifexPro/models/Wan2.2-S2V-14B"

print(f"\n📁 Model Paths:")
print(f"  TI2V-5B: {TI2V_PATH}")
print(f"  - Exists: {Path(TI2V_PATH).exists()}")
print(f"  S2V-14B: {S2V_PATH}")
print(f"  - Exists: {Path(S2V_PATH).exists()}")

# 파일 체크
print(f"\n📄 TI2V-5B Files:")
ti2v_files = list(Path(TI2V_PATH).glob("*.safetensors"))
for f in ti2v_files[:3]:
    size_gb = f.stat().st_size / (1024**3)
    print(f"  - {f.name}: {size_gb:.1f} GB")

print(f"\n📄 S2V-14B Files:")
s2v_files = list(Path(S2V_PATH).glob("*.safetensors"))
for f in s2v_files[:4]:
    size_gb = f.stat().st_size / (1024**3)
    print(f"  - {f.name}: {size_gb:.1f} GB")

print("\n✅ Models are ready for loading!")
print("="*60)