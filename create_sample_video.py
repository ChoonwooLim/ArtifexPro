"""
샘플 비디오 생성 스크립트
OpenCV를 사용해 간단한 테스트 비디오 생성
"""

import cv2
import numpy as np
from pathlib import Path

def create_sample_video(output_path: str, text: str = "SAMPLE", duration: int = 5, fps: int = 24):
    """간단한 샘플 비디오 생성"""
    
    # 비디오 설정
    width, height = 1280, 720
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
    
    # 총 프레임 수
    total_frames = fps * duration
    
    for frame_num in range(total_frames):
        # 그라디언트 배경 생성
        img = np.zeros((height, width, 3), dtype=np.uint8)
        
        # 색상 변화 효과 (OpenCV HSV는 0-179 범위)
        hue = (frame_num * 2) % 180
        color1 = tuple(int(c) for c in cv2.cvtColor(np.uint8([[[hue, 255, 255]]]), cv2.COLOR_HSV2BGR)[0][0])
        color2 = tuple(int(c) for c in cv2.cvtColor(np.uint8([[[(hue + 30) % 180, 255, 255]]]), cv2.COLOR_HSV2BGR)[0][0])
        
        # 그라디언트 그리기
        for y in range(height):
            ratio = y / height
            color = tuple(int(c1 * (1 - ratio) + c2 * ratio) for c1, c2 in zip(color1, color2))
            cv2.line(img, (0, y), (width, y), color, 1)
        
        # 텍스트 추가
        font = cv2.FONT_HERSHEY_SIMPLEX
        text_size = cv2.getTextSize(text, font, 3, 5)[0]
        text_x = (width - text_size[0]) // 2
        text_y = (height + text_size[1]) // 2
        
        # 텍스트 배경
        cv2.rectangle(img, (text_x - 20, text_y - text_size[1] - 20), 
                     (text_x + text_size[0] + 20, text_y + 20), 
                     (0, 0, 0), -1)
        
        # 텍스트
        cv2.putText(img, text, (text_x, text_y), font, 3, (255, 255, 255), 5)
        
        # 프레임 번호
        frame_text = f"Frame {frame_num + 1}/{total_frames}"
        cv2.putText(img, frame_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        # 진행 바
        progress = frame_num / total_frames
        cv2.rectangle(img, (10, height - 30), (int(10 + (width - 20) * progress), height - 10), (0, 255, 0), -1)
        
        # 프레임 쓰기
        out.write(img)
    
    # 정리
    out.release()
    
    print(f"Sample video created: {output_path}")

if __name__ == "__main__":
    # outputs 폴더 생성
    output_dir = Path("outputs")
    output_dir.mkdir(exist_ok=True)
    
    # 샘플 비디오 생성
    create_sample_video("outputs/sample_video.mp4", "ArtifexPro", 5, 24)
    print("Sample video generated successfully!")