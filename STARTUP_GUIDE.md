# 🚀 ArtifexPro Startup Guide

## Current Status: ✅ RUNNING

### Services Status
- **Frontend**: ✅ Running on http://localhost:3000
- **Backend API**: ✅ Running on http://localhost:8001
- **Models**: ✅ TI2V-5B and S2V-14B Ready

## Quick Start

### The app is already running! Just open your browser:
```
http://localhost:3000
```

## Available Features

### 1. WAN2.2 Professional Studio
- **Text to Video (T2V-A14B)**: Generate videos from text prompts
- **Image to Video (I2V-A14B)**: Animate static images
- **Text+Image to Video (TI2V-5B)**: Combine text and images for video
- **Sound to Video (S2V-14B)**: Create videos from audio

### 2. Quality Presets
- **Draft**: Fast preview (20 steps)
- **Preview**: Balanced quality (35 steps)
- **Production**: High quality (50 steps)
- **Cinema**: Maximum quality (75 steps)

### 3. Aesthetic Presets
- Photorealistic
- Cinematic
- Anime
- Digital Art
- Fantasy
- Cyberpunk
- Minimalist
- Vintage

### 4. Advanced Features
- Prompt Enhancement
- Negative Prompts
- Custom Seeds
- Motion Control
- Style Transfer
- Frame Interpolation

## How to Use

1. **Open the App**: http://localhost:3000
2. **Select Model**: Choose from T2V, I2V, TI2V, or S2V
3. **Enter Prompt**: Describe what you want to generate
4. **Upload Media** (if needed):
   - Image for I2V/TI2V
   - Audio for S2V
5. **Choose Settings**:
   - Quality preset
   - Aesthetic style
   - Video duration
   - Resolution
6. **Click Generate**: Wait for your video to be created

## Optimization Status

### Flash Attention (Ready for Pop!_OS)
- Setup script created: `scripts/setup_flash_attention_popos.sh`
- Expected speedup: 2.5-4x
- Memory savings: 40-60%

### To Enable Flash Attention:
```bash
# On Pop!_OS machine
cd ~/ArtifexPro
bash scripts/setup_flash_attention_popos.sh
```

## Troubleshooting

### If Frontend doesn't load:
```bash
# Restart frontend
npm run dev
```

### If Backend API fails:
```bash
# Restart backend
cd backend
python simple_api.py
```

### If you see port conflicts:
The backend has been moved from port 8000 to 8001 to avoid conflicts.

## System Requirements Met ✅
- Windows PC with frontend
- Dual RTX 3090 (48GB VRAM total)
- Pop!_OS ready for GPU processing
- All WAN2.2 models available

## Next Steps
1. Generate your first video
2. Test different quality presets
3. Experiment with aesthetic styles
4. Deploy Flash Attention on Pop!_OS for maximum performance

---

**Your high-end AI video generation platform is ready!**