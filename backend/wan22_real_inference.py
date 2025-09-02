"""
WAN2.2 실제 모델 추론 모듈
TI2V-5B 및 S2V-14B 모델 사용
"""

import os
import torch
import numpy as np
from pathlib import Path
from typing import Optional, Union, List
from PIL import Image
import cv2
from diffusers import DiffusionPipeline, DPMSolverMultistepScheduler
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class WAN22Inference:
    """WAN2.2 실제 모델 추론 클래스"""
    
    def __init__(self, model_path: str, device: str = "cuda:0"):
        self.model_path = Path(model_path)
        self.device = device
        self.pipeline = None
        self.model_loaded = False
        
    def load_ti2v_model(self):
        """TI2V-5B 모델 로드"""
        try:
            logger.info(f"Loading TI2V-5B model from {self.model_path}")
            
            # Diffusers 파이프라인으로 로드
            self.pipeline = DiffusionPipeline.from_pretrained(
                str(self.model_path),
                torch_dtype=torch.float16,
                variant="fp16",
                use_safetensors=True
            )
            
            # 스케줄러 설정
            self.pipeline.scheduler = DPMSolverMultistepScheduler.from_config(
                self.pipeline.scheduler.config
            )
            
            # GPU로 이동
            self.pipeline = self.pipeline.to(self.device)
            
            # 메모리 최적화
            self.pipeline.enable_attention_slicing()
            self.pipeline.enable_vae_slicing()
            
            # xFormers 사용 (가능한 경우)
            try:
                self.pipeline.enable_xformers_memory_efficient_attention()
                logger.info("xFormers enabled for memory efficiency")
            except:
                logger.info("xFormers not available, using default attention")
            
            self.model_loaded = True
            logger.info("TI2V-5B model loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load TI2V-5B model: {e}")
            raise
    
    def generate_video(
        self,
        prompt: str,
        image: Optional[Union[Image.Image, np.ndarray]] = None,
        num_frames: int = 120,  # 5초 * 24fps
        height: int = 704,
        width: int = 1280,
        num_inference_steps: int = 50,
        guidance_scale: float = 7.5,
        negative_prompt: Optional[str] = None,
        seed: int = -1,
        motion_strength: float = 1.0
    ) -> np.ndarray:
        """비디오 생성"""
        
        if not self.model_loaded:
            self.load_ti2v_model()
        
        # 시드 설정
        if seed == -1:
            seed = torch.randint(0, 2**32, (1,)).item()
        generator = torch.Generator(device=self.device).manual_seed(seed)
        
        logger.info(f"Generating video: {num_frames} frames at {width}x{height}")
        logger.info(f"Prompt: {prompt}")
        
        try:
            # 이미지가 있으면 I2V, 없으면 T2V
            if image is not None:
                logger.info("Mode: Image-to-Video")
                if isinstance(image, np.ndarray):
                    image = Image.fromarray(image)
                
                # I2V 생성
                video_frames = self.pipeline(
                    prompt=prompt,
                    image=image,
                    num_frames=num_frames,
                    height=height,
                    width=width,
                    num_inference_steps=num_inference_steps,
                    guidance_scale=guidance_scale,
                    negative_prompt=negative_prompt,
                    generator=generator,
                    output_type="np"
                ).frames
            else:
                logger.info("Mode: Text-to-Video")
                
                # T2V 생성
                video_frames = self.pipeline(
                    prompt=prompt,
                    num_frames=num_frames,
                    height=height,
                    width=width,
                    num_inference_steps=num_inference_steps,
                    guidance_scale=guidance_scale,
                    negative_prompt=negative_prompt,
                    generator=generator,
                    output_type="np"
                ).frames
            
            logger.info(f"Generated {len(video_frames)} frames")
            return video_frames
            
        except Exception as e:
            logger.error(f"Video generation failed: {e}")
            raise
    
    def save_video(self, frames: np.ndarray, output_path: str, fps: int = 24):
        """비디오 파일로 저장"""
        try:
            height, width = frames[0].shape[:2]
            
            # VideoWriter 설정
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
            
            for frame in frames:
                # RGB to BGR 변환
                frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
                out.write(frame_bgr)
            
            out.release()
            logger.info(f"Video saved to {output_path}")
            
        except Exception as e:
            logger.error(f"Failed to save video: {e}")
            raise
    
    def cleanup(self):
        """메모리 정리"""
        if self.pipeline is not None:
            del self.pipeline
            self.pipeline = None
            torch.cuda.empty_cache()
            logger.info("Model unloaded and memory cleared")


# Ray를 사용한 분산 처리용 워커
import ray

@ray.remote(num_gpus=1)
class WAN22Worker:
    """Ray 분산 처리용 WAN2.2 워커"""
    
    def __init__(self, gpu_id: int, model_path: str):
        self.gpu_id = gpu_id
        self.device = f"cuda:{gpu_id}"
        self.model_path = model_path
        self.inference = WAN22Inference(model_path, self.device)
        logger.info(f"WAN22Worker initialized on GPU {gpu_id}")
    
    def generate_video_chunk(
        self,
        prompt: str,
        start_frame: int,
        end_frame: int,
        **kwargs
    ) -> np.ndarray:
        """비디오 청크 생성"""
        num_frames = end_frame - start_frame
        logger.info(f"GPU {self.gpu_id}: Generating frames {start_frame}-{end_frame}")
        
        frames = self.inference.generate_video(
            prompt=prompt,
            num_frames=num_frames,
            **kwargs
        )
        
        return frames
    
    def get_gpu_info(self):
        """GPU 정보 반환"""
        props = torch.cuda.get_device_properties(self.device)
        return {
            "gpu_id": self.gpu_id,
            "name": props.name,
            "memory_total": props.total_memory / 1024**3,
            "memory_used": torch.cuda.memory_allocated(self.device) / 1024**3,
            "memory_free": (props.total_memory - torch.cuda.memory_allocated(self.device)) / 1024**3,
            "model_loaded": self.inference.model_loaded
        }


if __name__ == "__main__":
    # 테스트
    model_path = "/home/stevenlim/ArtifexPro/models/Wan2.2-TI2V-5B"
    
    inference = WAN22Inference(model_path)
    inference.load_ti2v_model()
    
    # T2V 테스트
    frames = inference.generate_video(
        prompt="A beautiful sunset over the ocean, cinematic",
        num_frames=24,  # 1초 테스트
        height=512,
        width=512,
        num_inference_steps=25
    )
    
    inference.save_video(frames, "test_output.mp4")
    inference.cleanup()