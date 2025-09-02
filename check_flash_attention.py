#!/usr/bin/env python3
"""Check Flash Attention installation and status"""

import sys
import torch

print("🔍 Checking Flash Attention Status...")
print("=" * 50)

# Check PyTorch and CUDA
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
    print(f"CUDA version: {torch.version.cuda}")

print("=" * 50)

# Check Flash Attention
try:
    import flash_attn
    print(f"✅ Flash Attention INSTALLED")
    print(f"   Version: {flash_attn.__version__}")
    FLASH_AVAILABLE = True
except ImportError as e:
    print(f"❌ Flash Attention NOT INSTALLED")
    print(f"   Error: {e}")
    FLASH_AVAILABLE = False

# Check xFormers
try:
    import xformers
    print(f"✅ xFormers INSTALLED (Fallback)")
    print(f"   Version: {xformers.__version__}")
except ImportError:
    print(f"⚠️ xFormers NOT INSTALLED")

print("=" * 50)

# Test Flash Attention if available
if FLASH_AVAILABLE and torch.cuda.is_available():
    print("\n🧪 Testing Flash Attention...")
    try:
        from flash_attn import flash_attn_func
        
        # Small test
        batch, seq_len, num_heads, head_dim = 1, 512, 8, 64
        device = torch.device("cuda")
        
        q = torch.randn(batch, seq_len, num_heads, head_dim, device=device, dtype=torch.float16)
        k = torch.randn(batch, seq_len, num_heads, head_dim, device=device, dtype=torch.float16)
        v = torch.randn(batch, seq_len, num_heads, head_dim, device=device, dtype=torch.float16)
        
        output = flash_attn_func(q, k, v)
        print(f"✅ Flash Attention test PASSED")
        print(f"   Output shape: {output.shape}")
    except Exception as e:
        print(f"❌ Flash Attention test FAILED")
        print(f"   Error: {e}")

print("\n📊 Summary:")
if FLASH_AVAILABLE:
    print("Flash Attention is ready to use for WAN2.2 optimization!")
    print("Expected speedup: 2.5-4x for video generation")
else:
    print("Flash Attention needs to be installed for optimal performance.")
    print("Run: bash scripts/setup_flash_attention_popos.sh")