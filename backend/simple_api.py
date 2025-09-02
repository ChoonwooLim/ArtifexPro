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
        # Detailed progress stages
        stages = [
            (5, "Initializing WAN2.2 TI2V-5B model..."),
            (10, "Loading image and preprocessing..."),
            (15, "Encoding prompt with CLIP text encoder..."),
            (20, "Extracting image features with ViT..."),
            (25, "Initializing diffusion pipeline..."),
            (30, "Starting denoising process..."),
            (40, "Running diffusion steps (Step 1-20)..."),
            (50, "Running diffusion steps (Step 21-35)..."),
            (60, "Running diffusion steps (Step 36-50)..."),
            (70, "Decoding latents with VAE decoder..."),
            (80, "Applying temporal consistency..."),
            (90, "Rendering final video frames..."),
            (95, "Encoding video with H.264 codec..."),
            (100, "Finalizing output...")
        ]
        
        for progress, message in stages:
            await asyncio.sleep(1.0)  # Simulate processing time
            jobs[job_id]["progress"] = progress
            jobs[job_id]["message"] = message
        
        # Generate real sample video
        output_path = OUTPUT_DIR / f"{job_id}_output.mp4"
        
        # Import video generation module
        import sys
        sys.path.append(str(Path.cwd()))
        from create_sample_video import create_sample_video
        
        # Create video with prompt text
        prompt_short = prompt[:15] if len(prompt) > 15 else prompt
        create_sample_video(str(output_path), f"WAN2.2: {prompt_short}", int(duration), 24)
        
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
    """진행 상황 메시지 for WAN2.2"""
    messages = {
        0: "Initializing WAN2.2 pipeline...",
        10: "Loading model weights from checkpoint...",
        20: "Processing input data with CLIP...",
        30: "Running neural network inference...",
        40: "Generating video frames (1/3)...",
        50: "Generating video frames (2/3)...",
        60: "Generating video frames (3/3)...",
        70: "Applying motion dynamics...",
        80: "Enhancing temporal consistency...",
        90: "Rendering final output...",
        100: "Generation complete!"
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

@app.post("/api/translate")
async def translate_text(
    text: str = Form(...),
    target_lang: str = Form("en")
):
    """구글 번역 API를 사용한 한글→영어 번역"""
    try:
        # deep-translator 라이브러리 사용
        try:
            from deep_translator import GoogleTranslator
            
            # 한글 감지
            is_korean = any(ord(c) >= 0xAC00 and ord(c) <= 0xD7A3 for c in text)
            
            if is_korean:
                # 구글 번역 수행
                translator = GoogleTranslator(source='ko', target=target_lang)
                translated = translator.translate(text)
            else:
                # 이미 영어면 그대로 반환
                translated = text
                
        except ImportError:
            # googletrans가 설치되지 않은 경우 fallback
            print("googletrans not installed, using fallback translation")
            
            # 간단한 키워드 기반 번역 (fallback)
            translations = {
                "아름다운 일몰": "beautiful sunset",
                "미래 도시": "futuristic city", 
                "우주 비행사": "astronaut in space",
                "판타지 숲": "fantasy forest",
                "사이버펑크": "cyberpunk",
                "네온 불빛": "neon lights",
                "비 오는 거리": "rainy street",
                "눈 내리는 산": "snowy mountain",
                "해변의 파도": "ocean waves on beach",
                "벚꽃": "cherry blossoms",
                "고양이": "cat",
                "강아지": "dog",
                "로봇": "robot",
                "용": "dragon",
                "마법사": "wizard",
                "우주": "space",
                "미래": "future",
                "판타지": "fantasy",
                "아름다운": "beautiful",
                "신비로운": "mysterious",
                "환상적인": "fantastic"
            }
            
            translated = text
            for korean, english in translations.items():
                if korean in text:
                    translated = translated.replace(korean, english)
            
            # 한글이 남아있으면 기본 템플릿
            if any(ord(c) >= 0xAC00 and ord(c) <= 0xD7A3 for c in translated):
                translated = f"A cinematic scene, {text}, highly detailed, 8K quality"
        
        return {
            "original": text,
            "translated": translated,
            "language": "ko" if any(ord(c) >= 0xAC00 and ord(c) <= 0xD7A3 for c in text) else "en",
            "success": True
        }
        
    except Exception as e:
        print(f"Translation error: {e}")
        return {
            "original": text,
            "translated": text,
            "language": "unknown",
            "success": False,
            "error": str(e)
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

@app.post("/api/autoshorts/generate")
async def generate_autoshorts(
    script: str = Form(...),
    platform: str = Form("tiktok"),
    style: str = Form("engaging"),
    duration: int = Form(60)
):
    """Auto Shorts 생성 (VisionCut.AI)"""
    job_id = str(uuid.uuid4())
    
    jobs[job_id] = {
        "id": job_id,
        "type": "autoshorts",
        "status": "processing",
        "progress": 0,
        "script": script,
        "platform": platform,
        "style": style,
        "duration": duration,
        "created_at": datetime.now().isoformat()
    }
    
    asyncio.create_task(simulate_autoshorts_generation(job_id, script, platform))
    
    return {"job_id": job_id, "status": "started"}

async def simulate_autoshorts_generation(job_id: str, script: str, platform: str):
    """Auto Shorts 생성 시뮬레이션"""
    try:
        stages = [
            (10, "Analyzing script..."),
            (20, "Generating scene breakdown..."),
            (30, "Creating visual storyboard..."),
            (40, "Generating video clips..."),
            (60, "Adding transitions and effects..."),
            (80, "Applying audio and music..."),
            (90, "Final rendering..."),
            (100, "Complete!")
        ]
        
        for progress, message in stages:
            await asyncio.sleep(2)
            jobs[job_id]["progress"] = progress
            jobs[job_id]["message"] = message
        
        output_path = OUTPUT_DIR / f"{job_id}_autoshorts.mp4"
        with open(output_path, "wb") as f:
            f.write(b"FAKE_AUTOSHORTS_VIDEO")
        
        jobs[job_id].update({
            "status": "completed",
            "progress": 100,
            "output": {
                "video_url": f"/outputs/{job_id}_autoshorts.mp4",
                "duration": 60,
                "platform": platform,
                "scenes": random.randint(5, 10),
                "format": "9:16" if platform in ["tiktok", "youtube", "instagram"] else "16:9"
            },
            "completed_at": datetime.now().isoformat()
        })
        
    except Exception as e:
        jobs[job_id].update({
            "status": "failed",
            "error": str(e)
        })

# AI Chat endpoint
chat_history = []

@app.post("/api/chat")
async def ai_chat(message: str = Form(...)):
    """AI Chat for VisionCut.AI"""
    # 시뮬레이션: 간단한 응답 생성
    responses = {
        "hello": "Hello! I'm VisionCut AI. How can I help you create amazing videos today?",
        "help": "I can help you with:\n- Creating auto shorts for TikTok, YouTube, Instagram\n- Generating videos from scripts\n- Adding effects and transitions\n- Optimizing for different platforms",
        "default": f"I understand you want to know about '{message}'. Let me help you with video creation!"
    }
    
    response = responses.get(message.lower(), responses["default"])
    
    chat_entry = {
        "user": message,
        "assistant": response,
        "timestamp": datetime.now().isoformat()
    }
    chat_history.append(chat_entry)
    
    return {"response": response, "history": chat_history[-10:]}  # 최근 10개 대화만 반환

if __name__ == "__main__":
    print("\n" + "="*50)
    print("ArtifexPro API Server Starting...")
    print("="*50)
    print(f"Upload Dir: {UPLOAD_DIR.absolute()}")
    print(f"Output Dir: {OUTPUT_DIR.absolute()}")
    print("\nAPI Endpoints:")
    print("  - http://localhost:8001")
    print("  - http://localhost:8001/docs (Swagger UI)")
    print("\nReady for video generation!")
    print("="*50 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8001)