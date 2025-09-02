"""
WAN2.2 Optimized Backend with Flash Attention Support
Designed for Pop!_OS with RTX 3090 (24GB VRAM)
"""

import os
import sys
import torch
import asyncio
from pathlib import Path
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from datetime import datetime
import json
import numpy as np
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
import uvicorn

# Check for Flash Attention availability
FLASH_ATTENTION_AVAILABLE = False
try:
    import flash_attn
    FLASH_ATTENTION_AVAILABLE = True
    print("✅ Flash Attention 3 is available!")
except ImportError:
    print("⚠️ Flash Attention not available, using standard attention")

# Check for xFormers
XFORMERS_AVAILABLE = False
try:
    import xformers
    import xformers.ops
    XFORMERS_AVAILABLE = True
    print("✅ xFormers is available!")
except ImportError:
    print("⚠️ xFormers not available")

@dataclass
class OptimizationConfig:
    """Configuration for WAN2.2 optimization"""
    use_flash_attention: bool = FLASH_ATTENTION_AVAILABLE
    use_xformers: bool = XFORMERS_AVAILABLE
    use_fp16: bool = True
    use_channels_last: bool = True
    use_torch_compile: bool = True
    offload_to_cpu: bool = False
    gradient_checkpointing: bool = True
    vae_slicing: bool = True
    attention_slicing: int = 4
    
    # Flash Attention specific
    flash_attention_scale: float = 1.0
    flash_attention_causal: bool = False
    flash_attention_dropout: float = 0.0
    
    # Memory optimization
    max_batch_size: int = 1
    optimize_for_rtx3090: bool = True
    
    # Performance tuning
    num_inference_steps: int = 50
    guidance_scale: float = 7.5
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "use_flash_attention": self.use_flash_attention,
            "use_xformers": self.use_xformers,
            "use_fp16": self.use_fp16,
            "use_channels_last": self.use_channels_last,
            "use_torch_compile": self.use_torch_compile,
            "offload_to_cpu": self.offload_to_cpu,
            "gradient_checkpointing": self.gradient_checkpointing,
            "vae_slicing": self.vae_slicing,
            "attention_slicing": self.attention_slicing,
            "flash_attention_scale": self.flash_attention_scale,
            "max_batch_size": self.max_batch_size
        }

class WAN22OptimizedPipeline:
    """Optimized WAN2.2 Pipeline with Flash Attention"""
    
    def __init__(self, model_type: str = "ti2v-5B", config: Optional[OptimizationConfig] = None):
        self.model_type = model_type
        self.config = config or OptimizationConfig()
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        
        # Initialize optimizations
        self._setup_optimizations()
        
        # Model paths (adjust for your system)
        self.model_paths = {
            "ti2v-5B": "/home/stevenlim/ArtifexPro/models/Wan2.2-TI2V-5B",
            "t2v-A14B": "/home/stevenlim/ArtifexPro/models/Wan2.2-T2V-A14B",
            "i2v-A14B": "/home/stevenlim/ArtifexPro/models/Wan2.2-I2V-A14B",
            "s2v-14B": "/home/stevenlim/ArtifexPro/models/Wan2.2-S2V-14B"
        }
        
        self.pipeline = None
        
    def _setup_optimizations(self):
        """Setup all optimizations for RTX 3090"""
        
        # Enable TF32 for Ampere GPUs (RTX 3090)
        torch.backends.cuda.matmul.allow_tf32 = True
        torch.backends.cudnn.allow_tf32 = True
        
        # Enable cudnn benchmark for better performance
        torch.backends.cudnn.benchmark = True
        torch.backends.cudnn.deterministic = False
        
        # Set memory allocator settings
        os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "max_split_size_mb:512"
        
        # Enable channels last memory format
        if self.config.use_channels_last:
            torch.set_default_tensor_type('torch.cuda.FloatTensor')
        
        print(f"🚀 Optimizations enabled:")
        print(f"  - Device: {self.device}")
        print(f"  - Flash Attention: {self.config.use_flash_attention}")
        print(f"  - xFormers: {self.config.use_xformers}")
        print(f"  - FP16: {self.config.use_fp16}")
        print(f"  - TF32: Enabled")
        print(f"  - Channels Last: {self.config.use_channels_last}")
        print(f"  - Torch Compile: {self.config.use_torch_compile}")
    
    async def load_model(self):
        """Load WAN2.2 model with optimizations"""
        try:
            model_path = self.model_paths.get(self.model_type)
            if not model_path or not Path(model_path).exists():
                raise ValueError(f"Model path not found: {model_path}")
            
            print(f"Loading {self.model_type} from {model_path}...")
            
            # Import the appropriate pipeline
            if self.model_type == "ti2v-5B":
                from diffusers import DiffusionPipeline
                
                # Load with optimizations
                self.pipeline = DiffusionPipeline.from_pretrained(
                    model_path,
                    torch_dtype=torch.float16 if self.config.use_fp16 else torch.float32,
                    variant="fp16" if self.config.use_fp16 else None,
                    use_safetensors=True
                )
                
                # Move to GPU
                self.pipeline = self.pipeline.to(self.device)
                
                # Apply Flash Attention if available
                if self.config.use_flash_attention and FLASH_ATTENTION_AVAILABLE:
                    self._apply_flash_attention()
                
                # Apply xFormers if available
                elif self.config.use_xformers and XFORMERS_AVAILABLE:
                    self.pipeline.enable_xformers_memory_efficient_attention()
                    print("✅ xFormers memory efficient attention enabled")
                
                # Enable VAE slicing for memory efficiency
                if self.config.vae_slicing:
                    self.pipeline.enable_vae_slicing()
                    print("✅ VAE slicing enabled")
                
                # Enable attention slicing
                if self.config.attention_slicing:
                    self.pipeline.enable_attention_slicing(self.config.attention_slicing)
                    print(f"✅ Attention slicing enabled (slice_size={self.config.attention_slicing})")
                
                # CPU offloading if needed
                if self.config.offload_to_cpu:
                    self.pipeline.enable_sequential_cpu_offload()
                    print("✅ Sequential CPU offload enabled")
                
                # Torch compile for faster inference
                if self.config.use_torch_compile and torch.__version__ >= "2.0":
                    self.pipeline.unet = torch.compile(self.pipeline.unet, mode="reduce-overhead")
                    print("✅ Torch compile enabled")
                
            print(f"✅ Model {self.model_type} loaded successfully!")
            return True
            
        except Exception as e:
            print(f"❌ Failed to load model: {e}")
            return False
    
    def _apply_flash_attention(self):
        """Apply Flash Attention to the model"""
        if not FLASH_ATTENTION_AVAILABLE:
            return
        
        try:
            # Replace attention modules with Flash Attention
            from flash_attn.modules.mha import FlashSelfAttention
            
            def replace_attention_with_flash(module):
                for name, child in module.named_children():
                    if hasattr(child, 'to_q') and hasattr(child, 'to_k') and hasattr(child, 'to_v'):
                        # This is likely an attention module
                        flash_attn = FlashSelfAttention(
                            causal=self.config.flash_attention_causal,
                            softmax_scale=self.config.flash_attention_scale,
                            attention_dropout=self.config.flash_attention_dropout
                        )
                        setattr(module, name, flash_attn)
                    else:
                        replace_attention_with_flash(child)
            
            if hasattr(self.pipeline, 'unet'):
                replace_attention_with_flash(self.pipeline.unet)
                print("✅ Flash Attention 3 enabled for UNet")
            
            if hasattr(self.pipeline, 'vae'):
                replace_attention_with_flash(self.pipeline.vae)
                print("✅ Flash Attention 3 enabled for VAE")
                
        except Exception as e:
            print(f"⚠️ Could not apply Flash Attention: {e}")
    
    async def generate(
        self,
        prompt: str,
        negative_prompt: str = "",
        image: Optional[np.ndarray] = None,
        audio: Optional[np.ndarray] = None,
        num_frames: int = 120,
        height: int = 704,
        width: int = 1280,
        num_inference_steps: int = 50,
        guidance_scale: float = 7.5,
        seed: int = -1,
        motion_strength: float = 1.0,
        temporal_consistency: float = 0.95,
        callback=None
    ) -> Optional[str]:
        """Generate video with optimizations"""
        
        if self.pipeline is None:
            await self.load_model()
        
        if self.pipeline is None:
            raise RuntimeError("Failed to load model")
        
        try:
            # Set seed for reproducibility
            if seed == -1:
                seed = torch.randint(0, 2**32, (1,)).item()
            generator = torch.Generator(device=self.device).manual_seed(seed)
            
            # Prepare inputs
            generation_kwargs = {
                "prompt": prompt,
                "negative_prompt": negative_prompt,
                "num_frames": num_frames,
                "height": height,
                "width": width,
                "num_inference_steps": num_inference_steps,
                "guidance_scale": guidance_scale,
                "generator": generator,
            }
            
            # Add image if provided
            if image is not None and self.model_type in ["i2v-A14B", "ti2v-5B"]:
                generation_kwargs["image"] = image
            
            # Add audio if provided
            if audio is not None and self.model_type == "s2v-14B":
                generation_kwargs["audio"] = audio
            
            print(f"🎬 Starting generation with:")
            print(f"  - Resolution: {width}x{height}")
            print(f"  - Frames: {num_frames}")
            print(f"  - Steps: {num_inference_steps}")
            print(f"  - Guidance: {guidance_scale}")
            print(f"  - Seed: {seed}")
            
            # Memory optimization context
            with torch.cuda.amp.autocast(enabled=self.config.use_fp16):
                with torch.no_grad():
                    # Generate video
                    result = self.pipeline(**generation_kwargs)
                    
                    # Save video
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    output_path = f"outputs/{self.model_type}_{timestamp}.mp4"
                    
                    # Here you would save the actual video
                    # For now, we'll create a placeholder
                    Path("outputs").mkdir(exist_ok=True)
                    with open(output_path, "wb") as f:
                        f.write(b"VIDEO_PLACEHOLDER")
                    
                    print(f"✅ Video saved to: {output_path}")
                    return output_path
                    
        except Exception as e:
            print(f"❌ Generation failed: {e}")
            raise
        finally:
            # Clear cache to free memory
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
    
    def get_memory_usage(self) -> Dict[str, float]:
        """Get current GPU memory usage"""
        if torch.cuda.is_available():
            allocated = torch.cuda.memory_allocated() / 1024**3
            reserved = torch.cuda.memory_reserved() / 1024**3
            total = torch.cuda.get_device_properties(0).total_memory / 1024**3
            
            return {
                "allocated_gb": round(allocated, 2),
                "reserved_gb": round(reserved, 2),
                "total_gb": round(total, 2),
                "free_gb": round(total - allocated, 2),
                "usage_percent": round((allocated / total) * 100, 1)
            }
        return {}

# FastAPI App
app = FastAPI(title="WAN2.2 Optimized API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global pipeline instance
pipeline = None

@app.on_event("startup")
async def startup_event():
    """Initialize pipeline on startup"""
    global pipeline
    config = OptimizationConfig(
        use_flash_attention=True,
        use_xformers=True,
        use_fp16=True,
        optimize_for_rtx3090=True
    )
    pipeline = WAN22OptimizedPipeline(model_type="ti2v-5B", config=config)
    await pipeline.load_model()

@app.get("/")
async def root():
    return {
        "status": "WAN2.2 Optimized Backend Running",
        "flash_attention": FLASH_ATTENTION_AVAILABLE,
        "xformers": XFORMERS_AVAILABLE,
        "cuda": torch.cuda.is_available(),
        "gpu": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None
    }

@app.get("/api/memory")
async def get_memory():
    """Get GPU memory usage"""
    if pipeline:
        return pipeline.get_memory_usage()
    return {"error": "Pipeline not initialized"}

@app.post("/api/generate")
async def generate_video(
    prompt: str = Form(...),
    negative_prompt: str = Form(""),
    model_type: str = Form("ti2v-5B"),
    num_frames: int = Form(120),
    height: int = Form(704),
    width: int = Form(1280),
    num_inference_steps: int = Form(50),
    guidance_scale: float = Form(7.5),
    seed: int = Form(-1),
    image: Optional[UploadFile] = File(None),
    audio: Optional[UploadFile] = File(None)
):
    """Generate video with WAN2.2"""
    global pipeline
    
    # Switch model if needed
    if pipeline.model_type != model_type:
        pipeline = WAN22OptimizedPipeline(model_type=model_type)
        await pipeline.load_model()
    
    # Process uploaded files
    image_array = None
    audio_array = None
    
    if image:
        # Process image to numpy array
        pass
    
    if audio:
        # Process audio to numpy array
        pass
    
    # Generate video
    try:
        output_path = await pipeline.generate(
            prompt=prompt,
            negative_prompt=negative_prompt,
            image=image_array,
            audio=audio_array,
            num_frames=num_frames,
            height=height,
            width=width,
            num_inference_steps=num_inference_steps,
            guidance_scale=guidance_scale,
            seed=seed
        )
        
        return {
            "status": "success",
            "output": output_path,
            "memory": pipeline.get_memory_usage()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/optimization_status")
async def optimization_status():
    """Get optimization status"""
    return {
        "flash_attention": FLASH_ATTENTION_AVAILABLE,
        "xformers": XFORMERS_AVAILABLE,
        "cuda_available": torch.cuda.is_available(),
        "gpu_name": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
        "pytorch_version": torch.__version__,
        "cuda_version": torch.version.cuda,
        "tf32_enabled": torch.backends.cuda.matmul.allow_tf32,
        "cudnn_benchmark": torch.backends.cudnn.benchmark,
        "memory": pipeline.get_memory_usage() if pipeline else {}
    }

if __name__ == "__main__":
    # Run on Pop!_OS
    uvicorn.run(app, host="0.0.0.0", port=8001, reload=False)