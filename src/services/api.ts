/**
 * API 서비스 - 백엔드와 통신
 */

const API_BASE = 'http://localhost:8001';
const DISTRIBUTED_API_BASE = 'http://localhost:8003'; // 분산 GPU API
const POPOS_API_BASE = 'http://10.0.0.2:8002'; // Pop!_OS GPU 서버

export interface Job {
  id: string;
  type: 'ti2v' | 's2v' | 'ti2v_distributed';
  status: 'processing' | 'completed' | 'failed';
  progress: number;
  message?: string;
  output?: {
    video_url: string;
    thumbnail_url?: string;
    duration: number;
    resolution?: string;
    fps?: number;
    size_mb?: number;
    mode?: string; // 'distributed_2_gpu', 'single_gpu' 등
  };
  created_at: string;
  completed_at?: string;
  error?: string;
  // 분산 처리 관련 필드
  use_distributed?: boolean;
  backends_used?: string[];
  distributed_results?: any;
}

export interface ModelInfo {
  name: string;
  status: string;
  vram_required: string;
  capabilities: string[];
}

class APIService {
  /**
   * TI2V 생성 요청
   */
  async generateTI2V(
    imageFile: File,
    prompt: string,
    duration: number = 5,
    quality: string = 'balanced'
  ): Promise<{ job_id: string }> {
    const formData = new FormData();
    formData.append('image', imageFile);
    formData.append('prompt', prompt);
    formData.append('duration', duration.toString());
    formData.append('quality', quality);

    const response = await fetch(`${API_BASE}/api/ti2v/generate`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Failed to start TI2V generation: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * S2V 생성 요청
   */
  async generateS2V(
    audioFile: File,
    style: string = 'cinematic',
    duration?: number
  ): Promise<{ job_id: string }> {
    const formData = new FormData();
    formData.append('audio', audioFile);
    formData.append('style', style);
    if (duration) {
      formData.append('duration', duration.toString());
    }

    const response = await fetch(`${API_BASE}/api/s2v/generate`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Failed to start S2V generation: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 작업 상태 조회
   */
  async getJobStatus(jobId: string): Promise<Job> {
    const response = await fetch(`${API_BASE}/api/job/${jobId}`);
    
    if (!response.ok) {
      throw new Error(`Failed to get job status: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 작업 상태 폴링
   */
  async pollJobStatus(
    jobId: string,
    onProgress?: (job: Job) => void,
    interval: number = 1000
  ): Promise<Job> {
    return new Promise((resolve, reject) => {
      const poll = async () => {
        try {
          const job = await this.getJobStatus(jobId);
          
          if (onProgress) {
            onProgress(job);
          }

          if (job.status === 'completed') {
            resolve(job);
          } else if (job.status === 'failed') {
            reject(new Error(job.error || 'Job failed'));
          } else {
            setTimeout(poll, interval);
          }
        } catch (error) {
          reject(error);
        }
      };

      poll();
    });
  }

  /**
   * 모든 작업 목록
   */
  async listJobs(): Promise<Job[]> {
    const response = await fetch(`${API_BASE}/api/jobs`);
    
    if (!response.ok) {
      throw new Error(`Failed to list jobs: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 사용 가능한 모델 정보
   */
  async getModels(): Promise<{ ti2v: ModelInfo; s2v: ModelInfo }> {
    const response = await fetch(`${API_BASE}/api/models`);
    
    if (!response.ok) {
      throw new Error(`Failed to get models: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 시스템 상태
   */
  async getSystemStatus(): Promise<any> {
    const response = await fetch(`${API_BASE}/api/system/status`);
    
    if (!response.ok) {
      throw new Error(`Failed to get system status: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 파일 업로드
   */
  async uploadFile(file: File): Promise<{ file_id: string; url: string }> {
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch(`${API_BASE}/api/upload`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Failed to upload file: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 비디오 다운로드 URL 생성
   */
  getVideoUrl(path: string): string {
    return `${API_BASE}${path}`;
  }

  /**
   * AutoShorts 생성 요청
   */
  async generateAutoShorts(
    script: string,
    platform: string = 'tiktok',
    style: string = 'engaging',
    duration: number = 60
  ): Promise<{ job_id: string }> {
    const formData = new FormData();
    formData.append('script', script);
    formData.append('platform', platform);
    formData.append('style', style);
    formData.append('duration', duration.toString());

    const response = await fetch(`${API_BASE}/api/autoshorts/generate`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Failed to start AutoShorts generation: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * AI Chat
   */
  async sendChatMessage(message: string): Promise<{ response: string; history: any[] }> {
    const formData = new FormData();
    formData.append('message', message);

    const response = await fetch(`${API_BASE}/api/chat`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Failed to send chat message: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 텍스트 번역 (한글 → 영어)
   */
  async translateText(text: string, targetLang: string = 'en'): Promise<{ 
    original: string; 
    translated: string; 
    language: string;
  }> {
    const formData = new FormData();
    formData.append('text', text);
    formData.append('target_lang', targetLang);

    const response = await fetch(`${API_BASE}/api/translate`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Failed to translate text: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 분산 GPU 상태 확인
   */
  async getDistributedGpuStatus(): Promise<any> {
    const response = await fetch(`${DISTRIBUTED_API_BASE}/api/gpu/status`);
    
    if (!response.ok) {
      throw new Error(`Failed to get distributed GPU status: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 분산 GPU 시스템 정보
   */
  async getDistributedSystemInfo(): Promise<any> {
    const response = await fetch(`${DISTRIBUTED_API_BASE}/`);
    
    if (!response.ok) {
      throw new Error(`Failed to get distributed system info: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 분산 TI2V 생성 요청 (Windows + Pop!_OS)
   */
  async generateDistributedTI2V(
    imageFile: File | null,
    prompt: string,
    duration: number = 5,
    quality: string = 'balanced',
    useDistributed: boolean = true
  ): Promise<{ job_id: string; distributed: boolean; backends: number }> {
    const formData = new FormData();
    
    if (imageFile) {
      formData.append('image', imageFile);
    } else {
      // 더미 파일 추가 (백엔드에서 처리)
      const dummyFile = new File([''], 'dummy.txt', { type: 'text/plain' });
      formData.append('image', dummyFile);
    }
    
    formData.append('prompt', prompt);
    formData.append('duration', duration.toString());
    formData.append('quality', quality);
    formData.append('use_distributed', useDistributed.toString());

    const response = await fetch(`${DISTRIBUTED_API_BASE}/api/ti2v/generate`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Failed to start distributed TI2V generation: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 분산 작업 상태 조회
   */
  async getDistributedJobStatus(jobId: string): Promise<Job> {
    const response = await fetch(`${DISTRIBUTED_API_BASE}/api/job/${jobId}`);
    
    if (!response.ok) {
      throw new Error(`Failed to get distributed job status: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * 분산 작업 상태 폴링
   */
  async pollDistributedJobStatus(
    jobId: string,
    onProgress?: (job: Job) => void,
    interval: number = 1000
  ): Promise<Job> {
    return new Promise((resolve, reject) => {
      const poll = async () => {
        try {
          const job = await this.getDistributedJobStatus(jobId);
          
          if (onProgress) {
            onProgress(job);
          }

          if (job.status === 'completed') {
            resolve(job);
          } else if (job.status === 'failed') {
            reject(new Error(job.error || 'Distributed job failed'));
          } else {
            setTimeout(poll, interval);
          }
        } catch (error) {
          reject(error);
        }
      };

      poll();
    });
  }

  /**
   * 분산 비디오 다운로드 URL 생성
   */
  getDistributedVideoUrl(path: string): string {
    return `${DISTRIBUTED_API_BASE}${path}`;
  }
}

export const apiService = new APIService();