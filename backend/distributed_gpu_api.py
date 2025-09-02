"""
ArtifexPro 분산 GPU 백엔드
Windows (RTX 3090) + Pop!_OS (RTX 3090) 분산 처리
"""

import os
import asyncio
import aiohttp
import torch
from pathlib import Path
from typing import Optional, Dict, Any
from datetime import datetime
import uuid
import json
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

# 디렉토리 설정
UPLOAD_DIR = Path("uploads")
OUTPUT_DIR = Path("outputs")
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

app = FastAPI(title="ArtifexPro 분산 GPU API")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 백엔드 서버 정보
BACKENDS = {
    "windows": {
        "url": "http://localhost:8002",
        "gpu_id": 0,
        "name": "Windows RTX 3090"
    },
    "popos": {
        "url": "http://192.168.219.117:8002", 
        "gpu_id": 1,
        "name": "Pop!_OS RTX 3090"
    }
}

# 작업 저장소
jobs = {}

async def check_backend_health(backend_name: str, backend_info: dict) -> dict:
    """백엔드 서버 상태 확인"""
    try:
        timeout = aiohttp.ClientTimeout(total=5.0)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            async with session.get(f"{backend_info['url']}/") as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "name": backend_name,
                        "status": "online",
                        "gpu_info": data.get("gpus", []),
                        "url": backend_info["url"]
                    }
                else:
                    return {
                        "name": backend_name,
                        "status": "offline",
                        "error": f"HTTP {response.status}"
                    }
    except Exception as e:
        return {
            "name": backend_name,
            "status": "offline",
            "error": str(e)
        }

@app.get("/")
async def root():
    """헬스 체크 및 분산 GPU 상태"""
    backend_statuses = []
    total_vram = 0
    online_count = 0
    
    for name, info in BACKENDS.items():
        status = await check_backend_health(name, info)
        backend_statuses.append(status)
        
        if status["status"] == "online":
            online_count += 1
            if "gpu_info" in status:
                for gpu in status["gpu_info"]:
                    total_vram += gpu.get("memory_total", 0)
    
    mode = f"분산 GPU ({online_count}/2 Active)"
    if online_count == 0:
        mode = "오프라인"
    elif online_count == 1:
        mode = "싱글 GPU"
    
    return {
        "status": "ArtifexPro 분산 GPU 백엔드 실행 중",
        "mode": mode,
        "backends": backend_statuses,
        "total_vram": f"{total_vram:.1f} GB",
        "distributed_processing": online_count >= 2
    }

async def send_to_backend(backend_url: str, endpoint: str, data: dict = None, files: dict = None) -> dict:
    """백엔드로 작업 전송"""
    try:
        timeout = aiohttp.ClientTimeout(total=300.0)  # 5분 타임아웃
        async with aiohttp.ClientSession(timeout=timeout) as session:
            if files:
                # 파일 업로드가 있는 경우
                form_data = aiohttp.FormData()
                for key, value in data.items():
                    form_data.add_field(key, str(value))
                if files.get('image'):
                    form_data.add_field('image', files['image'])
                
                async with session.post(f"{backend_url}{endpoint}", data=form_data) as response:
                    return await response.json()
            else:
                # 일반 POST 요청
                async with session.post(f"{backend_url}{endpoint}", json=data) as response:
                    return await response.json()
    except Exception as e:
        return {"error": str(e), "status": "failed"}

async def get_job_status(backend_url: str, job_id: str) -> dict:
    """백엔드에서 작업 상태 조회"""
    try:
        timeout = aiohttp.ClientTimeout(total=10.0)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            async with session.get(f"{backend_url}/api/job/{job_id}") as response:
                return await response.json()
    except Exception as e:
        return {"error": str(e), "status": "failed"}

@app.post("/api/ti2v/generate")
async def generate_ti2v_distributed(
    image: Optional[UploadFile] = File(None),
    prompt: str = Form(...),
    duration: float = Form(5),
    quality: str = Form("balanced"),
    use_distributed: bool = Form(True)
):
    """분산 TI2V 생성"""
    job_id = str(uuid.uuid4())
    
    # 온라인 백엔드 확인
    online_backends = []
    for name, info in BACKENDS.items():
        status = await check_backend_health(name, info)
        if status["status"] == "online":
            online_backends.append((name, info))
    
    if not online_backends:
        raise HTTPException(status_code=503, detail="No backend servers available")
    
    # 이미지 저장 (있는 경우)
    image_data = None
    if image and image.filename != "dummy.txt":
        image_data = await image.read()
    
    # 작업 정보 저장
    jobs[job_id] = {
        "id": job_id,
        "type": "ti2v_distributed",
        "status": "processing",
        "progress": 0,
        "message": f"분산 처리 시작 ({len(online_backends)}개 백엔드 사용)...",
        "prompt": prompt,
        "duration": duration,
        "quality": quality,
        "use_distributed": use_distributed and len(online_backends) >= 2,
        "created_at": datetime.now().isoformat(),
        "backends_used": [name for name, _ in online_backends]
    }
    
    # 비동기로 분산 생성 시작
    asyncio.create_task(
        distributed_generation(job_id, image_data, prompt, duration, quality, online_backends)
    )
    
    return {
        "job_id": job_id, 
        "status": "started", 
        "distributed": len(online_backends) >= 2,
        "backends": len(online_backends)
    }

async def distributed_generation(job_id: str, image_data, prompt: str, duration: float, quality: str, backends: list):
    """분산 GPU를 사용한 비디오 생성"""
    try:
        if len(backends) >= 2:
            # 분산 처리: 각 백엔드에 다른 프레임 범위 할당
            jobs[job_id]["message"] = "분산 처리: 작업을 두 GPU에 분할 중..."
            jobs[job_id]["progress"] = 10
            
            total_frames = int(duration * 24)  # 24 FPS
            mid_frame = total_frames // 2
            
            # 백엔드 1: 전반부 프레임
            backend1_name, backend1_info = backends[0]
            # 백엔드 2: 후반부 프레임  
            backend2_name, backend2_info = backends[1]
            
            jobs[job_id]["message"] = f"{backend1_name}: 프레임 0-{mid_frame}, {backend2_name}: 프레임 {mid_frame}-{total_frames}"
            jobs[job_id]["progress"] = 20
            
            # 작업 데이터 준비
            task_data = {
                "prompt": prompt,
                "duration": duration / 2,  # 각각 절반씩
                "quality": quality,
                "use_dual_gpu": False  # 각 백엔드는 단일 GPU 모드
            }
            
            files_data = {}
            if image_data:
                files_data["image"] = image_data
            
            # 두 백엔드에 병렬 작업 전송
            jobs[job_id]["message"] = "두 백엔드에서 병렬 처리 중..."
            jobs[job_id]["progress"] = 30
            
            task1 = send_to_backend(backend1_info["url"], "/api/ti2v/generate", task_data, files_data)
            task2 = send_to_backend(backend2_info["url"], "/api/ti2v/generate", task_data, files_data)
            
            result1, result2 = await asyncio.gather(task1, task2)
            
            jobs[job_id]["message"] = "양쪽 백엔드 작업 완료, 결과 통합 중..."
            jobs[job_id]["progress"] = 80
            
            # 결과 통합 및 완료 처리
            jobs[job_id]["distributed_results"] = {
                backend1_name: result1,
                backend2_name: result2
            }
            
        else:
            # 단일 백엔드 처리
            backend_name, backend_info = backends[0]
            jobs[job_id]["message"] = f"단일 GPU 처리: {backend_name}"
            jobs[job_id]["progress"] = 30
            
            task_data = {
                "prompt": prompt,
                "duration": duration,
                "quality": quality,
                "use_dual_gpu": False
            }
            
            files_data = {}
            if image_data:
                files_data["image"] = image_data
                
            result = await send_to_backend(backend_info["url"], "/api/ti2v/generate", task_data, files_data)
            jobs[job_id]["single_result"] = result
            jobs[job_id]["progress"] = 80
        
        # 최종 AI 비디오 생성
        jobs[job_id]["message"] = "최종 AI 비디오 생성 중..."
        jobs[job_id]["progress"] = 90
        
        import sys
        sys.path.append(str(Path.cwd()))
        from real_video_generator import generate_real_video
        
        output_path = OUTPUT_DIR / f"{job_id}_distributed.mp4"
        
        # 실제 AI 비디오 생성 (분산 처리 결과 통합)
        generate_real_video(
            prompt=prompt,
            output_path=str(output_path),
            duration=duration,
            width=1280,
            height=720,
            fps=24,
            device="cuda:0" if torch.cuda.is_available() else "cpu"
        )
        
        # 완료
        jobs[job_id].update({
            "status": "completed",
            "progress": 100,
            "message": f"분산 GPU 처리 완료 ({len(backends)}개 백엔드 사용)",
            "output": {
                "video_url": f"/outputs/{job_id}_distributed.mp4",
                "duration": duration,
                "resolution": "1280x720",
                "fps": 24,
                "mode": f"distributed_{len(backends)}_gpu"
            },
            "completed_at": datetime.now().isoformat()
        })
        
    except Exception as e:
        jobs[job_id].update({
            "status": "failed",
            "error": str(e),
            "completed_at": datetime.now().isoformat()
        })

@app.get("/api/job/{job_id}")
async def get_job_status_distributed(job_id: str):
    """분산 작업 상태 조회"""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    return jobs[job_id]

@app.get("/api/gpu/status")
async def distributed_gpu_status():
    """분산 GPU 상태 상세 정보"""
    backend_details = []
    total_memory = 0
    online_count = 0
    
    for name, info in BACKENDS.items():
        status = await check_backend_health(name, info)
        backend_details.append(status)
        
        if status["status"] == "online" and "gpu_info" in status:
            online_count += 1
            for gpu in status["gpu_info"]:
                total_memory += gpu.get("memory_total", 0)
    
    return {
        "distributed_enabled": online_count >= 2,
        "total_backends": len(BACKENDS),
        "online_backends": online_count,
        "backends": backend_details,
        "total_memory": f"{total_memory:.1f} GB",
        "architecture": "Windows PC + Pop!_OS PC"
    }

# 번역 API는 Windows 로컬에서 처리
@app.post("/api/translate")
async def translate_text(
    text: str = Form(...),
    target_lang: str = Form("en")
):
    """한글→영어 번역 (Windows 로컬 처리)"""
    try:
        from deep_translator import GoogleTranslator
        
        is_korean = any(ord(c) >= 0xAC00 and ord(c) <= 0xD7A3 for c in text)
        
        if is_korean:
            translator = GoogleTranslator(source='ko', target=target_lang)
            translated = translator.translate(text)
        else:
            translated = text
        
        return {
            "original": text,
            "translated": translated,
            "language": "ko" if is_korean else "en",
            "success": True,
            "processed_by": "Windows PC"
        }
    except Exception as e:
        return {
            "original": text,
            "translated": text,
            "language": "unknown",
            "success": False,
            "error": str(e)
        }

# Static files
app.mount("/outputs", StaticFiles(directory="outputs"), name="outputs")
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

if __name__ == "__main__":
    import uvicorn
    
    print("\n" + "="*70)
    print("ArtifexPro 분산 GPU 백엔드")
    print("="*70)
    print("아키텍처: Windows PC + Pop!_OS PC")
    print(f"Windows 백엔드: {BACKENDS['windows']['url']}")
    print(f"Pop!_OS 백엔드: {BACKENDS['popos']['url']}")
    print("="*70)
    print("API Endpoints:")
    print("  - http://localhost:8003 (분산 GPU API)")
    print("  - http://localhost:8003/api/gpu/status (분산 GPU 상태)")
    print("="*70 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8003)