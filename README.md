# ArtifexPro Studio

Professional AI-Powered Video Generation & Editing Suite

## Overview

ArtifexPro Studio is a high-end video editing application that combines traditional video editing capabilities with cutting-edge AI video generation powered by Wan2.2. Built with Electron and Python, it provides a professional-grade interface for creators, filmmakers, and content producers.

## Features

### 🎬 Professional Video Editing
- Multi-track timeline with unlimited video and audio tracks
- Real-time preview with GPU acceleration
- Professional color grading tools
- Advanced audio mixing capabilities
- Frame-accurate editing

### 🤖 AI-Powered Generation (Wan2.2)
- **Text-to-Video**: Generate videos from text descriptions
- **Image-to-Video**: Animate static images
- **Speech-to-Video**: Create videos synchronized with audio
- **Style Transfer**: Apply artistic styles to videos

### 🎨 Advanced Effects & Tools
- Built-in effects library
- LUT presets for color grading
- Motion tracking
- Green screen removal
- Video stabilization

### 💡 Smart Features
- Auto-scene detection
- AI-powered video enhancement
- Smart trimming and cutting
- Automated subtitle generation
- Content-aware fill for video

## System Requirements

### Minimum
- OS: Windows 10/11, macOS 10.15+, Ubuntu 20.04+
- CPU: Intel i5 8th gen or AMD Ryzen 5 3600
- RAM: 8GB
- GPU: NVIDIA GTX 1060 / AMD RX 580 (4GB VRAM)
- Storage: 10GB free space

### Recommended
- OS: Windows 11, macOS 12+, Ubuntu 22.04+
- CPU: Intel i7 10th gen or AMD Ryzen 7 5800X
- RAM: 32GB
- GPU: NVIDIA RTX 3070 / AMD RX 6700 XT (8GB+ VRAM)
- Storage: 50GB SSD space

## Installation

### Prerequisites
1. Node.js 18+ and npm
2. Python 3.9+
3. CUDA 11.8+ (for NVIDIA GPUs)

### Setup

```bash
# Clone the repository
git clone https://github.com/artifexpro/studio.git
cd ArtifexPro

# Install Node.js dependencies
npm install

# Install Python dependencies
pip install -r requirements.txt

# Download Wan2.2 models (optional, for full AI features)
python scripts/download_models.py

# Start development version
npm run dev
```

### Building for Production

```bash
# Build for current platform
npm run build

# Package as installer
npm run package
```

## Usage

### Quick Start

1. **Launch ArtifexPro Studio**
2. **Create New Project** (Ctrl+N)
3. **Import Media** (Ctrl+I) - Import videos, images, or audio
4. **AI Generation**:
   - Switch to AI Tools panel
   - Select generation mode (Text/Image/Speech to Video)
   - Enter your prompt
   - Click "Generate Video"
5. **Edit Timeline**:
   - Drag media to timeline tracks
   - Use tools to cut, trim, and arrange
   - Apply effects and transitions
6. **Export Video** (Ctrl+E)

### AI Video Generation Modes

#### Text-to-Video (T2V)
```
Example prompt: "A serene sunset over mountain peaks with birds flying"
Duration: 5-30 seconds
Quality: 720p/1080p/4K
```

#### Image-to-Video (I2V)
```
Input: Static image (JPG/PNG)
Prompt: Describe the motion/animation
Output: Animated video from image
```

#### Speech-to-Video (S2V)
```
Input: Audio file + Reference image
Output: Lip-synced video with speech
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+N | New Project |
| Ctrl+O | Open Project |
| Ctrl+S | Save Project |
| Ctrl+I | Import Media |
| Ctrl+E | Export Video |
| Ctrl+G | AI Generator |
| Space | Play/Pause |
| J/K/L | Playback controls |
| I/O | Set In/Out points |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |

## API Integration

ArtifexPro provides a REST API for automation:

```python
import requests

# Generate video via API
response = requests.post('http://localhost:5000/api/generate', json={
    'task': 't2v-A14B',
    'prompt': 'Beautiful ocean waves at sunset',
    'duration': 10,
    'quality': 'high'
})

result = response.json()
print(f"Generated video: {result['output_path']}")
```

## Plugin Development

Create custom effects and tools:

```javascript
// plugins/my-effect.js
class MyCustomEffect {
    constructor() {
        this.name = 'My Effect';
        this.category = 'Custom';
    }
    
    apply(frame, params) {
        // Process video frame
        return processedFrame;
    }
}

export default MyCustomEffect;
```

## Troubleshooting

### GPU Not Detected
- Ensure CUDA is installed (NVIDIA)
- Update GPU drivers
- Check `nvidia-smi` output

### Generation Failed
- Check model files in `models/` directory
- Verify Python backend is running
- Check available VRAM

### Performance Issues
- Lower preview quality
- Close other applications
- Enable GPU acceleration in preferences

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

ArtifexPro Studio is released under the MIT License. See [LICENSE](LICENSE) for details.

## Credits

- Wan2.2 AI Engine by Alibaba
- Electron Framework
- FFmpeg for video processing
- Socket.IO for real-time communication

## Support

- Documentation: [docs.artifexpro.com](https://docs.artifexpro.com)
- Issues: [GitHub Issues](https://github.com/artifexpro/studio/issues)
- Discord: [Join our community](https://discord.gg/artifexpro)

---

**ArtifexPro Studio** - Where AI meets Professional Video Editing

© 2024 ArtifexPro Team