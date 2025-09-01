# DualPC 구축전략 (업그레이드 에디션)

## 📋 목차
1. [개요](#개요)
2. [아키텍처 개요](#아키텍처-개요)
3. [하드웨어 및 예산](#하드웨어-및-예산)
4. [네트워크 구성 (10GbE 직결)](#네트워크-구성-10gbe-직결)
5. [파일 공유 (NFSv4/대안 SMB)](#파일-공유-nfsv4대안-smb)
6. [소프트웨어 설치](#소프트웨어-설치)
7. [Ray 클러스터 구성](#ray-클러스터-구성)
8. [GPU 작업 스케줄링/배치 처리](#gpu-작업-스케줄링배치-처리)
9. [성능 최적화](#성능-최적화)
10. [모니터링/로그 수집](#모니터링로그-수집)
11. [운영 체크리스트](#운영-체크리스트)
12. [트러블슈팅](#트러블슈팅)
13. [자동화 스크립트 샘플](#자동화-스크립트-샘플)
14. [부록: 포트/방화벽, 보안 권장사항](#부록-포트방화벽-보안-권장사항)

---

## 개요

### 목표
ArtifexPro 프로젝트를 위해 2대의 RTX 3090 PC를 10Gbps 직결로 연결하여, 분산 추론/후처리를 안정적으로 수행하는 듀얼 PC 클러스터를 구축합니다.

### 성공 기준
- 생성/렌더 처리량: 최소 1.8×, 일반적 2.0×까지 향상
- 단일 작업 지연: 네트워크 왕복 < 0.5ms, 파일 공유 대역폭 ≥ 9.4 Gbps
- VRAM 총합 활용: 48 GB 안정적 사용 (메모리 파편화 방지)
- 자동화: 1회 스크립트 실행으로 클러스터 구동/상태 점검 가능

---

## 아키텍처 개요

### 논리 구조
```mermaid
graph LR
  subgraph PC1[Linux Server]
    A[Ray Head + Ray Client Server\nCUDA 12.1 + PyTorch\nNFSv4 Server] -->|Jobs| M1[Wan2.2 Model Server]
    A -->|Metrics| D1[Ray Dashboard]
  end
  subgraph PC2[Windows Main]
    B[Ray Worker Client] -->|Tasks| P1[Post-Processor (Upscale/NVENC)]
    B -->|I/O| MNT[Projects/Cache Mount]
  end
  A <-.10GbE Direct Cat6a.-> B
  MNT -.NFSv4/SMB.-> A
```

### 데이터 흐름
- PC2에서 생성 요청 → Ray Client를 통해 PC1의 모델 서버로 전달
- 생성 결과 프레임/비디오 → PC2로 스트리밍/공유 디렉토리 저장
- PC2에서 업스케일/인코딩 → 결과물을 공유 디렉토리에 기록

### 포트/서비스
- Ray GCS: 6379 (TCP)
- Ray Client Server: 10001 (TCP)
- Ray Dashboard: 8265 (TCP)
- NFSv4: 2049 (TCP/UDP), 필요시 rpcbind: 111 (TCP/UDP)

---

## 하드웨어 및 예산

### BOM (Bill of Materials)

| 항목 | 권장 모델 | 수량 | 단가(원) | 합계(원) | 비고 |
|---|---|---:|---:|---:|---|
| 10GbE NIC | Intel X550-T2 (Dell OEM) | 2 | 120,000 | 240,000 | 듀얼 포트, 브래킷/정상 동작 확인 |
| 케이블 | CAT6a STP 차폐 3m | 1 | 10,000 | 10,000 | 직결 권장, 5m 이하 |
| 쿨링 | 40mm 팬 2개 + 방열판 | 1 | 15,000 | 15,000 | 여름 대비 |
| 예비 | 여분 케이블/커넥터 | 1 | 30,000 | 30,000 | 선택 |
| 합계 |  |  |  | 295,000 | (대략) |

체크사항
- 브래킷 규격(저/표준 높이) 포함 여부 확인
- NIC 포트 2개 모두 링크 업 테스트
- 정품 칩셋(X550) 확인, 발열 관리(에어플로우) 고려

---

## 네트워크 구성 (10GbE 직결)

### PC1 (Ubuntu 22.04) 고정 IP + 튜닝
```bash
# 인터페이스 확인
lspci | grep Ethernet
ip link show

# Netplan (예: enp3s0f0 사용)
sudo nano /etc/netplan/01-10gbe.yaml

network:
  version: 2
  renderer: networkd
  ethernets:
    enp3s0f0:
      addresses: [10.0.0.1/24]
      mtu: 9000
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

sudo netplan apply

# 10GbE 튜닝 스크립트
cat > ~/network_optimize.sh << 'EOF'
#!/bin/bash
IFACE="enp3s0f0"
sudo ip link set $IFACE mtu 9000
sudo ethtool -G $IFACE rx 4096 tx 4096
sudo ethtool -K $IFACE tso on gso on gro on lro on
sudo ethtool -C $IFACE adaptive-rx on adaptive-tx on
sudo ethtool -L $IFACE combined 8
echo "Network optimization complete!"
EOF
chmod +x ~/network_optimize.sh && ./network_optimize.sh

# 시스템 전역 튜닝
sudo tee -a /etc/sysctl.conf > /dev/null << 'EOF'
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
EOF
sudo sysctl -p
```

### PC2 (Windows 11) 고정 IP + 고급 설정 (PowerShell 관리자)
```powershell
Get-NetAdapter | ft Name, InterfaceDescription, LinkSpeed

# IP (예: 보조 NIC 이름이 "Ethernet 2")
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 10.0.0.2 -PrefixLength 24

# Jumbo Frames
Set-NetAdapterAdvancedProperty -Name "Ethernet 2" -DisplayName "Jumbo Packet" -DisplayValue "9014"

# Buffers
Set-NetAdapterAdvancedProperty -Name "Ethernet 2" -DisplayName "Receive Buffers" -DisplayValue "4096"
Set-NetAdapterAdvancedProperty -Name "Ethernet 2" -DisplayName "Transmit Buffers" -DisplayValue "4096"

# RSS
Set-NetAdapterRss -Name "Ethernet 2" -Enabled $True -NumberOfReceiveQueues 8

# 연결 테스트
ping 10.0.0.1 -l 8000 -f
```

### 대역폭 검증 (iperf3)
```bash
# PC1 (Linux):
iperf3 -s

# PC2 (Windows):
iperf3.exe -c 10.0.0.1 -P 4 -t 30
# 기대치: 9.4+ Gbps
```

---

## 파일 공유 (NFSv4/대안 SMB)

권장 기본: NFSv4 (Windows 클라이언트 호환성 강화를 위해 exports 옵션 보강). 필요 시 SMB 대안을 병행 제공합니다.

### PC1 (Ubuntu) NFSv4 서버
```bash
sudo apt install -y nfs-kernel-server

# NFSv4 루트 구성
sudo mkdir -p /exports/projects /exports/cache /exports/models
sudo mkdir -p /data/projects /data/cache /data/models
sudo mount --bind /data/projects /exports/projects
sudo mount --bind /data/cache /exports/cache
sudo mount --bind /data/models /exports/models

sudo tee /etc/exports > /dev/null << 'EOF'
/exports/projects 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash,insecure)
/exports/cache    10.0.0.0/24(rw,async,no_subtree_check,no_root_squash,insecure)
/exports/models   10.0.0.0/24(ro,sync,no_subtree_check,insecure)
EOF

sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

주의: Windows NFS 클라이언트는 비특권 포트를 사용하는 경우가 있어 `insecure` 옵션을 지정해야 연결 문제가 줄어듭니다.

### PC2 (Windows) NFS 클라이언트
```powershell
Enable-WindowsOptionalFeature -FeatureName NFS-Client -Online
Restart-Computer

# 재부팅 후 마운트 (NFSv4 UNC 경로)
mount -o anon \\10.0.0.1\\exports\\projects P:
mount -o anon \\10.0.0.1\\exports\\cache Z:
```

### 대안: SMB 공유 (호환/권한 관리 용이)
```bash
# PC1에 SMB 설치
sudo apt install -y samba

sudo tee -a /etc/samba/smb.conf > /dev/null << 'EOF'
[projects]
   path = /data/projects
   read only = no
   browsable = yes

[cache]
   path = /data/cache
   read only = no
   browsable = yes
EOF

sudo systemctl restart smbd
```
Windows 연결: 파일 탐색기에서 `\\10.0.0.1\projects` 로 접속 (자격증명 필요 시 로컬 유저/암호 사용).

---

## 소프트웨어 설치

### PC1 (Linux)
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl wget htop nvtop iotop python3.10 python3.10-venv python3-pip

# CUDA 12.1 (필요 시)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update && sudo apt-get -y install cuda-12-1

# Python venv
python3.10 -m venv ~/artifex_env
source ~/artifex_env/bin/activate
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install ray[default]==2.9.0 fastapi uvicorn redis numpy scipy pandas wandb tensorboard
```

Wan2.2 모델 디렉토리 구성(예시)
```bash
mkdir -p ~/models ~/projects ~/cache
ln -s /path/to/Wan2.2-T2V-A14B ~/models/
ln -s /path/to/Wan2.2-I2V-A14B ~/models/
```

### PC2 (Windows)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y git nodejs python vscode

pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install ray[default]==2.9.0 numpy pandas
```

---

## Ray 클러스터 구성

### PC1: Ray Head + Client Server
```bash
# venv 활성화 후 실행
source ~/artifex_env/bin/activate

ray stop || true
ray start --head \
  --port=6379 \
  --ray-client-server-port=10001 \
  --dashboard-host=0.0.0.0 \
  --dashboard-port=8265 \
  --num-gpus=1 \
  --object-store-memory=50000000000 \
  --block
```

모델 서버(예시)
```python
# ~/model_server.py
import ray

@ray.remote(num_gpus=1, name="wan22_model_server")
class Wan22ModelServer:
    def __init__(self):
        # 실제 모델 로딩 코드를 연결
        self.ready = True
    def generate_t2v(self, prompt: str, **kwargs):
        return {"prompt": prompt, "result": "video_placeholder"}

if __name__ == "__main__":
    ray.init(address="ray://0.0.0.0:10001")
    server = Wan22ModelServer.remote()
    print("Model server ready")
```

### PC2: Ray Client 연결 + 후처리 워커
```python
# post_processor.py (Windows)
import ray

ray.init(address='ray://10.0.0.1:10001')

@ray.remote(num_gpus=1, name="windows_gpu_worker")
class PostProcessor:
    def upscale(self, video_tensor):
        return "upscaled"
    def encode_nvenc(self, frames, codec='h265'):
        return f"encoded_{codec}"
```

연결 확인
```bash
# 브라우저에서 Ray Dashboard 접속
http://10.0.0.1:8265
```

---

## GPU 작업 스케줄링/배치 처리

스케줄러 개념
```python
# scheduler.py
import ray, time, uuid
from enum import Enum

class TaskType(Enum):
    GENERATION = "generation"
    POST_PROCESS = "post_process"
    ENCODING = "encoding"

class DualGPUScheduler:
    def __init__(self):
        self.linux_server = ray.get_actor("wan22_model_server")
        self.windows_worker = ray.get_actor("windows_gpu_worker")
        self.task_mapping = {
            "t2v-A14B": (self.linux_server, TaskType.GENERATION),
            "i2v-A14B": (self.linux_server, TaskType.GENERATION),
            "upscale": (self.windows_worker, TaskType.POST_PROCESS),
            "encode": (self.windows_worker, TaskType.ENCODING),
        }
    async def submit_job(self, job):
        actor, category = self.task_mapping.get(job['type'], (self.linux_server, TaskType.GENERATION))
        result_ref = actor.generate_t2v.remote(job.get('prompt', '')) if category==TaskType.GENERATION else actor.encode_nvenc.remote(job, 'h265')
        return result_ref

class BatchProcessor:
    def __init__(self, batch_size=4, timeout=30):
        self.batch_size = batch_size
        self.timeout = timeout
        self.pending_jobs = []
        self.last_batch_time = time.time()
    def add_job(self, job):
        self.pending_jobs.append(job)
        if self._should_process_batch():
            return self._create_batch()
    def _should_process_batch(self):
        return len(self.pending_jobs) >= self.batch_size or time.time() - self.last_batch_time > self.timeout
    def _create_batch(self):
        batch = self.pending_jobs[:self.batch_size]
        self.pending_jobs = self.pending_jobs[self.batch_size:]
        self.last_batch_time = time.time()
        return { 'jobs': batch, 'batch_id': str(uuid.uuid4()), 'created_at': time.time() }
```

---

## 성능 최적화

1) GPU 메모리/연산
```python
# gpu_memory_manager.py
import torch, gc

class GPUMemoryManager:
    def __init__(self, device='cuda:0'):
        self.device = device
    def optimize(self):
        gc.collect(); torch.cuda.empty_cache()
        torch.backends.cudnn.benchmark = True
        try:
            torch.set_float32_matmul_precision("high")
        except Exception:
            pass
    def set_fraction(self, fraction=0.9):
        torch.cuda.set_per_process_memory_fraction(fraction, self.device)
```

2) 네트워크 소켓 옵션
```python
# network_optimizer.py
import socket
class NetworkOptimizer:
    OPTS = { socket.SO_RCVBUF: 128*1024*1024, socket.SO_SNDBUF: 128*1024*1024, socket.TCP_NODELAY: 1 }
    def apply(self, sock):
        for k, v in self.OPTS.items():
            level = socket.IPPROTO_TCP if k==socket.TCP_NODELAY else socket.SOL_SOCKET
            sock.setsockopt(level, k, v)
```

3) 캐싱 전략 (Redis + 파일)
```python
# cache_manager.py
import redis, pickle, hashlib
from pathlib import Path
class DistributedCache:
    def __init__(self):
        self.redis_local = redis.Redis(host='localhost', port=6379)
        self.cache_dir = Path('/data/cache')
    def key(self, params: dict):
        return hashlib.md5(str(sorted(params.items())).encode()).hexdigest()
    def set(self, key, data, ttl=3600):
        payload = pickle.dumps(data)
        if len(payload) < 100*1024*1024:
            self.redis_local.setex(key, ttl, payload)
        else:
            (self.cache_dir / f"{key}.pkl").write_bytes(payload)
```

4) 디스크 I/O
- NVMe 사용, 파일 청크 쓰기(≥ 8MB), 병렬 스트림 수 `-P 4~8` 검증

---

## 모니터링/로그 수집

### 실시간 대시보드 (CLI)
```python
# monitor.py
import psutil, GPUtil, time
from rich.console import Console
from rich.table import Table

class SystemMonitor:
    def __init__(self):
        self.c = Console()
    def gpu(self):
        rows = []
        for g in GPUtil.getGPUs():
            rows.append((g.name, f"{g.load*100:.1f}%", f"{g.memoryUsed}/{g.memoryTotal}MB", f"{g.temperature}C"))
        return rows
    def net(self):
        io = psutil.net_io_counters()
        return (io.bytes_sent, io.bytes_recv)
    def render(self):
        t = Table(title="ArtifexPro Cluster Monitor")
        t.add_column("GPU"); t.add_column("Load"); t.add_column("Mem"); t.add_column("Temp")
        for n,l,m,tp in self.gpu():
            t.add_row(n,l,m,tp)
        self.c.print(t)
```

### 로그 집계 (Linux)
```bash
#!/bin/bash
LOG_DIR="/var/log/artifexpro"; mkdir -p $LOG_DIR
cp /tmp/ray/session_latest/logs/* $LOG_DIR/ 2>/dev/null || true
journalctl -u artifexpro > $LOG_DIR/system.log
nvidia-smi dmon -s pucmem -d 60 -o TD -f $LOG_DIR/gpu_dmon.log &
```

---

## 운영 체크리스트

- [ ] 케이블/포트 링크 업(10,000 Mb/s) 및 MTU 9000 양단 적용
- [ ] iperf3 ≧ 9.4 Gbps
- [ ] NFS/SMB 마운트 및 R/W 성능 점검(대용량 단일 파일/다수 파일)
- [ ] Ray Head(6379,10001), Dashboard(8265) 접근 확인
- [ ] 모델 서버/워커 정상 등록 및 샘플 잡 수행

---

## 트러블슈팅

네트워크
```bash
ping -c 4 10.0.0.1
ethtool enp3s0f0 | grep Speed   # 10000Mb/s 확인
ip link show enp3s0f0 | grep mtu # 9000 확인
iperf3 -c 10.0.0.1 -P 4
```

GPU
```bash
nvidia-smi
nvcc --version
python -c "import torch; print(torch.cuda.is_available())"
```

Ray
```bash
ray status
ray stop; ray start --head --port=6379 --ray-client-server-port=10001
tail -f /tmp/ray/session_latest/logs/gcs_server.out
```

NFS
```bash
sudo systemctl status nfs-kernel-server
showmount -e 10.0.0.1
sudo mount -t nfs4 10.0.0.1:/exports/projects /mnt/test
```

---

## 자동화 스크립트 샘플

디렉토리 제안
```
scripts/
  setup_network.sh
  install_software.sh
  start_ray.sh
  start_model_server.sh
  start_monitoring.sh
tools/
  check_status.py
```

메인 설치 스크립트
```bash
#!/bin/bash
echo "ArtifexPro Dual PC Cluster Setup"
export ARTIFEX_HOME="/opt/artifexpro"
export RAY_ADDRESS="10.0.0.1:6379"
./scripts/setup_network.sh && ./scripts/install_software.sh && ./scripts/start_ray.sh && ./scripts/start_model_server.sh && ./scripts/start_monitoring.sh
echo "Setup complete!"
```

상태 점검 스크립트
```python
#!/usr/bin/env python3
import ray, subprocess
def check(cmd):
    return subprocess.run(cmd, capture_output=True).returncode == 0
def ok(x):
    return '✓' if x else '✗'
print("System Status\n==============")
print("Network:", ok(check(['ping','-c','1','10.0.0.1'])))
try:
    ray.init(address='ray://10.0.0.1:10001'); rc=True
except Exception:
    rc=False
print("Ray:", ok(rc))
print("GPU:", ok(check(['nvidia-smi'])))
```

---

## 부록: 포트/방화벽, 보안 권장사항

방화벽
- Linux(UFW): 6379/TCP, 10001/TCP, 8265/TCP, 2049/TCP-UDP, 111/TCP-UDP 허용
- Windows Defender 방화벽: 10001/TCP 아웃바운드 허용, iperf3 테스트 허용

보안
- 내부 전용망 전제. 외부 공개 금지, 필요시 WireGuard 등으로 터널링
- SMB 사용 시 읽기 전용 공유 분리, NFS `ro`로 모델 디렉토리 제공
- Ray Client 포트(10001)는 신뢰 네트워크로 제한

마치며
- 본 개편본은 포트/마운트/클라이언트 포트(10001) 설정을 정합화하고, Windows NFS 호환성을 높이기 위해 NFSv4 루트 구조와 `insecure` 옵션을 추가했습니다. 운영 체크리스트와 자동화 샘플을 통해 1회 스크립트 구동으로 환경 점검까지 가능하도록 정리했습니다.
