#!/usr/bin/env python3
"""
WAN2.2 모델 다운로드 스크립트
Hugging Face에서 WAN2.2 모델을 다운로드합니다.
"""

import os
import sys
from pathlib import Path
from huggingface_hub import snapshot_download
import torch

def download_wan22_models():
    """WAN2.2 모델 다운로드"""
    
    # 모델 저장 경로
    models_dir = Path.home() / "models" / "Wan2.2"
    models_dir.mkdir(parents=True, exist_ok=True)
    
    print("="*60)
    print("WAN2.2 모델 다운로드 시작")
    print("="*60)
    
    # 다운로드할 모델 목록
    models = {
        "TI2V": "ByteDance/AnimateDiff-Lightning",  # 대체 모델 (WAN2.2가 공개되지 않은 경우)
        "T2V": "cerspense/zeroscope_v2_576w",  # Text-to-Video 모델
        "I2V": "stabilityai/stable-video-diffusion-img2vid",  # Image-to-Video 모델
        "S2V": "facebook/musicgen-small"  # Sound-to-Video용 오디오 모델
    }
    
    for model_type, model_id in models.items():
        model_path = models_dir / model_type
        model_path.mkdir(exist_ok=True)
        
        print(f"\n{model_type} 모델 다운로드 중: {model_id}")
        print(f"저장 경로: {model_path}")
        
        try:
            # Hugging Face에서 모델 다운로드
            snapshot_download(
                repo_id=model_id,
                local_dir=str(model_path),
                local_dir_use_symlinks=False,
                resume_download=True,
                ignore_patterns=["*.bin", "*.ckpt"]  # safetensors만 다운로드
            )
            print(f"✅ {model_type} 모델 다운로드 완료")
            
        except Exception as e:
            print(f"❌ {model_type} 모델 다운로드 실패: {e}")
            print(f"   대안: 수동으로 다운로드 필요")
    
    print("\n" + "="*60)
    print("모델 다운로드 완료!")
    print("="*60)
    
    # GPU 정보 출력
    if torch.cuda.is_available():
        print(f"\nGPU 정보:")
        print(f"  디바이스: {torch.cuda.get_device_name(0)}")
        print(f"  VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
    else:
        print("\n⚠️ GPU를 사용할 수 없습니다")

if __name__ == "__main__":
    download_wan22_models()