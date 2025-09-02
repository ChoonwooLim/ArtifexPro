"""
Windows 듀얼 GPU 클라이언트
프론트엔드에서 Ray 클러스터 사용
"""

import ray
import asyncio
from typing import Optional
import base64
from PIL import Image
import io

class DualGPUClient:
    def __init__(self):
        # Ray 클러스터 연결
        try:
            ray.init(address='ray://192.168.219.150:10001')
            self.connected = True
            print("✅ Connected to Ray Cluster")
            self._check_resources()
        except Exception as e:
            print(f"❌ Failed to connect: {e}")
            self.connected = False
    
    def _check_resources(self):
        """클러스터 리소스 확인"""
        resources = ray.cluster_resources()
        print(f"\n📊 Cluster Resources:")
        print(f"  Total GPUs: {resources.get('GPU', 0)}")
        print(f"  Total CPUs: {resources.get('CPU', 0)}")
        print(f"  Total Memory: {resources.get('memory', 0) / 1e9:.1f} GB")
        
        nodes = ray.nodes()
        print(f"\n🖥️ Nodes ({len(nodes)}):")
        for i, node in enumerate(nodes):
            print(f"  Node {i+1}: {node['NodeManagerHostname']}")
            print(f"    - GPUs: {node['Resources'].get('GPU', 0)}")
            print(f"    - Status: {'Active' if node['Alive'] else 'Inactive'}")
    
    async def generate_ti2v(self, image_path: str, prompt: str, duration: float = 5.0):
        """TI2V 생성 (듀얼 GPU 사용)"""
        if not self.connected:
            return {"error": "Not connected to cluster"}
        
        print(f"\n🎬 Generating TI2V with dual GPUs...")
        print(f"  Prompt: {prompt}")
        print(f"  Duration: {duration}s")
        
        # 이미지 로드 및 인코딩
        with open(image_path, 'rb') as f:
            image_data = base64.b64encode(f.read()).decode()
        
        # Ray 원격 함수 호출
        @ray.remote(num_gpus=2.0)  # 두 GPU 모두 사용
        def distributed_ti2v(img_data, text, dur):
            # 실제 모델 실행 (Pop!_OS와 Windows GPU 협업)
            import time
            time.sleep(2)  # 시뮬레이션
            return {
                "status": "success",
                "video": f"ti2v_output_{int(time.time())}.mp4",
                "used_gpus": 2
            }
        
        # 비동기 실행
        result_ref = distributed_ti2v.remote(image_data, prompt, duration)
        result = await asyncio.get_event_loop().run_in_executor(None, ray.get, result_ref)
        
        print(f"✅ Generated using {result['used_gpus']} GPUs")
        return result
    
    async def generate_s2v(self, audio_path: str, style: str = "cinematic"):
        """S2V 생성 (듀얼 GPU 사용)"""
        if not self.connected:
            return {"error": "Not connected to cluster"}
        
        print(f"\n🎵 Generating S2V with dual GPUs...")
        print(f"  Style: {style}")
        
        # 오디오 로드
        with open(audio_path, 'rb') as f:
            audio_data = base64.b64encode(f.read()).decode()
        
        @ray.remote(num_gpus=2.0)
        def distributed_s2v(aud_data, st):
            import time
            time.sleep(3)
            return {
                "status": "success",
                "video": f"s2v_output_{int(time.time())}.mp4",
                "used_gpus": 2
            }
        
        result_ref = distributed_s2v.remote(audio_data, style)
        result = await asyncio.get_event_loop().run_in_executor(None, ray.get, result_ref)
        
        print(f"✅ Generated using {result['used_gpus']} GPUs")
        return result
    
    def monitor_gpus(self):
        """GPU 사용량 모니터링"""
        @ray.remote(num_gpus=0)
        def get_gpu_stats():
            import subprocess
            result = subprocess.run(['nvidia-smi', '--query-gpu=name,memory.used,memory.total,utilization.gpu', 
                                   '--format=csv,noheader'], capture_output=True, text=True)
            return result.stdout
        
        # 각 노드에서 GPU 정보 수집
        stats = ray.get([get_gpu_stats.remote() for _ in range(2)])
        
        print("\n📊 GPU Status:")
        for i, stat in enumerate(stats):
            if stat:
                print(f"  Node {i+1}: {stat.strip()}")
    
    def shutdown(self):
        """Ray 연결 종료"""
        if self.connected:
            ray.shutdown()
            print("👋 Disconnected from Ray cluster")

# 테스트
async def test_dual_gpu():
    client = DualGPUClient()
    
    if client.connected:
        # 모니터링
        client.monitor_gpus()
        
        # TI2V 테스트 (실제 파일 경로 필요)
        # result = await client.generate_ti2v("test.jpg", "A beautiful sunset", 5.0)
        # print(result)
    
    client.shutdown()

if __name__ == "__main__":
    asyncio.run(test_dual_gpu())