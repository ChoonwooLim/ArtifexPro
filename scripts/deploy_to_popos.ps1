# Deploy ArtifexPro to Pop!_OS with Flash Attention
# PowerShell script for Windows to deploy to Pop!_OS

Write-Host "🚀 Deploying ArtifexPro to Pop!_OS with Flash Attention..." -ForegroundColor Cyan

# Configuration
$PopOSHost = "192.168.1.100"
$PopOSUser = "stevenlim"
$RemotePath = "/home/stevenlim/ArtifexPro"

# Files to deploy
$FilesToDeploy = @(
    "backend/wan22_optimized.py",
    "backend/ray_cluster_manager.py",
    "scripts/setup_flash_attention_popos.sh",
    "scripts/start_ray_cluster.sh",
    "requirements.txt"
)

# Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
$TempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }

foreach ($file in $FilesToDeploy) {
    $destPath = Join-Path $TempDir $file
    $destDir = Split-Path $destPath -Parent
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item -Path $file -Destination $destPath -Force
}

# Create requirements.txt if not exists
$RequirementsPath = Join-Path $TempDir "requirements.txt"
if (!(Test-Path $RequirementsPath)) {
    @"
# WAN2.2 Optimized Requirements
torch>=2.4.0
torchvision
torchaudio
flash-attn>=2.5.0
xformers>=0.0.23
diffusers>=0.25.0
transformers>=4.36.0
accelerate>=0.25.0
safetensors>=0.4.0
omegaconf>=2.3.0
einops>=0.7.0
imageio-ffmpeg>=0.4.9
opencv-python-headless>=4.8.0
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
python-multipart>=0.0.6
aiofiles>=23.0.0
ray[default]>=2.9.0
deepspeed>=0.12.0
bitsandbytes>=0.41.0
triton>=2.1.0
peft>=0.7.0
numpy<2.0.0
pillow>=10.0.0
tqdm>=4.66.0
psutil>=5.9.0
"@ | Out-File -FilePath $RequirementsPath -Encoding UTF8
}

# Create setup script
$SetupScriptPath = Join-Path $TempDir "setup_and_run.sh"
@'
#!/bin/bash
# Setup and run WAN2.2 with Flash Attention

echo "🚀 Setting up WAN2.2 with Flash Attention on Pop!_OS"
echo "============================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Navigate to ArtifexPro directory
cd ~/ArtifexPro

# Make scripts executable
chmod +x scripts/*.sh

# Run Flash Attention setup
echo -e "${GREEN}Setting up Flash Attention...${NC}"
bash scripts/setup_flash_attention_popos.sh

# Start Ray cluster
echo -e "${GREEN}Starting Ray cluster...${NC}"
bash scripts/start_ray_cluster.sh

# Start the optimized backend
echo -e "${GREEN}Starting WAN2.2 optimized backend...${NC}"
source venv/bin/activate
python backend/wan22_optimized.py

echo -e "${GREEN}✅ Setup complete!${NC}"
'@ | Out-File -FilePath $SetupScriptPath -Encoding UTF8 -NoNewline

# Deploy to Pop!_OS
Write-Host "🚢 Deploying to Pop!_OS..." -ForegroundColor Green

# Create remote directory
ssh "${PopOSUser}@${PopOSHost}" "mkdir -p $RemotePath"

# Copy files
scp -r "$TempDir/*" "${PopOSUser}@${PopOSHost}:${RemotePath}/"

# Run setup
Write-Host "🔧 Running setup on Pop!_OS..." -ForegroundColor Cyan
ssh "${PopOSUser}@${PopOSHost}" "cd $RemotePath && chmod +x setup_and_run.sh && ./setup_and_run.sh"

# Cleanup
Remove-Item -Path $TempDir -Recurse -Force

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "📡 WAN2.2 backend running at: http://${PopOSHost}:8001" -ForegroundColor Yellow
Write-Host "🎮 Ray dashboard available at: http://${PopOSHost}:8265" -ForegroundColor Yellow