"""
Test Flash Attention Performance
Compare standard attention vs Flash Attention on RTX 3090
"""

import torch
import time
import numpy as np
from typing import Tuple, Dict
import sys

def check_environment():
    """Check GPU and Flash Attention availability"""
    print("🔍 Checking Environment...")
    print("=" * 50)
    
    # Check CUDA
    if not torch.cuda.is_available():
        print("❌ CUDA is not available")
        return False
    
    # GPU info
    gpu_count = torch.cuda.device_count()
    print(f"✅ Found {gpu_count} GPU(s)")
    
    for i in range(gpu_count):
        props = torch.cuda.get_device_properties(i)
        print(f"  GPU {i}: {props.name}")
        print(f"    Memory: {props.total_memory / 1024**3:.1f} GB")
        print(f"    Compute Capability: {props.major}.{props.minor}")
    
    # Check Flash Attention
    try:
        import flash_attn
        print(f"✅ Flash Attention installed: v{flash_attn.__version__}")
    except ImportError:
        print("⚠️ Flash Attention not installed")
    
    # Check xFormers
    try:
        import xformers
        print(f"✅ xFormers installed: v{xformers.__version__}")
    except ImportError:
        print("⚠️ xFormers not installed")
    
    print("=" * 50)
    return True

def benchmark_standard_attention(
    batch_size: int = 4,
    seq_len: int = 2048,
    dim: int = 1024,
    num_heads: int = 16,
    iterations: int = 100
) -> Tuple[float, float]:
    """Benchmark standard PyTorch attention"""
    
    device = torch.device("cuda")
    head_dim = dim // num_heads
    
    # Create random inputs
    q = torch.randn(batch_size, num_heads, seq_len, head_dim, 
                   device=device, dtype=torch.float16)
    k = torch.randn(batch_size, num_heads, seq_len, head_dim,
                   device=device, dtype=torch.float16)
    v = torch.randn(batch_size, num_heads, seq_len, head_dim,
                   device=device, dtype=torch.float16)
    
    # Warmup
    for _ in range(10):
        scores = torch.matmul(q, k.transpose(-2, -1)) / (head_dim ** 0.5)
        attn = torch.nn.functional.softmax(scores, dim=-1)
        output = torch.matmul(attn, v)
    
    torch.cuda.synchronize()
    
    # Benchmark
    start_time = time.time()
    
    for _ in range(iterations):
        scores = torch.matmul(q, k.transpose(-2, -1)) / (head_dim ** 0.5)
        attn = torch.nn.functional.softmax(scores, dim=-1)
        output = torch.matmul(attn, v)
    
    torch.cuda.synchronize()
    elapsed_time = time.time() - start_time
    
    # Memory usage
    memory_mb = torch.cuda.max_memory_allocated() / 1024**2
    torch.cuda.reset_peak_memory_stats()
    
    return elapsed_time, memory_mb

def benchmark_flash_attention(
    batch_size: int = 4,
    seq_len: int = 2048,
    dim: int = 1024,
    num_heads: int = 16,
    iterations: int = 100
) -> Tuple[float, float]:
    """Benchmark Flash Attention"""
    
    try:
        from flash_attn import flash_attn_func
    except ImportError:
        print("Flash Attention not available")
        return float('inf'), 0
    
    device = torch.device("cuda")
    head_dim = dim // num_heads
    
    # Create random inputs (Flash Attention expects different format)
    # Shape: (batch, seq_len, num_heads, head_dim)
    q = torch.randn(batch_size, seq_len, num_heads, head_dim,
                   device=device, dtype=torch.float16)
    k = torch.randn(batch_size, seq_len, num_heads, head_dim,
                   device=device, dtype=torch.float16)
    v = torch.randn(batch_size, seq_len, num_heads, head_dim,
                   device=device, dtype=torch.float16)
    
    # Warmup
    for _ in range(10):
        output = flash_attn_func(q, k, v)
    
    torch.cuda.synchronize()
    
    # Benchmark
    start_time = time.time()
    
    for _ in range(iterations):
        output = flash_attn_func(q, k, v)
    
    torch.cuda.synchronize()
    elapsed_time = time.time() - start_time
    
    # Memory usage
    memory_mb = torch.cuda.max_memory_allocated() / 1024**2
    torch.cuda.reset_peak_memory_stats()
    
    return elapsed_time, memory_mb

def benchmark_xformers_attention(
    batch_size: int = 4,
    seq_len: int = 2048,
    dim: int = 1024,
    num_heads: int = 16,
    iterations: int = 100
) -> Tuple[float, float]:
    """Benchmark xFormers memory efficient attention"""
    
    try:
        import xformers.ops as xops
    except ImportError:
        print("xFormers not available")
        return float('inf'), 0
    
    device = torch.device("cuda")
    head_dim = dim // num_heads
    
    # Create random inputs
    # xFormers expects: (batch * seq_len, num_heads, head_dim)
    q = torch.randn(batch_size * seq_len, num_heads, head_dim,
                   device=device, dtype=torch.float16)
    k = torch.randn(batch_size * seq_len, num_heads, head_dim,
                   device=device, dtype=torch.float16)
    v = torch.randn(batch_size * seq_len, num_heads, head_dim,
                   device=device, dtype=torch.float16)
    
    # Warmup
    for _ in range(10):
        output = xops.memory_efficient_attention(q, k, v)
    
    torch.cuda.synchronize()
    
    # Benchmark
    start_time = time.time()
    
    for _ in range(iterations):
        output = xops.memory_efficient_attention(q, k, v)
    
    torch.cuda.synchronize()
    elapsed_time = time.time() - start_time
    
    # Memory usage
    memory_mb = torch.cuda.max_memory_allocated() / 1024**2
    torch.cuda.reset_peak_memory_stats()
    
    return elapsed_time, memory_mb

def run_benchmarks():
    """Run comprehensive benchmarks"""
    
    if not check_environment():
        return
    
    print("\n🚀 Running Attention Benchmarks for WAN2.2")
    print("=" * 60)
    
    # Test configurations
    configs = [
        {"name": "Small", "batch": 1, "seq_len": 512, "dim": 768, "heads": 12},
        {"name": "Medium", "batch": 2, "seq_len": 1024, "dim": 1024, "heads": 16},
        {"name": "Large", "batch": 4, "seq_len": 2048, "dim": 1280, "heads": 20},
        {"name": "WAN2.2 Video", "batch": 1, "seq_len": 4096, "dim": 1536, "heads": 24},
    ]
    
    results = []
    
    for config in configs:
        print(f"\n📊 Testing {config['name']} Configuration")
        print(f"  Batch: {config['batch']}, Seq: {config['seq_len']}, "
              f"Dim: {config['dim']}, Heads: {config['heads']}")
        print("-" * 40)
        
        # Standard Attention
        print("  Testing Standard Attention...", end=" ")
        std_time, std_mem = benchmark_standard_attention(
            batch_size=config['batch'],
            seq_len=config['seq_len'],
            dim=config['dim'],
            num_heads=config['heads'],
            iterations=50
        )
        print(f"✓ {std_time:.2f}s, {std_mem:.0f}MB")
        
        # Flash Attention
        print("  Testing Flash Attention...", end=" ")
        flash_time, flash_mem = benchmark_flash_attention(
            batch_size=config['batch'],
            seq_len=config['seq_len'],
            dim=config['dim'],
            num_heads=config['heads'],
            iterations=50
        )
        
        if flash_time != float('inf'):
            print(f"✓ {flash_time:.2f}s, {flash_mem:.0f}MB")
            flash_speedup = std_time / flash_time
            flash_memory_saved = (std_mem - flash_mem) / std_mem * 100
        else:
            print("✗ Not available")
            flash_speedup = 0
            flash_memory_saved = 0
        
        # xFormers
        print("  Testing xFormers...", end=" ")
        xf_time, xf_mem = benchmark_xformers_attention(
            batch_size=config['batch'],
            seq_len=config['seq_len'],
            dim=config['dim'],
            num_heads=config['heads'],
            iterations=50
        )
        
        if xf_time != float('inf'):
            print(f"✓ {xf_time:.2f}s, {xf_mem:.0f}MB")
            xf_speedup = std_time / xf_time
            xf_memory_saved = (std_mem - xf_mem) / std_mem * 100
        else:
            print("✗ Not available")
            xf_speedup = 0
            xf_memory_saved = 0
        
        # Store results
        results.append({
            "config": config['name'],
            "standard": {"time": std_time, "memory": std_mem},
            "flash": {"time": flash_time, "memory": flash_mem, 
                     "speedup": flash_speedup, "memory_saved": flash_memory_saved},
            "xformers": {"time": xf_time, "memory": xf_mem,
                        "speedup": xf_speedup, "memory_saved": xf_memory_saved}
        })
    
    # Summary
    print("\n" + "=" * 60)
    print("📈 BENCHMARK SUMMARY")
    print("=" * 60)
    
    for result in results:
        print(f"\n{result['config']} Configuration:")
        
        if result['flash']['speedup'] > 0:
            print(f"  Flash Attention: {result['flash']['speedup']:.2f}x faster, "
                  f"{result['flash']['memory_saved']:.1f}% memory saved")
        
        if result['xformers']['speedup'] > 0:
            print(f"  xFormers: {result['xformers']['speedup']:.2f}x faster, "
                  f"{result['xformers']['memory_saved']:.1f}% memory saved")
    
    # Recommendations
    print("\n" + "=" * 60)
    print("💡 RECOMMENDATIONS FOR WAN2.2")
    print("=" * 60)
    
    best_option = "Standard"
    best_speedup = 1.0
    
    if results[-1]['flash']['speedup'] > best_speedup:
        best_option = "Flash Attention"
        best_speedup = results[-1]['flash']['speedup']
    
    if results[-1]['xformers']['speedup'] > best_speedup:
        best_option = "xFormers"
        best_speedup = results[-1]['xformers']['speedup']
    
    print(f"\n✅ Best option for WAN2.2: {best_option}")
    print(f"   Expected speedup: {best_speedup:.2f}x")
    print(f"\n🎯 For RTX 3090 (24GB VRAM):")
    print("   - Use Flash Attention for maximum speed")
    print("   - Enable FP16 for memory efficiency")
    print("   - Use VAE slicing for large resolutions")
    print("   - Enable torch.compile for additional speedup")

if __name__ == "__main__":
    run_benchmarks()