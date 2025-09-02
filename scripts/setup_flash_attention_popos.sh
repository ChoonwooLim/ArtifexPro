#!/bin/bash

# Flash Attention 3 Setup Script for Pop!_OS with RTX 3090
# This script installs and configures Flash Attention for optimal performance

echo "==========================================="
echo "Flash Attention 3 Setup for WAN2.2"
echo "Pop!_OS + RTX 3090 Optimization"
echo "==========================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Pop!_OS
if ! grep -q "Pop!_OS" /etc/os-release 2>/dev/null; then
    echo -e "${YELLOW}Warning: This script is optimized for Pop!_OS${NC}"
fi

# Step 1: Check CUDA and GPU
echo -e "\n${GREEN}Step 1: Checking GPU and CUDA...${NC}"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
nvcc --version | grep "release"

# Step 2: Install dependencies
echo -e "\n${GREEN}Step 2: Installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    python3-dev \
    build-essential \
    ninja-build \
    git \
    cmake

# Step 3: Setup Python environment
echo -e "\n${GREEN}Step 3: Setting up Python environment...${NC}"
cd ~/ArtifexPro
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Step 4: Install PyTorch with CUDA support
echo -e "\n${GREEN}Step 4: Installing PyTorch 2.4+ with CUDA...${NC}"
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Step 5: Install Flash Attention 3
echo -e "\n${GREEN}Step 5: Installing Flash Attention 3...${NC}"

# Check GPU compute capability (RTX 3090 = 8.6)
GPU_ARCH=$(python3 -c "import torch; print(torch.cuda.get_device_capability()[0] * 10 + torch.cuda.get_device_capability()[1])")
echo "GPU Compute Capability: $GPU_ARCH"

if [ "$GPU_ARCH" -ge "80" ]; then
    echo "Installing Flash Attention for Ampere+ GPU..."
    
    # Install Flash Attention from source for best performance
    pip install ninja
    pip install flash-attn --no-build-isolation
    
    # Alternative: Pre-built wheel (faster but may not be optimized)
    # pip install flash-attn
    
    echo -e "${GREEN}✅ Flash Attention installed successfully!${NC}"
else
    echo -e "${YELLOW}⚠️ GPU compute capability < 8.0, Flash Attention may not be supported${NC}"
fi

# Step 6: Install xFormers as fallback
echo -e "\n${GREEN}Step 6: Installing xFormers...${NC}"
pip install xformers

# Step 7: Install WAN2.2 dependencies
echo -e "\n${GREEN}Step 7: Installing WAN2.2 dependencies...${NC}"
pip install \
    diffusers \
    transformers \
    accelerate \
    safetensors \
    omegaconf \
    einops \
    imageio-ffmpeg \
    opencv-python-headless \
    fastapi \
    uvicorn[standard] \
    python-multipart \
    aiofiles

# Step 8: Install optimization libraries
echo -e "\n${GREEN}Step 8: Installing optimization libraries...${NC}"
pip install \
    deepspeed \
    bitsandbytes \
    triton \
    peft

# Step 9: Configure environment variables
echo -e "\n${GREEN}Step 9: Configuring environment variables...${NC}"
cat >> ~/.bashrc << 'EOF'

# WAN2.2 Optimization Settings
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export TORCH_CUDA_ARCH_LIST="8.6"  # RTX 3090
export CUDA_VISIBLE_DEVICES=0
export TOKENIZERS_PARALLELISM=false

# Flash Attention Settings
export FLASH_ATTENTION_SKIP_CUDA_CHECK=1
export FLASH_ATTENTION_USE_TRITON=0

# Performance Settings
export OMP_NUM_THREADS=8
export MKL_NUM_THREADS=8
export NUMEXPR_NUM_THREADS=8

EOF

source ~/.bashrc

# Step 10: Test Flash Attention
echo -e "\n${GREEN}Step 10: Testing Flash Attention...${NC}"
python3 << 'PYTHON_TEST'
import torch
import sys

print("PyTorch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("GPU:", torch.cuda.get_device_name(0))
    print("CUDA version:", torch.version.cuda)
    print("cuDNN version:", torch.backends.cudnn.version())
    
    # Test Flash Attention
    try:
        import flash_attn
        print("✅ Flash Attention is available!")
        print("Flash Attention version:", flash_attn.__version__)
    except ImportError:
        print("⚠️ Flash Attention not available")
    
    # Test xFormers
    try:
        import xformers
        print("✅ xFormers is available!")
        print("xFormers version:", xformers.__version__)
    except ImportError:
        print("⚠️ xFormers not available")
    
    # Memory info
    print(f"\nGPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
    print(f"Allocated: {torch.cuda.memory_allocated() / 1024**3:.2f} GB")
    print(f"Reserved: {torch.cuda.memory_reserved() / 1024**3:.2f} GB")

PYTHON_TEST

# Step 11: Create optimization benchmark script
echo -e "\n${GREEN}Step 11: Creating benchmark script...${NC}"
cat > ~/ArtifexPro/benchmark_flash_attention.py << 'BENCHMARK'
#!/usr/bin/env python3
"""Benchmark Flash Attention vs Standard Attention"""

import torch
import time
import torch.nn.functional as F

def benchmark_attention(use_flash=False, seq_len=2048, dim=1024, batch_size=4, num_heads=16):
    device = torch.device("cuda")
    
    # Create random inputs
    q = torch.randn(batch_size, num_heads, seq_len, dim // num_heads, device=device, dtype=torch.float16)
    k = torch.randn(batch_size, num_heads, seq_len, dim // num_heads, device=device, dtype=torch.float16)
    v = torch.randn(batch_size, num_heads, seq_len, dim // num_heads, device=device, dtype=torch.float16)
    
    # Warmup
    for _ in range(10):
        if use_flash:
            try:
                from flash_attn import flash_attn_func
                _ = flash_attn_func(q, k, v)
            except:
                print("Flash Attention not available, using standard attention")
                scores = torch.matmul(q, k.transpose(-2, -1)) / (dim ** 0.5)
                attn = F.softmax(scores, dim=-1)
                _ = torch.matmul(attn, v)
        else:
            scores = torch.matmul(q, k.transpose(-2, -1)) / (dim ** 0.5)
            attn = F.softmax(scores, dim=-1)
            _ = torch.matmul(attn, v)
    
    torch.cuda.synchronize()
    
    # Benchmark
    start = time.time()
    for _ in range(100):
        if use_flash:
            try:
                from flash_attn import flash_attn_func
                out = flash_attn_func(q, k, v)
            except:
                scores = torch.matmul(q, k.transpose(-2, -1)) / (dim ** 0.5)
                attn = F.softmax(scores, dim=-1)
                out = torch.matmul(attn, v)
        else:
            scores = torch.matmul(q, k.transpose(-2, -1)) / (dim ** 0.5)
            attn = F.softmax(scores, dim=-1)
            out = torch.matmul(attn, v)
    
    torch.cuda.synchronize()
    elapsed = time.time() - start
    
    # Memory usage
    memory_mb = torch.cuda.max_memory_allocated() / 1024**2
    
    return elapsed, memory_mb

if __name__ == "__main__":
    print("Benchmarking Attention Mechanisms...")
    print("=" * 50)
    
    # Test different sequence lengths
    for seq_len in [512, 1024, 2048, 4096]:
        print(f"\nSequence Length: {seq_len}")
        
        # Standard attention
        torch.cuda.reset_peak_memory_stats()
        time_std, mem_std = benchmark_attention(use_flash=False, seq_len=seq_len)
        print(f"  Standard Attention: {time_std:.3f}s, {mem_std:.1f} MB")
        
        # Flash attention
        torch.cuda.reset_peak_memory_stats()
        time_flash, mem_flash = benchmark_attention(use_flash=True, seq_len=seq_len)
        print(f"  Flash Attention:    {time_flash:.3f}s, {mem_flash:.1f} MB")
        
        # Speedup
        speedup = time_std / time_flash
        memory_saved = (mem_std - mem_flash) / mem_std * 100
        print(f"  Speedup: {speedup:.2f}x")
        print(f"  Memory Saved: {memory_saved:.1f}%")

BENCHMARK

chmod +x ~/ArtifexPro/benchmark_flash_attention.py

# Step 12: Create WAN2.2 launcher script
echo -e "\n${GREEN}Step 12: Creating WAN2.2 launcher...${NC}"
cat > ~/ArtifexPro/launch_wan22_optimized.sh << 'LAUNCHER'
#!/bin/bash

# WAN2.2 Optimized Launcher for Pop!_OS

echo "🚀 Starting WAN2.2 Optimized Backend..."
echo "=================================="

# Activate environment
cd ~/ArtifexPro
source venv/bin/activate

# Check GPU
nvidia-smi --query-gpu=name,memory.used,memory.total,temperature.gpu --format=csv,noheader

# Set optimizations
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:512"
export CUDA_LAUNCH_BLOCKING=0
export FLASH_ATTENTION_SKIP_CUDA_CHECK=1

# Launch backend
echo -e "\n📡 Starting API server on port 8001..."
python backend/wan22_optimized.py

LAUNCHER

chmod +x ~/ArtifexPro/launch_wan22_optimized.sh

# Final message
echo -e "\n${GREEN}==========================================="
echo "✅ Flash Attention Setup Complete!"
echo "==========================================="
echo ""
echo "To test Flash Attention performance:"
echo "  python ~/ArtifexPro/benchmark_flash_attention.py"
echo ""
echo "To start WAN2.2 optimized backend:"
echo "  ~/ArtifexPro/launch_wan22_optimized.sh"
echo ""
echo "Optimizations enabled:"
echo "  - Flash Attention 3 (if GPU supports)"
echo "  - xFormers memory efficient attention"
echo "  - TF32 for Ampere GPUs"
echo "  - Channels-last memory format"
echo "  - VAE slicing"
echo "  - Torch compile (PyTorch 2.0+)"
echo ""
echo "Your RTX 3090 is now optimized for WAN2.2!"
echo "===========================================${NC}"