#!/bin/bash

# Start Ray Cluster for Dual GPU on Pop!_OS
# Optimized for 2x RTX 3090 (48GB total VRAM)

echo "🚀 Starting Ray Cluster for Dual RTX 3090"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check GPUs
echo -e "${GREEN}Checking GPUs...${NC}"
nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader

# Kill existing Ray processes
echo -e "${YELLOW}Cleaning up existing Ray processes...${NC}"
ray stop --force 2>/dev/null || true
sleep 2

# Start Ray head node with optimized settings
echo -e "${GREEN}Starting Ray head node...${NC}"

# Calculate resources (2 GPUs, leave some CPU for system)
NUM_CPUS=$(nproc --ignore=2)
NUM_GPUS=2

# Start Ray with specific configuration
ray start --head \
    --port=6379 \
    --dashboard-host=0.0.0.0 \
    --dashboard-port=8265 \
    --num-cpus=$NUM_CPUS \
    --num-gpus=$NUM_GPUS \
    --object-store-memory=10000000000 \
    --node-ip-address=192.168.1.100 \
    --include-dashboard=true

# Check Ray status
sleep 3
ray status

echo -e "${GREEN}✅ Ray cluster started successfully!${NC}"
echo ""
echo "Dashboard: http://192.168.1.100:8265"
echo "Head node: ray://192.168.1.100:10001"
echo ""
echo "GPU Memory Distribution:"
echo "  - GPU 0: 24GB (Primary)"
echo "  - GPU 1: 24GB (Secondary)"
echo "  - Total: 48GB available for WAN2.2"
echo ""
echo -e "${YELLOW}To connect from Windows:${NC}"
echo "  ray.init('ray://192.168.1.100:10001')"
echo ""

# Create Python test script
cat > /tmp/test_ray_gpus.py << 'EOF'
import ray
import torch

ray.init(address='ray://localhost:10001')

@ray.remote(num_gpus=1)
def check_gpu(gpu_id):
    import torch
    device = torch.device(f'cuda:{gpu_id}')
    gpu_name = torch.cuda.get_device_name(device)
    memory_total = torch.cuda.get_device_properties(device).total_memory / 1024**3
    return f"GPU {gpu_id}: {gpu_name}, {memory_total:.1f}GB"

# Test both GPUs
futures = [check_gpu.remote(i) for i in range(2)]
results = ray.get(futures)

print("\n✅ Ray GPU Test Results:")
for result in results:
    print(f"  {result}")

ray.shutdown()
EOF

# Test Ray GPUs
echo -e "${GREEN}Testing Ray GPU access...${NC}"
python3 /tmp/test_ray_gpus.py

echo -e "${GREEN}Ray cluster is ready for WAN2.2!${NC}"