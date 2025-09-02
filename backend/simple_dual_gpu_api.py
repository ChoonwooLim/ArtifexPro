"""
ArtifexPro Simple Dual GPU Backend (without Ray)
Simplified version for Windows local testing
"""

import os
import torch
import asyncio
from pathlib import Path
from typing import Optional, Dict, Any
from datetime import datetime
import uuid
import shutil
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import json
import uvicorn

# 디렉토리 설정
UPLOAD_DIR = Path("uploads")
OUTPUT_DIR = Path("outputs")
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

app = FastAPI(title="ArtifexPro Simple Dual GPU API")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files
app.mount("/outputs", StaticFiles(directory="outputs"), name="outputs")
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# 작업 저장소
jobs = {}

# GPU 정보
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
gpu_count = torch.cuda.device_count() if torch.cuda.is_available() else 0

@app.get("/")
async def root():
    return {
        "status": "online",
        "service": "ArtifexPro Simple Dual GPU API",
        "gpu_available": torch.cuda.is_available(),
        "gpu_count": gpu_count,
        "device": str(device)
    }

@app.get("/health")
async def health():
    gpu_info = {}
    if torch.cuda.is_available():
        for i in range(gpu_count):
            gpu_info[f"gpu_{i}"] = {
                "name": torch.cuda.get_device_name(i),
                "memory_total": f"{torch.cuda.get_device_properties(i).total_memory / 1024**3:.1f} GB",
                "memory_allocated": f"{torch.cuda.memory_allocated(i) / 1024**3:.1f} GB",
                "memory_reserved": f"{torch.cuda.memory_reserved(i) / 1024**3:.1f} GB"
            }
    
    return {
        "status": "healthy",
        "gpu_count": gpu_count,
        "gpu_info": gpu_info,
        "timestamp": datetime.now().isoformat()
    }

@app.get("/system-info")
async def system_info():
    """Get detailed system information"""
    return {
        "mode": f"GPU Mode ({gpu_count} GPU{'s' if gpu_count > 1 else ''})" if gpu_count > 0 else "CPU Mode",
        "total_vram": f"{gpu_count * 24:.1f} GB" if gpu_count > 0 else "N/A",
        "backends": [
            {"name": "windows", "status": "online", "gpu": "RTX 3090 24GB"},
        ],
        "ray_status": "disabled (simple mode)",
        "models_available": ["ti2v-5B", "s2v-14B"]
    }

@app.post("/generate/ti2v")
async def generate_ti2v(
    prompt: str = Form(...),
    duration: int = Form(5),
    resolution: str = Form("720*480"),
    fps: int = Form(24),
    image: Optional[UploadFile] = File(None)
):
    """Generate Text/Image to Video"""
    job_id = str(uuid.uuid4())
    
    # Save uploaded image if provided
    image_path = None
    if image:
        image_path = UPLOAD_DIR / f"{job_id}_{image.filename}"
        with open(image_path, "wb") as f:
            f.write(await image.read())
    
    # Create job
    job = {
        "id": job_id,
        "type": "ti2v",
        "status": "processing",
        "prompt": prompt,
        "duration": duration,
        "resolution": resolution,
        "fps": fps,
        "image": str(image_path) if image_path else None,
        "created_at": datetime.now().isoformat(),
        "progress": 0
    }
    
    jobs[job_id] = job
    
    # Simulate video generation (in real implementation, this would call the actual model)
    asyncio.create_task(simulate_video_generation(job_id))
    
    return JSONResponse(content={
        "job_id": job_id,
        "status": "processing",
        "message": "Video generation started"
    })

async def simulate_video_generation(job_id: str):
    """Simulate video generation process"""
    job = jobs[job_id]
    
    # Simulate progress updates
    for progress in [10, 30, 50, 70, 90, 100]:
        await asyncio.sleep(2)  # Simulate processing time
        job["progress"] = progress
        
        if progress == 100:
            # Create a dummy video file
            output_path = OUTPUT_DIR / f"{job_id}.mp4"
            output_path.write_text("dummy video content")  # In real implementation, this would be actual video
            
            job["status"] = "completed"
            job["output"] = {
                "video_url": f"/outputs/{job_id}.mp4",
                "file_size": "25MB",
                "duration": job["duration"],
                "resolution": job["resolution"]
            }
            job["completed_at"] = datetime.now().isoformat()

@app.get("/job/{job_id}")
async def get_job_status(job_id: str):
    """Get job status"""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return jobs[job_id]

@app.get("/jobs")
async def list_jobs():
    """List all jobs"""
    return list(jobs.values())

@app.post("/translate")
async def translate_text(text: str = Form(...)):
    """Mock translation endpoint"""
    # In production, this would use a real translation API
    return {
        "original": text,
        "translated": text,  # Mock: return same text
        "language": "en"
    }

@app.post("/generate/autoshorts")
async def generate_autoshorts(
    topic: str = Form(...),
    duration: int = Form(60)
):
    """Generate auto shorts"""
    job_id = str(uuid.uuid4())
    
    job = {
        "id": job_id,
        "type": "autoshorts",
        "status": "processing",
        "topic": topic,
        "duration": duration,
        "created_at": datetime.now().isoformat()
    }
    
    jobs[job_id] = job
    
    # Simulate generation
    asyncio.create_task(simulate_video_generation(job_id))
    
    return JSONResponse(content={
        "job_id": job_id,
        "status": "processing",
        "message": "AutoShorts generation started"
    })

if __name__ == "__main__":
    print(f"Starting ArtifexPro Simple Dual GPU API...")
    print(f"GPU Available: {torch.cuda.is_available()}")
    print(f"GPU Count: {gpu_count}")
    if gpu_count > 0:
        print(f"GPU Name: {torch.cuda.get_device_name(0)}")
    
    uvicorn.run(app, host="0.0.0.0", port=8002)