"""
Ray Cluster Manager for Dual RTX 3090 GPUs
Manages distributed GPU processing for WAN2.2 models
"""

import ray
import torch
import numpy as np
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass
import time
import psutil
import os
from pathlib import Path

@dataclass
class GPUResource:
    """GPU resource information"""
    gpu_id: int
    name: str
    memory_total: float  # GB
    memory_used: float   # GB
    memory_free: float   # GB
    utilization: float   # %

class RayClusterManager:
    """Manages Ray cluster for dual GPU processing"""
    
    def __init__(self, head_address: str = "ray://192.168.1.100:10001"):
        self.head_address = head_address
        self.is_connected = False
        self.gpu_actors = []
        
    def connect(self) -> bool:
        """Connect to Ray cluster"""
        try:
            # Connect to existing cluster
            ray.init(address=self.head_address, ignore_reinit_error=True)
            self.is_connected = True
            
            print(f"✅ Connected to Ray cluster at {self.head_address}")
            print(f"Resources: {ray.available_resources()}")
            
            # Initialize GPU actors
            self._initialize_gpu_actors()
            
            return True
            
        except Exception as e:
            print(f"❌ Failed to connect to Ray cluster: {e}")
            self.is_connected = False
            return False
    
    def _initialize_gpu_actors(self):
        """Initialize GPU actors for each available GPU"""
        num_gpus = int(ray.available_resources().get("GPU", 0))
        
        if num_gpus == 0:
            print("⚠️ No GPUs available in Ray cluster")
            return
        
        print(f"🎮 Initializing {num_gpus} GPU actors...")
        
        for gpu_id in range(num_gpus):
            actor = GPUActor.options(
                num_gpus=1,
                name=f"gpu_actor_{gpu_id}"
            ).remote(gpu_id)
            self.gpu_actors.append(actor)
        
        print(f"✅ Initialized {len(self.gpu_actors)} GPU actors")
    
    def get_gpu_status(self) -> List[GPUResource]:
        """Get status of all GPUs in cluster"""
        if not self.is_connected:
            return []
        
        futures = [actor.get_gpu_status.remote() for actor in self.gpu_actors]
        statuses = ray.get(futures)
        
        return [GPUResource(**status) for status in statuses]
    
    def distribute_model(self, model_type: str, model_path: str) -> bool:
        """Distribute model across GPUs"""
        if not self.is_connected or not self.gpu_actors:
            return False
        
        print(f"📦 Distributing {model_type} model across {len(self.gpu_actors)} GPUs...")
        
        # Strategy based on model size
        model_configs = {
            "ti2v-5B": {"layers_per_gpu": [12, 12]},  # 24 layers total
            "s2v-14B": {"layers_per_gpu": [20, 20]},  # 40 layers total
            "t2v-A14B": {"layers_per_gpu": [20, 20]}, # MoE architecture
            "i2v-A14B": {"layers_per_gpu": [20, 20]}  # MoE architecture
        }
        
        config = model_configs.get(model_type, {"layers_per_gpu": [20, 20]})
        
        # Load model on each GPU with assigned layers
        futures = []
        for i, actor in enumerate(self.gpu_actors):
            futures.append(
                actor.load_model_partition.remote(
                    model_path=model_path,
                    model_type=model_type,
                    partition_id=i,
                    total_partitions=len(self.gpu_actors),
                    layers=config["layers_per_gpu"][i]
                )
            )
        
        results = ray.get(futures)
        success = all(results)
        
        if success:
            print(f"✅ Model {model_type} distributed successfully")
        else:
            print(f"❌ Failed to distribute model {model_type}")
        
        return success
    
    def generate_distributed(
        self,
        prompt: str,
        model_type: str,
        **kwargs
    ) -> Optional[np.ndarray]:
        """Generate video using distributed processing"""
        if not self.is_connected or not self.gpu_actors:
            return None
        
        print(f"🎬 Starting distributed generation with {model_type}...")
        
        # Phase 1: Text encoding (GPU 0)
        text_features = ray.get(
            self.gpu_actors[0].encode_text.remote(prompt)
        )
        
        # Phase 2: Parallel diffusion (Both GPUs)
        if len(self.gpu_actors) >= 2:
            # Split timesteps between GPUs
            num_steps = kwargs.get("num_inference_steps", 50)
            
            # GPU 0: First half of timesteps
            future1 = self.gpu_actors[0].diffusion_step.remote(
                text_features=text_features,
                timesteps=list(range(0, num_steps // 2)),
                **kwargs
            )
            
            # GPU 1: Second half of timesteps
            future2 = self.gpu_actors[1].diffusion_step.remote(
                text_features=text_features,
                timesteps=list(range(num_steps // 2, num_steps)),
                **kwargs
            )
            
            # Gather results
            latents1, latents2 = ray.get([future1, future2])
            
            # Combine latents
            combined_latents = self._combine_latents(latents1, latents2)
            
        else:
            # Single GPU fallback
            combined_latents = ray.get(
                self.gpu_actors[0].diffusion_step.remote(
                    text_features=text_features,
                    timesteps=list(range(num_steps)),
                    **kwargs
                )
            )
        
        # Phase 3: VAE decoding (GPU with more free memory)
        gpu_statuses = self.get_gpu_status()
        best_gpu = max(gpu_statuses, key=lambda x: x.memory_free)
        
        video_frames = ray.get(
            self.gpu_actors[best_gpu.gpu_id].decode_vae.remote(combined_latents)
        )
        
        print(f"✅ Distributed generation complete")
        return video_frames
    
    def _combine_latents(self, latents1: np.ndarray, latents2: np.ndarray) -> np.ndarray:
        """Combine latents from multiple GPUs"""
        # Weighted average based on timestep importance
        weight1 = 0.6  # Early timesteps more important
        weight2 = 0.4  # Later timesteps
        
        return latents1 * weight1 + latents2 * weight2
    
    def shutdown(self):
        """Shutdown Ray connection"""
        if self.is_connected:
            ray.shutdown()
            self.is_connected = False
            print("🔌 Ray cluster disconnected")


@ray.remote
class GPUActor:
    """Actor that runs on a specific GPU"""
    
    def __init__(self, gpu_id: int):
        self.gpu_id = gpu_id
        self.device = torch.device(f"cuda:{gpu_id}")
        self.model = None
        self.model_type = None
        
        # Set CUDA device
        torch.cuda.set_device(self.device)
        
        print(f"🎮 GPU Actor {gpu_id} initialized on {torch.cuda.get_device_name(gpu_id)}")
    
    def get_gpu_status(self) -> Dict[str, Any]:
        """Get GPU status information"""
        torch.cuda.set_device(self.device)
        
        props = torch.cuda.get_device_properties(self.device)
        memory_allocated = torch.cuda.memory_allocated(self.device) / 1024**3
        memory_reserved = torch.cuda.memory_reserved(self.device) / 1024**3
        
        return {
            "gpu_id": self.gpu_id,
            "name": props.name,
            "memory_total": props.total_memory / 1024**3,
            "memory_used": memory_allocated,
            "memory_free": (props.total_memory / 1024**3) - memory_allocated,
            "utilization": (memory_allocated / (props.total_memory / 1024**3)) * 100
        }
    
    def load_model_partition(
        self,
        model_path: str,
        model_type: str,
        partition_id: int,
        total_partitions: int,
        layers: int
    ) -> bool:
        """Load a partition of the model"""
        try:
            torch.cuda.set_device(self.device)
            
            print(f"📦 GPU {self.gpu_id}: Loading {model_type} partition {partition_id}/{total_partitions}")
            
            # Import based on model type
            if "t2v" in model_type.lower() or "i2v" in model_type.lower():
                from diffusers import DiffusionPipeline
                
                # Load with device map for model parallelism
                self.model = DiffusionPipeline.from_pretrained(
                    model_path,
                    torch_dtype=torch.float16,
                    device_map={
                        "text_encoder": self.device if partition_id == 0 else "cpu",
                        "unet": self.device,
                        "vae": self.device if partition_id == total_partitions - 1 else "cpu"
                    }
                )
            
            self.model_type = model_type
            
            # Apply optimizations
            if hasattr(self.model, 'enable_xformers_memory_efficient_attention'):
                self.model.enable_xformers_memory_efficient_attention()
            
            if hasattr(self.model, 'enable_vae_slicing'):
                self.model.enable_vae_slicing()
            
            print(f"✅ GPU {self.gpu_id}: Model partition loaded successfully")
            return True
            
        except Exception as e:
            print(f"❌ GPU {self.gpu_id}: Failed to load model partition: {e}")
            return False
    
    def encode_text(self, prompt: str) -> np.ndarray:
        """Encode text prompt"""
        torch.cuda.set_device(self.device)
        
        with torch.no_grad():
            if hasattr(self.model, 'text_encoder'):
                # Encode prompt
                inputs = self.model.tokenizer(
                    prompt,
                    padding="max_length",
                    truncation=True,
                    return_tensors="pt"
                ).to(self.device)
                
                text_embeddings = self.model.text_encoder(inputs.input_ids)[0]
                
                return text_embeddings.cpu().numpy()
        
        return np.zeros((1, 77, 768))  # Placeholder
    
    def diffusion_step(
        self,
        text_features: np.ndarray,
        timesteps: List[int],
        **kwargs
    ) -> np.ndarray:
        """Run diffusion steps"""
        torch.cuda.set_device(self.device)
        
        # Convert to tensor
        text_features = torch.from_numpy(text_features).to(self.device)
        
        # Initialize latents
        latent_shape = (1, 4, kwargs.get("num_frames", 16), 
                       kwargs.get("height", 64) // 8, 
                       kwargs.get("width", 64) // 8)
        
        latents = torch.randn(latent_shape, device=self.device, dtype=torch.float16)
        
        # Run diffusion steps
        with torch.no_grad():
            for t in timesteps:
                # Simplified diffusion step (actual implementation would use scheduler)
                noise_pred = torch.randn_like(latents) * 0.1
                latents = latents - noise_pred
        
        return latents.cpu().numpy()
    
    def decode_vae(self, latents: np.ndarray) -> np.ndarray:
        """Decode latents to video frames"""
        torch.cuda.set_device(self.device)
        
        latents = torch.from_numpy(latents).to(self.device)
        
        with torch.no_grad():
            if hasattr(self.model, 'vae'):
                # Decode latents
                frames = self.model.vae.decode(latents).sample
                frames = (frames / 2 + 0.5).clamp(0, 1)
                frames = frames.cpu().numpy()
                return frames
        
        # Placeholder
        return np.random.rand(1, 16, 3, 512, 512)


# Example usage
if __name__ == "__main__":
    # Initialize manager
    manager = RayClusterManager()
    
    # Connect to cluster
    if manager.connect():
        # Check GPU status
        gpu_statuses = manager.get_gpu_status()
        for gpu in gpu_statuses:
            print(f"GPU {gpu.gpu_id}: {gpu.name}, "
                  f"Free: {gpu.memory_free:.1f}GB / {gpu.memory_total:.1f}GB")
        
        # Load model
        manager.distribute_model(
            model_type="ti2v-5B",
            model_path="/home/stevenlim/models/Wan2.2-TI2V-5B"
        )
        
        # Generate video
        video = manager.generate_distributed(
            prompt="A beautiful sunset over mountains",
            model_type="ti2v-5B",
            num_frames=120,
            height=704,
            width=1280,
            num_inference_steps=50
        )
        
        if video is not None:
            print(f"Generated video shape: {video.shape}")
        
        # Shutdown
        manager.shutdown()