"""
Wan2.2 Model Status Checker
현재 다운로드된 모델 확인 스크립트
"""

import os
from pathlib import Path
import json

def check_model_files(model_dir):
    """모델 디렉토리 체크"""
    model_path = Path(model_dir)
    if not model_path.exists():
        return None
    
    info = {
        "name": model_path.name,
        "path": str(model_path),
        "files": {
            "safetensors": list(model_path.glob("**/*.safetensors")),
            "json": list(model_path.glob("**/*.json")),
            "bin": list(model_path.glob("**/*.bin")),
        },
        "size_gb": sum(f.stat().st_size for f in model_path.rglob("*") if f.is_file()) / (1024**3)
    }
    return info

def main():
    print("=" * 60)
    print("🚀 ArtifexPro - Wan2.2 Model Status")
    print("=" * 60)
    
    models = [
        "Wan2.2-T2V-A14B",
        "Wan2.2-I2V-A14B", 
        "Wan2.2-TI2V-5B",
        "Wan2.2-S2V-14B"
    ]
    
    total_size = 0
    model_status = []
    
    for model in models:
        info = check_model_files(model)
        if info:
            model_status.append(info)
            total_size += info["size_gb"]
            
            print(f"\n✅ {info['name']}")
            print(f"   Size: {info['size_gb']:.1f} GB")
            print(f"   Safetensors: {len(info['files']['safetensors'])} files")
            print(f"   Config: {len(info['files']['json'])} files")
            
            # 모델별 특징
            if "T2V" in model:
                print(f"   Type: Text-to-Video (27B MoE, 14B active)")
                print(f"   VRAM Required: ~80GB")
            elif "I2V" in model:
                print(f"   Type: Image-to-Video (27B MoE)")
                print(f"   VRAM Required: ~80GB")
            elif "TI2V" in model:
                print(f"   Type: Text+Image-to-Video (5B Dense)")
                print(f"   VRAM Required: ~24GB (RTX 4090 가능)")
            elif "S2V" in model:
                print(f"   Type: Speech-to-Video (14B)")
                print(f"   VRAM Required: ~40GB")
        else:
            print(f"\n❌ {model} - Not found")
    
    print("\n" + "=" * 60)
    print(f"📊 Total Models: {len(model_status)}/4")
    print(f"💾 Total Size: {total_size:.1f} GB")
    print("=" * 60)
    
    # 실행 권장사항
    print("\n📝 Recommendations:")
    print("1. TI2V-5B 모델은 RTX 4090 (24GB VRAM)에서 실행 가능")
    print("2. T2V/I2V 모델은 A100 (80GB) 또는 다중 GPU 필요")
    print("3. 모델 파일을 Pop!_OS로 이동 필요 (GPU 서버)")
    print("4. NFS/SMB로 Windows에서 마운트하여 사용 가능")

if __name__ == "__main__":
    main()