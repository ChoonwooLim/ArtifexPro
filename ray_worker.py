"""
Windows Ray Worker for RTX 3090
Pop!_OS와 연결하여 듀얼 GPU 클러스터 구성
"""

import ray
import torch
import os

def setup_ray_worker():
    """Windows를 Ray Worker로 설정"""
    print("🖥️ Windows RTX 3090 Ray Worker Setup")
    print("="*50)
    
    # GPU 정보 확인
    if torch.cuda.is_available():
        gpu_name = torch.cuda.get_device_name(0)
        gpu_memory = torch.cuda.get_device_properties(0).total_memory / 1e9
        print(f"✅ GPU Detected: {gpu_name}")
        print(f"   VRAM: {gpu_memory:.1f} GB")
    else:
        print("❌ No GPU detected!")
        return
    
    # Ray 클러스터 연결
    try:
        # Pop!_OS Head Node에 연결
        ray.init(address='ray://192.168.219.150:10001')
        print("\n✅ Connected to Ray Cluster!")
        
        # 클러스터 정보
        print("\n📊 Cluster Resources:")
        resources = ray.cluster_resources()
        print(f"   Total CPUs: {resources.get('CPU', 0)}")
        print(f"   Total GPUs: {resources.get('GPU', 0)}")
        print(f"   Total Memory: {resources.get('memory', 0) / 1e9:.1f} GB")
        
    except Exception as e:
        print(f"\n❌ Failed to connect: {e}")
        print("\n💡 Make sure:")
        print("   1. Pop!_OS Ray head is running")
        print("   2. Network connection is active")
        print("   3. Firewall allows port 6379")

@ray.remote(num_gpus=1)
class WindowsGPUWorker:
    """Windows GPU 작업 처리"""
    def __init__(self):
        self.device = "cuda:0"
        self.gpu_name = torch.cuda.get_device_name(0)
        
    def process_upscale(self, video_data):
        """비디오 업스케일링 (Windows GPU 처리)"""
        print(f"Processing on {self.gpu_name}")
        # 업스케일링 로직
        return "upscaled_video"
    
    def process_encoding(self, video_data, codec="h265"):
        """NVENC 인코딩 (Windows GPU 처리)"""
        print(f"Encoding with NVENC on {self.gpu_name}")
        # 인코딩 로직
        return "encoded_video"

if __name__ == "__main__":
    setup_ray_worker()
    
    # Worker 유지
    print("\n🔄 Ray Worker is running...")
    print("Press Ctrl+C to stop")
    
    try:
        import time
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n👋 Shutting down Ray Worker...")
        ray.shutdown()