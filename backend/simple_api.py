"""
간단한 로컬 API 서버 (Windows에서 실행)
실제 모델 없이 시뮬레이션으로 작동
"""

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import uvicorn
from typing import Optional
import asyncio
import uuid
import os
import json
from datetime import datetime
import random
from pathlib import Path
import base64
import shutil

app = FastAPI(title="ArtifexPro API")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 작업 저장소
jobs = {}
UPLOAD_DIR = Path("uploads")
OUTPUT_DIR = Path("outputs")
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

@app.get("/")
async def root():
    return {"status": "ArtifexPro Backend Running", "version": "1.0.0"}

@app.post("/api/ti2v/generate")
async def generate_ti2v(
    image: UploadFile = File(...),
    prompt: str = Form(...),
    duration: float = Form(5.0),
    quality: str = Form("balanced")
):
    """Text+Image to Video 생성"""
    job_id = str(uuid.uuid4())
    
    # 이미지 저장
    image_path = UPLOAD_DIR / f"{job_id}_{image.filename}"
    with open(image_path, "wb") as f:
        shutil.copyfileobj(image.file, f)
    
    # 작업 시작
    jobs[job_id] = {
        "id": job_id,
        "type": "ti2v",
        "status": "processing",
        "progress": 0,
        "prompt": prompt,
        "duration": duration,
        "quality": quality,
        "created_at": datetime.now().isoformat()
    }
    
    # 비동기로 처리
    asyncio.create_task(simulate_ti2v_generation(job_id, image_path, prompt, duration))
    
    return {"job_id": job_id, "status": "started"}

@app.post("/api/s2v/generate")
async def generate_s2v(
    audio: UploadFile = File(...),
    style: str = Form("cinematic"),
    duration: Optional[float] = Form(None)
):
    """Sound to Video 생성"""
    job_id = str(uuid.uuid4())
    
    # 오디오 저장
    audio_path = UPLOAD_DIR / f"{job_id}_{audio.filename}"
    with open(audio_path, "wb") as f:
        shutil.copyfileobj(audio.file, f)
    
    jobs[job_id] = {
        "id": job_id,
        "type": "s2v",
        "status": "processing",
        "progress": 0,
        "style": style,
        "duration": duration or 10.0,
        "created_at": datetime.now().isoformat()
    }
    
    asyncio.create_task(simulate_s2v_generation(job_id, audio_path, style))
    
    return {"job_id": job_id, "status": "started"}

@app.get("/api/job/{job_id}")
async def get_job_status(job_id: str):
    """작업 상태 조회"""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return jobs[job_id]

@app.get("/api/jobs")
async def list_jobs():
    """모든 작업 목록"""
    return list(jobs.values())

async def simulate_ti2v_generation(job_id: str, image_path: Path, prompt: str, duration: float):
    """TI2V 생성 시뮬레이션"""
    try:
        # 진행률 업데이트
        for progress in range(0, 101, 10):
            await asyncio.sleep(1)  # 시뮬레이션 딜레이
            jobs[job_id]["progress"] = progress
            jobs[job_id]["message"] = f"Processing: {progress}% - {get_progress_message(progress)}"
        
        # 가짜 비디오 생성 (실제로는 샘플 비디오 복사)
        output_path = OUTPUT_DIR / f"{job_id}_output.mp4"
        
        # 샘플 비디오 생성 (빈 파일)
        with open(output_path, "wb") as f:
            f.write(b"FAKE_VIDEO_DATA")  # 실제로는 ffmpeg로 생성
        
        # 썸네일 생성
        thumbnail_path = OUTPUT_DIR / f"{job_id}_thumb.jpg"
        shutil.copy(image_path, thumbnail_path)
        
        jobs[job_id].update({
            "status": "completed",
            "progress": 100,
            "output": {
                "video_url": f"/outputs/{job_id}_output.mp4",
                "thumbnail_url": f"/outputs/{job_id}_thumb.jpg",
                "duration": duration,
                "resolution": "1280x720",
                "fps": 30,
                "size_mb": random.randint(10, 50)
            },
            "completed_at": datetime.now().isoformat()
        })
        
    except Exception as e:
        jobs[job_id].update({
            "status": "failed",
            "error": str(e),
            "completed_at": datetime.now().isoformat()
        })

async def simulate_s2v_generation(job_id: str, audio_path: Path, style: str):
    """S2V 생성 시뮬레이션"""
    try:
        for progress in range(0, 101, 5):
            await asyncio.sleep(0.5)
            jobs[job_id]["progress"] = progress
            jobs[job_id]["message"] = f"Generating video from audio: {progress}%"
        
        output_path = OUTPUT_DIR / f"{job_id}_output.mp4"
        with open(output_path, "wb") as f:
            f.write(b"FAKE_S2V_VIDEO")
        
        jobs[job_id].update({
            "status": "completed",
            "progress": 100,
            "output": {
                "video_url": f"/outputs/{job_id}_output.mp4",
                "duration": jobs[job_id]["duration"],
                "style": style
            },
            "completed_at": datetime.now().isoformat()
        })
        
    except Exception as e:
        jobs[job_id].update({
            "status": "failed",
            "error": str(e)
        })

def get_progress_message(progress: int) -> str:
    """진행 상황 메시지"""
    messages = {
        0: "Initializing model...",
        10: "Loading image and prompt...",
        20: "Encoding image features...",
        30: "Processing text prompt...",
        40: "Generating initial frames...",
        50: "Applying motion dynamics...",
        60: "Enhancing temporal coherence...",
        70: "Refining video quality...",
        80: "Post-processing frames...",
        90: "Finalizing output...",
        100: "Complete!"
    }
    return messages.get(progress, f"Processing... {progress}%")

# Static files 서빙
app.mount("/outputs", StaticFiles(directory="outputs"), name="outputs")
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.post("/api/upload")
async def upload_file(file: UploadFile = File(...)):
    """파일 업로드"""
    file_id = str(uuid.uuid4())
    file_path = UPLOAD_DIR / f"{file_id}_{file.filename}"
    
    with open(file_path, "wb") as f:
        shutil.copyfileobj(file.file, f)
    
    return {
        "file_id": file_id,
        "filename": file.filename,
        "size": file_path.stat().st_size,
        "url": f"/uploads/{file_id}_{file.filename}"
    }

@app.get("/api/models")
async def get_available_models():
    """사용 가능한 모델 목록"""
    return {
        "ti2v": {
            "name": "Wan2.2-TI2V-5B",
            "status": "ready",
            "vram_required": "16GB",
            "capabilities": ["720p", "1080p", "5-30s"]
        },
        "s2v": {
            "name": "Wan2.2-S2V-14B",
            "status": "ready",
            "vram_required": "20GB",
            "capabilities": ["music-sync", "style-transfer"]
        }
    }

@app.get("/api/system/status")
async def system_status():
    """시스템 상태"""
    return {
        "gpu": {
            "name": "RTX 3090",
            "vram_total": "24GB",
            "vram_used": f"{random.randint(8, 20)}GB",
            "temperature": f"{random.randint(50, 75)}°C"
        },
        "jobs": {
            "active": len([j for j in jobs.values() if j["status"] == "processing"]),
            "completed": len([j for j in jobs.values() if j["status"] == "completed"]),
            "failed": len([j for j in jobs.values() if j["status"] == "failed"])
        }
    }

if __name__ == "__main__":
    print("\n" + "="*50)
    print("ArtifexPro API Server Starting...")
    print("="*50)
    print(f"Upload Dir: {UPLOAD_DIR.absolute()}")
    print(f"Output Dir: {OUTPUT_DIR.absolute()}")
    print("\nAPI Endpoints:")
    print("  - http://localhost:8000")
    print("  - http://localhost:8000/docs (Swagger UI)")
    print("\nReady for video generation!")
    print("="*50 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000)