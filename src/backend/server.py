"""
ArtifexPro Backend Server
Handles AI video generation and processing using Wan2.2
"""

import os
import sys
import json
import asyncio
import logging
from pathlib import Path
from typing import Optional, Dict, Any
from datetime import datetime

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import torch
import numpy as np
from PIL import Image

# Add Wan2.2 to path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../Wan2.2'))

# Import Wan2.2 modules
try:
    from wan import text2video, image2video, speech2video, textimage2video
    from wan.configs import WAN_CONFIGS
    from wan.utils.utils import save_video, merge_video_audio
    from wan.utils.prompt_extend import QwenPromptExpander
except ImportError as e:
    logging.error(f"Failed to import Wan2.2 modules: {e}")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# Configuration
UPLOAD_FOLDER = Path('uploads')
OUTPUT_FOLDER = Path('outputs')
TEMP_FOLDER = Path('temp')
MAX_FILE_SIZE = 500 * 1024 * 1024  # 500MB

# Create necessary directories
for folder in [UPLOAD_FOLDER, OUTPUT_FOLDER, TEMP_FOLDER]:
    folder.mkdir(exist_ok=True)

# Global variables for model management
models = {}
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

class VideoGenerator:
    """Handles video generation using Wan2.2"""
    
    def __init__(self):
        self.models = {}
        self.device = device
        self.is_generating = False
        
    def load_model(self, task: str, ckpt_dir: str) -> bool:
        """Load a Wan2.2 model for specific task"""
        try:
            if task in self.models:
                return True
                
            logger.info(f"Loading model for task: {task}")
            
            # Get configuration for task
            cfg = WAN_CONFIGS.get(task)
            if not cfg:
                logger.error(f"Unknown task: {task}")
                return False
            
            # Load model based on task type
            if task == "t2v-A14B":
                model = text2video.load_model(ckpt_dir, cfg)
            elif task == "i2v-A14B":
                model = image2video.load_model(ckpt_dir, cfg)
            elif task == "s2v-14B":
                model = speech2video.load_model(ckpt_dir, cfg)
            elif task == "ti2v-5B":
                model = textimage2video.load_model(ckpt_dir, cfg)
            else:
                logger.error(f"Unsupported task: {task}")
                return False
            
            self.models[task] = model
            logger.info(f"Model loaded successfully for task: {task}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            return False
    
    async def generate_video(self, params: Dict[str, Any], progress_callback=None) -> Optional[str]:
        """Generate video based on parameters"""
        try:
            self.is_generating = True
            
            task = params.get('task', 't2v-A14B')
            prompt = params.get('prompt', '')
            image_path = params.get('image_path')
            audio_path = params.get('audio_path')
            duration = params.get('duration', 5)
            quality = params.get('quality', 'standard')
            
            # Set resolution based on quality
            resolution_map = {
                'standard': '720p',
                'high': '1080p',
                'ultra': '4K'
            }
            resolution = resolution_map.get(quality, '720p')
            
            # Generate unique output filename
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            output_path = OUTPUT_FOLDER / f"generated_{timestamp}.mp4"
            
            # Progress updates
            if progress_callback:
                await progress_callback(10, "Initializing generation...")
            
            # Prepare generation parameters
            gen_params = {
                'prompt': prompt,
                'size': resolution,
                'frame_num': int(duration * 30),  # 30 fps
                'sample_steps': 50,
                'sample_guide_scale': 7.5,
                'seed': np.random.randint(0, 2**32)
            }
            
            if image_path:
                gen_params['image'] = image_path
            if audio_path:
                gen_params['audio'] = audio_path
            
            # Load model if not already loaded
            if task not in self.models:
                if progress_callback:
                    await progress_callback(20, "Loading AI model...")
                # In production, load actual model
                # self.load_model(task, ckpt_dir)
            
            if progress_callback:
                await progress_callback(30, "Processing input...")
            
            # Simulate generation process (replace with actual Wan2.2 generation)
            for i in range(40, 90, 10):
                if progress_callback:
                    await progress_callback(i, f"Generating video... {i}%")
                await asyncio.sleep(1)  # Simulate processing time
            
            # In production, call actual generation function
            # result = self.models[task].generate(**gen_params)
            # save_video(result, str(output_path))
            
            # For demo, create a placeholder file
            output_path.touch()
            
            if progress_callback:
                await progress_callback(100, "Generation complete!")
            
            self.is_generating = False
            return str(output_path)
            
        except Exception as e:
            logger.error(f"Video generation failed: {e}")
            self.is_generating = False
            return None

# Initialize generator
generator = VideoGenerator()

# API Routes
@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'gpu_available': torch.cuda.is_available(),
        'device': str(device)
    })

@app.route('/api/generate', methods=['POST'])
async def generate_video_endpoint():
    """Generate video endpoint"""
    try:
        data = request.json
        
        # Validate input
        if not data.get('prompt'):
            return jsonify({'error': 'Prompt is required'}), 400
        
        # Check if already generating
        if generator.is_generating:
            return jsonify({'error': 'Generation already in progress'}), 429
        
        # Start generation with progress updates
        async def progress_callback(percent, message):
            socketio.emit('generation_progress', {
                'percent': percent,
                'message': message
            })
        
        output_path = await generator.generate_video(data, progress_callback)
        
        if output_path:
            return jsonify({
                'success': True,
                'output_path': output_path,
                'message': 'Video generated successfully'
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Generation failed'
            }), 500
            
    except Exception as e:
        logger.error(f"Generation endpoint error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """Upload file endpoint"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Save file
        filename = file.filename
        filepath = UPLOAD_FOLDER / filename
        file.save(str(filepath))
        
        return jsonify({
            'success': True,
            'filepath': str(filepath),
            'filename': filename
        })
        
    except Exception as e:
        logger.error(f"Upload error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/export', methods=['POST'])
def export_video():
    """Export processed video"""
    try:
        data = request.json
        input_path = data.get('input_path')
        export_settings = data.get('settings', {})
        
        if not input_path or not Path(input_path).exists():
            return jsonify({'error': 'Invalid input path'}), 400
        
        # Process export (placeholder for actual export logic)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_path = OUTPUT_FOLDER / f"export_{timestamp}.mp4"
        
        # In production, apply export settings and process video
        # For now, just copy the file
        output_path.touch()
        
        return jsonify({
            'success': True,
            'output_path': str(output_path)
        })
        
    except Exception as e:
        logger.error(f"Export error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/effects', methods=['GET'])
def get_effects():
    """Get available effects list"""
    effects = [
        {'id': 'blur', 'name': 'Blur', 'category': 'Basic'},
        {'id': 'sharpen', 'name': 'Sharpen', 'category': 'Basic'},
        {'id': 'brightness', 'name': 'Brightness', 'category': 'Color'},
        {'id': 'contrast', 'name': 'Contrast', 'category': 'Color'},
        {'id': 'saturation', 'name': 'Saturation', 'category': 'Color'},
        {'id': 'hue', 'name': 'Hue Shift', 'category': 'Color'},
        {'id': 'vintage', 'name': 'Vintage', 'category': 'Style'},
        {'id': 'cinematic', 'name': 'Cinematic', 'category': 'Style'},
        {'id': 'glitch', 'name': 'Glitch', 'category': 'Creative'},
        {'id': 'pixelate', 'name': 'Pixelate', 'category': 'Creative'},
    ]
    return jsonify(effects)

@app.route('/api/presets', methods=['GET'])
def get_presets():
    """Get color grading presets"""
    presets = [
        {'id': 'teal-orange', 'name': 'Teal & Orange', 'thumbnail': '/assets/presets/teal-orange.jpg'},
        {'id': 'film-noir', 'name': 'Film Noir', 'thumbnail': '/assets/presets/film-noir.jpg'},
        {'id': 'warm-sunset', 'name': 'Warm Sunset', 'thumbnail': '/assets/presets/warm-sunset.jpg'},
        {'id': 'cool-blue', 'name': 'Cool Blue', 'thumbnail': '/assets/presets/cool-blue.jpg'},
        {'id': 'vintage-film', 'name': 'Vintage Film', 'thumbnail': '/assets/presets/vintage-film.jpg'},
    ]
    return jsonify(presets)

# WebSocket Events
@socketio.on('connect')
def handle_connect():
    logger.info('Client connected')
    emit('connected', {'message': 'Connected to ArtifexPro backend'})

@socketio.on('disconnect')
def handle_disconnect():
    logger.info('Client disconnected')

@socketio.on('request_status')
def handle_status_request():
    emit('status', {
        'generating': generator.is_generating,
        'gpu_memory': torch.cuda.memory_allocated() if torch.cuda.is_available() else 0,
        'models_loaded': list(generator.models.keys())
    })

if __name__ == '__main__':
    logger.info(f"Starting ArtifexPro backend server on port 5000")
    logger.info(f"Device: {device}")
    logger.info(f"GPU Available: {torch.cuda.is_available()}")
    
    socketio.run(app, host='127.0.0.1', port=5000, debug=True)