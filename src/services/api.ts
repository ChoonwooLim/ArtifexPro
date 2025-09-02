/**
 * API 서비스 - 백엔드와 통신
 */

const API_BASE = 'http://localhost:8000';

export interface Job {
  id: string;
  type: 'ti2v' | 's2v';
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
  };
  created_at: string;
  completed_at?: string;
  error?: string;
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
}

export const apiService = new APIService();