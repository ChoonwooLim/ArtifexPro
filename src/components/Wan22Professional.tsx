import React, { useState, useEffect, useRef, useCallback } from 'react';
import { 
  Upload, Input, Select, Button, Progress, Card, Space, Typography, 
  Slider, Switch, Tooltip, Tag, Radio, InputNumber, App, Tabs
} from 'antd';
import { 
  PlayCircleOutlined, StopOutlined, SaveOutlined,
  InfoCircleOutlined,
  AudioOutlined, PictureOutlined, TranslationOutlined
} from '@ant-design/icons';
import { apiService } from '../services/api';
import './Wan22Professional.css';

const { TextArea } = Input;
const { Option } = Select;
const { Title, Text } = Typography;
// const { TabPane } = Tabs; // Deprecated

interface ModelConfig {
  name: string;
  params: string;
  vramRequired: string;
  resolution: string[];
  features: string[];
  optimal: string;
}

const WAN22_MODELS: Record<string, ModelConfig> = {
  't2v-A14B': {
    name: 'T2V-A14B (Text to Video)',
    params: '27B MoE (14B active)',
    vramRequired: '80GB (single) / 40GB (multi)',
    resolution: ['480*832', '832*480', '1280*720', '720*1280'],
    features: ['Cinematic aesthetics', 'Complex motion', 'Prompt extension'],
    optimal: 'Professional film-quality generation'
  },
  'i2v-A14B': {
    name: 'I2V-A14B (Image to Video)',
    params: '27B MoE (14B active)',
    vramRequired: '80GB (single) / 40GB (multi)',
    resolution: ['480*832', '832*480', '1280*720', '720*1280'],
    features: ['Image animation', 'Motion control', 'Style preservation'],
    optimal: 'Product showcase, image animation'
  },
  'ti2v-5B': {
    name: 'TI2V-5B (Text OR Image to Video)',
    params: '5B Dense (4×32×32 compression)',
    vramRequired: '24GB (RTX 4090/3090)',
    resolution: ['1280*704', '704*1280', '720p@24fps'],
    features: ['T2V & I2V in one model', '9min for 5s video', 'Consumer GPU', '64x compression'],
    optimal: 'Fast prototyping on single GPU (T2V or I2V)'
  },
  's2v-14B': {
    name: 'S2V-14B (Speech to Video)',
    params: '14B',
    vramRequired: '40GB',
    resolution: ['480*832', '832*480', '1280*720', '720*1280'],
    features: ['Audio sync', 'Lip sync', 'Pose control'],
    optimal: 'Music videos, talking avatars'
  }
};

const AESTHETIC_PRESETS: Record<string, {
  lighting: string;
  composition: string;
  colorTone: string;
  contrast: string;
  saturation: string;
}> = {
  'cinematic': {
    lighting: 'Dramatic',
    composition: 'Rule of thirds',
    colorTone: 'Cinematic teal-orange',
    contrast: 'High',
    saturation: 'Medium'
  },
  'documentary': {
    lighting: 'Natural',
    composition: 'Center-weighted',
    colorTone: 'Natural',
    contrast: 'Medium',
    saturation: 'Low'
  },
  'artistic': {
    lighting: 'Creative',
    composition: 'Asymmetric',
    colorTone: 'Vibrant',
    contrast: 'Very high',
    saturation: 'High'
  },
  'commercial': {
    lighting: 'Bright and even',
    composition: 'Product-focused',
    colorTone: 'Clean whites',
    contrast: 'Medium',
    saturation: 'Enhanced'
  }
};

const Wan22Professional: React.FC = () => {
  const { message } = App.useApp();
  const [activeModel, setActiveModel] = useState<string>('ti2v-5B');
  const [isGenerating, setIsGenerating] = useState(false);
  
  // Generation parameters
  const [prompt, setPrompt] = useState('');
  const [negativePrompt, setNegativePrompt] = useState('');
  const [resolution, setResolution] = useState('1280*704');
  const [duration, setDuration] = useState(5);
  const [fps, setFps] = useState(24);
  const [steps, setSteps] = useState(50);
  const [cfgScale, setCfgScale] = useState(7.5);
  const [seed, setSeed] = useState(-1);
  
  // Advanced settings
  const [usePromptExtension, setUsePromptExtension] = useState(true);
  const [promptExtensionMethod, setPromptExtensionMethod] = useState('llm');
  const [aestheticPreset, setAestheticPreset] = useState('cinematic');
  const [motionStrength, setMotionStrength] = useState(1.0);
  const [temporalConsistency, setTemporalConsistency] = useState(0.95);
  
  // Optimization settings
  const [useOffload, setUseOffload] = useState(true);
  const [useFP16, setUseFP16] = useState(true);
  const [useFlashAttention, setUseFlashAttention] = useState(false);
  const [batchSize, setBatchSize] = useState(1);
  
  // Files
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [referenceImage, setReferenceImage] = useState<File | null>(null);
  
  // Progress
  const [progress, setProgress] = useState(0);
  const [phase, setPhase] = useState('Ready');
  const [eta, setEta] = useState('');
  const [, setCurrentJob] = useState<any>(null);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  
  const logRef = useRef<HTMLTextAreaElement>(null);
  
  // 분산 GPU 상태 확인
  const checkDistributedStatus = async () => {
    try {
      const status = await apiService.getDistributedSystemInfo();
      logMessage(`✅ 분산 시스템 상태: ${status.mode}`);
      logMessage(`💾 총 VRAM: ${status.total_vram}`);
      logMessage(`🖥️ 온라인 백엔드: ${status.backends?.length || 0}개`);
      
      if (status.backends) {
        status.backends.forEach((backend: any) => {
          logMessage(`  - ${backend.name}: ${backend.status}`);
        });
      }
    } catch (error) {
      logMessage(`❌ 분산 시스템 연결 실패: ${error}`);
    }
  };

  // Initialize console on mount
  useEffect(() => {
    if (logRef.current) {
      const timestamp = new Date().toLocaleTimeString();
      logRef.current.value = `[${timestamp}] 🚀 WAN2.2 Professional Studio Ready\n`;
      logRef.current.value += `[${timestamp}] 🎯 분산 GPU 모드: Windows + Pop!_OS\n`;
      logRef.current.value += `[${timestamp}] 📊 Available Models: TI2V-5B, T2V-A14B, I2V-A14B, S2V-14B\n`;
      logRef.current.value += `[${timestamp}] ⚡ Flash Attention: ${useFlashAttention ? 'Enabled' : 'Disabled'}\n`;
      logRef.current.value += `[${timestamp}] 🖥️ 백엔드 서버 확인 중...\n`;
      logRef.current.value += '========================================\n';
      
      // 분산 GPU 상태 확인
      setTimeout(() => checkDistributedStatus(), 1000);
    }
  }, []);

  // Calculate estimated time and VRAM
  const estimatedTime = useCallback(() => {
    // const model = WAN22_MODELS[activeModel]; // not used
    const baseTime = activeModel.includes('5B') ? 540 : 720; // seconds
    const frameCount = fps * duration;
    const stepMultiplier = steps / 50;
    const resMultiplier = resolution.includes('1280') ? 1.2 : 1.0;
    
    let time = baseTime * stepMultiplier * resMultiplier * (frameCount / 120);
    
    if (useFP16) time *= 0.7;
    if (useFlashAttention) time *= 0.8;
    if (useOffload) time *= 1.3;
    
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}m ${seconds}s`;
  }, [activeModel, fps, duration, steps, resolution, useFP16, useFlashAttention, useOffload]);

  const handleGenerate = async () => {
    // Validation
    if (!prompt && activeModel !== 'i2v-A14B') {
      message.error('프롬프트를 입력해주세요');
      return;
    }
    
    // I2V-A14B는 이미지 필수, TI2V-5B는 선택적
    if (activeModel === 'i2v-A14B' && !imageFile) {
      message.error('I2V 모델은 이미지가 필수입니다');
      return;
    }
    
    if (activeModel === 's2v-14B' && !audioFile) {
      message.error('Speech-to-Video requires an audio file');
      return;
    }

    setIsGenerating(true);
    setVideoUrl(null);
    setProgress(0);
    setPhase('Initializing');
    
    // 콘솔 초기화 및 시작 로그
    if (logRef.current) {
      logRef.current.value = ''; // 기존 로그 지우기
    }
    // const timestamp = new Date().toLocaleTimeString(); // not used
    logMessage('========================================');
    logMessage(`Video Generation Started`);
    logMessage(`Model: ${activeModel.toUpperCase()}`);
    logMessage(`Resolution: ${resolution}`);
    logMessage(`Duration: ${duration}s`);
    logMessage(`FPS: ${fps}`);
    logMessage(`Steps: ${steps}`);
    if (activeModel === 'ti2v-5B') {
      logMessage(`Mode: ${imageFile ? 'Image-to-Video' : 'Text-to-Video'}`);
    }
    logMessage('========================================');
    
    try {
      // Enhance prompt if enabled
      let enhancedPrompt = prompt;
      if (usePromptExtension) {
        enhancedPrompt = enhancePrompt(prompt);
        logMessage(`Enhanced prompt: ${enhancedPrompt}`);
      }
      
      // Apply aesthetic preset
      if (aestheticPreset !== 'none') {
        const preset = AESTHETIC_PRESETS[aestheticPreset];
        enhancedPrompt += `, ${preset.lighting} lighting, ${preset.composition} composition, ${preset.colorTone} color grading`;
        logMessage(`Applied aesthetic preset: ${aestheticPreset}`);
      }
      
      // Prepare generation request
      const formData = new FormData();
      formData.append('prompt', enhancedPrompt);
      formData.append('negative_prompt', negativePrompt);
      formData.append('duration', duration.toString());
      formData.append('fps', fps.toString());
      formData.append('steps', steps.toString());
      formData.append('cfg_scale', cfgScale.toString());
      formData.append('seed', seed.toString());
      formData.append('resolution', resolution);
      formData.append('motion_strength', motionStrength.toString());
      formData.append('temporal_consistency', temporalConsistency.toString());
      
      if (imageFile) formData.append('image', imageFile);
      if (audioFile) formData.append('audio', audioFile);
      if (referenceImage) formData.append('reference', referenceImage);
      
      // Call appropriate API based on model
      let job_id: string;
      
      setPhase('Submitting job');
      logMessage(`Starting ${activeModel} generation...`);
      
      if (activeModel === 's2v-14B' && audioFile) {
        const { job_id: id } = await apiService.generateS2V(audioFile, 'cinematic', duration);
        job_id = id;
      } else {
        // 분산 GPU 사용
        logMessage('🚀 분산 GPU 모드: Windows + Pop!_OS');
        const result = await apiService.generateDistributedTI2V(
          imageFile,
          enhancedPrompt,
          duration,
          'high',
          true  // 분산 처리 사용
        );
        job_id = result.job_id;
        logMessage(`분산 처리 시작: ${result.backends}개 백엔드 사용`);
      }
      
      message.success('Generation job submitted!');
      setPhase('Processing');
      
      // Monitor progress (분산 GPU용)
      const completedJob = await apiService.pollDistributedJobStatus(job_id, (job) => {
        setCurrentJob(job);
        setProgress(job.progress);
        setPhase(job.message || 'Processing');
        
        if (job.message) {
          logMessage(job.message);
        }
        
        // 분산 처리 정보 로그
        if (job.backends_used) {
          logMessage(`사용 중인 백엔드: ${job.backends_used.join(', ')}`);
        }
        
        // Calculate ETA
        if (job.progress > 0 && job.progress < 100) {
          const elapsed = Date.now() - startTime;
          const total = (elapsed / job.progress) * 100;
          const remaining = total - elapsed;
          const etaMinutes = Math.floor(remaining / 60000);
          const etaSeconds = Math.floor((remaining % 60000) / 1000);
          setEta(`${etaMinutes}m ${etaSeconds}s`);
        }
      });
      
      // Handle completion
      if (completedJob.output) {
        setVideoUrl(apiService.getDistributedVideoUrl(completedJob.output.video_url));
        message.success('🎉 분산 GPU 처리 완료!');
        setPhase('Completed');
        setProgress(100);
        setEta('');
        logMessage('✅ 분산 GPU 처리 완료!');
        logMessage(`모드: ${completedJob.output.mode || 'distributed'}`);
        logMessage(`Output: ${completedJob.output.video_url}`);
        logMessage(`Duration: ${completedJob.output.duration}s`);
        logMessage(`Resolution: ${completedJob.output.resolution || resolution}`);
        
        if (completedJob.backends_used) {
          logMessage(`처리된 백엔드: ${completedJob.backends_used.join(', ')}`);
        }
      }
      
    } catch (error: any) {
      message.error(`Generation failed: ${error.message}`);
      setPhase('Failed');
      logMessage(`❌ Error: ${error.message}`);
    } finally {
      setIsGenerating(false);
    }
  };
  
  const startTime = Date.now();
  
  const enhancePrompt = (original: string): string => {
    // Simple prompt enhancement (in production, this would use an LLM)
    const enhancements = [
      'highly detailed',
      'professional quality',
      'smooth motion',
      'cinematic lighting',
      '8K resolution',
      'photorealistic'
    ];
    
    return `${original}, ${enhancements.join(', ')}`;
  };
  
  const logMessage = (msg: string) => {
    if (logRef.current) {
      const timestamp = new Date().toLocaleTimeString();
      logRef.current.value += `[${timestamp}] ${msg}\n`;
      logRef.current.scrollTop = logRef.current.scrollHeight;
    }
  };

  return (
    <div className="wan22-professional">
      {/* Header */}
      <div className="wan22-header">
        <div className="header-content">
          <Title level={2} className="app-title">
            WAN2.2 Professional Studio
          </Title>
          <Text className="app-subtitle">
            Enterprise-Grade AI Video Generation
          </Text>
        </div>
        <div className="header-stats">
          <Tag color="green">GPU: RTX 3090 24GB</Tag>
          <Tag color="blue">CUDA 12.1</Tag>
          <Tag color="purple">PyTorch 2.4</Tag>
        </div>
      </div>

      {/* Model Selector */}
      <Card className="model-selector-card">
        <Title level={4}>Select Model</Title>
        <Radio.Group 
          value={activeModel} 
          onChange={(e) => {
            setActiveModel(e.target.value);
            setResolution(WAN22_MODELS[e.target.value].resolution[0]);
          }}
          className="model-radio-group"
        >
          {Object.entries(WAN22_MODELS).map(([key, model]) => (
            <Radio.Button key={key} value={key} className="model-radio-button">
              <div className="model-info">
                <div className="model-name">{model.name}</div>
                <div className="model-specs">
                  <Tag color="blue">{model.params}</Tag>
                  <Tag color="orange">{model.vramRequired}</Tag>
                </div>
                <div className="model-features">
                  {model.features.map(f => (
                    <Tag key={f}>{f}</Tag>
                  ))}
                </div>
              </div>
            </Radio.Button>
          ))}
        </Radio.Group>
      </Card>

      {/* Main Content */}
      <div className="wan22-content">
        <div className="left-panel">
          {/* Input Section */}
          <Card className="input-card">
            <Title level={4}>Input</Title>
            
            {/* Prompt */}
            <div className="input-group">
              <label>
                Prompt <Tooltip title="Describe your video in detail"><InfoCircleOutlined /></Tooltip>
                <Button 
                  size="small" 
                  style={{ marginLeft: 10 }}
                  onClick={async () => {
                    if (prompt) {
                      try {
                        const result = await apiService.translateText(prompt);
                        if (result && result.translated !== prompt) {
                          setPrompt(result.translated);
                          message.success(`번역 완료: ${result.translated.substring(0, 50)}...`);
                        } else if (result.language === 'en') {
                          message.info('이미 영어입니다');
                        }
                      } catch (error) {
                        message.error('번역 실패');
                      }
                    }
                  }}
                  icon={<TranslationOutlined />}
                >
                  한→영 번역
                </Button>
              </label>
              <TextArea
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="A cinematic shot of a futuristic city at sunset, flying cars, neon lights... (한글 입력 가능)"
                rows={3}
                className="prompt-input"
              />
              {prompt && /[가-힣]/.test(prompt) && (
                <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                  한글이 감지되었습니다. '한→영 번역' 버튼을 클릭하세요.
                </Text>
              )}
            </div>
            
            {/* Negative Prompt */}
            <div className="input-group">
              <label>Negative Prompt</label>
              <Input
                value={negativePrompt}
                onChange={(e) => setNegativePrompt(e.target.value)}
                placeholder="blur, low quality, distorted..."
              />
            </div>
            
            {/* File Uploads */}
            {(activeModel === 'i2v-A14B' || activeModel === 'ti2v-5B') && (
              <div className="input-group">
                <label>
                  Input Image 
                  {activeModel === 'i2v-A14B' && <span className="required">*</span>}
                  {activeModel === 'ti2v-5B' && (
                    <Tooltip title="선택사항: 이미지가 있으면 I2V, 없으면 T2V로 작동">
                      <Tag color="green" style={{ marginLeft: 8 }}>선택</Tag>
                    </Tooltip>
                  )}
                </label>
                <Upload
                  beforeUpload={(file) => {
                    setImageFile(file);
                    return false;
                  }}
                  maxCount={1}
                >
                  <Button icon={<PictureOutlined />}>
                    {imageFile ? imageFile.name : 'Select Image'}
                  </Button>
                </Upload>
                {activeModel === 'ti2v-5B' && !imageFile && (
                  <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                    이미지 없이 프롬프트만으로 비디오 생성 가능 (T2V 모드)
                  </Text>
                )}
              </div>
            )}
            
            {activeModel === 's2v-14B' && (
              <>
                <div className="input-group">
                  <label>Audio File <span className="required">*</span></label>
                  <Upload
                    beforeUpload={(file) => {
                      setAudioFile(file);
                      return false;
                    }}
                    maxCount={1}
                  >
                    <Button icon={<AudioOutlined />}>
                      {audioFile ? audioFile.name : 'Select Audio'}
                    </Button>
                  </Upload>
                </div>
                <div className="input-group">
                  <label>Reference Image (Optional)</label>
                  <Upload
                    beforeUpload={(file) => {
                      setReferenceImage(file);
                      return false;
                    }}
                    maxCount={1}
                  >
                    <Button icon={<PictureOutlined />}>
                      {referenceImage ? referenceImage.name : 'Select Reference'}
                    </Button>
                  </Upload>
                </div>
              </>
            )}
          </Card>

          {/* Generation Settings */}
          <Card className="settings-card">
            <Tabs 
              defaultActiveKey="basic"
              items={[
                {
                  key: 'basic',
                  label: 'Basic Settings',
                  children: (
                    <div className="settings-grid">
                      <div className="setting-item">
                        <label>Resolution</label>
                        <Select value={resolution} onChange={setResolution} style={{ width: '100%' }}>
                          {WAN22_MODELS[activeModel].resolution.map(res => (
                            <Option key={res} value={res}>{res}</Option>
                          ))}
                        </Select>
                      </div>
                      
                      <div className="setting-item">
                        <label>Duration (seconds)</label>
                        <InputNumber
                          value={duration}
                          onChange={(v) => setDuration(v || 5)}
                          min={1}
                          max={30}
                          style={{ width: '100%' }}
                        />
                      </div>
                      
                      <div className="setting-item">
                        <label>FPS</label>
                        <Select value={fps} onChange={setFps} style={{ width: '100%' }}>
                          <Option value={8}>8 FPS</Option>
                          <Option value={12}>12 FPS</Option>
                          <Option value={16}>16 FPS</Option>
                          <Option value={24}>24 FPS</Option>
                          <Option value={30}>30 FPS</Option>
                        </Select>
                      </div>
                      
                      <div className="setting-item">
                        <label>Sampling Steps</label>
                        <Slider
                          value={steps}
                          onChange={setSteps}
                          min={20}
                          max={100}
                          marks={{ 20: '20', 50: '50', 100: '100' }}
                        />
                      </div>
                      
                      <div className="setting-item">
                        <label>CFG Scale</label>
                        <Slider
                          value={cfgScale}
                          onChange={setCfgScale}
                          min={1}
                          max={20}
                          step={0.5}
                          marks={{ 1: '1', 7.5: '7.5', 20: '20' }}
                        />
                      </div>
                      
                      <div className="setting-item">
                        <label>Seed</label>
                        <InputNumber
                          value={seed}
                          onChange={(v) => setSeed(v || -1)}
                          style={{ width: '100%' }}
                          placeholder="-1 for random"
                        />
                      </div>
                    </div>
                  )
                },
                {
                  key: 'advanced',
                  label: 'Advanced',
                  children: (
                    <Space direction="vertical" style={{ width: '100%' }}>
                      <div className="setting-group">
                        <Title level={5}>Prompt Enhancement</Title>
                        <Switch
                          checked={usePromptExtension}
                          onChange={setUsePromptExtension}
                          checkedChildren="ON"
                          unCheckedChildren="OFF"
                        />
                        {usePromptExtension && (
                          <Select
                            value={promptExtensionMethod}
                            onChange={setPromptExtensionMethod}
                            style={{ width: '100%', marginTop: 8 }}
                          >
                            <Option value="llm">LLM Enhancement</Option>
                            <Option value="template">Template-based</Option>
                            <Option value="artistic">Artistic Style</Option>
                          </Select>
                        )}
                      </div>
                      
                      <div className="setting-group">
                        <Title level={5}>Aesthetic Preset</Title>
                        <Select
                          value={aestheticPreset}
                          onChange={setAestheticPreset}
                          style={{ width: '100%' }}
                        >
                          <Option value="none">None</Option>
                          <Option value="cinematic">Cinematic</Option>
                          <Option value="documentary">Documentary</Option>
                          <Option value="artistic">Artistic</Option>
                          <Option value="commercial">Commercial</Option>
                        </Select>
                      </div>
                      
                      <div className="setting-group">
                        <Title level={5}>Motion Control</Title>
                        <label>Motion Strength</label>
                        <Slider
                          value={motionStrength}
                          onChange={setMotionStrength}
                          min={0}
                          max={2}
                          step={0.1}
                          marks={{ 0: 'Static', 1: 'Normal', 2: 'Dynamic' }}
                        />
                        
                        <label>Temporal Consistency</label>
                        <Slider
                          value={temporalConsistency}
                          onChange={setTemporalConsistency}
                          min={0}
                          max={1}
                          step={0.05}
                          marks={{ 0: 'Low', 0.5: 'Medium', 1: 'High' }}
                        />
                      </div>
                    </Space>
                  )
                },
                {
                  key: 'optimization',
                  label: 'Optimization',
                  children: (
                    <Space direction="vertical" style={{ width: '100%' }}>
                      <div className="optimization-settings">
                        <Switch
                          checked={useOffload}
                          onChange={setUseOffload}
                          checkedChildren="CPU Offload ON"
                          unCheckedChildren="CPU Offload OFF"
                        />
                        <Switch
                          checked={useFP16}
                          onChange={setUseFP16}
                          checkedChildren="FP16 ON"
                          unCheckedChildren="FP16 OFF"
                        />
                        <Switch
                          checked={useFlashAttention}
                          onChange={setUseFlashAttention}
                          checkedChildren="Flash Attention ON"
                          unCheckedChildren="Flash Attention OFF"
                        />
                      </div>
                      
                      <div className="setting-item">
                        <label>Batch Size</label>
                        <InputNumber
                          value={batchSize}
                          onChange={(v) => setBatchSize(v || 1)}
                          min={1}
                          max={8}
                          style={{ width: '100%' }}
                        />
                      </div>
                      
                      <div className="info-box">
                        <Title level={5}>Estimated Performance</Title>
                        <Text>Time: {estimatedTime()}</Text>
                        <br />
                        <Text>VRAM Usage: ~{activeModel.includes('5B') ? '16GB' : '22GB'}</Text>
                      </div>
                    </Space>
                  )
                }
              ]}
            />
          </Card>

          {/* Action Buttons */}
          <div className="action-buttons">
            <Button
              type="primary"
              size="large"
              icon={<PlayCircleOutlined />}
              onClick={handleGenerate}
              loading={isGenerating}
              disabled={!prompt}
              className="generate-button"
            >
              Generate Video
            </Button>
            
            <Button
              size="large"
              icon={<StopOutlined />}
              disabled={!isGenerating}
              danger
            >
              Cancel
            </Button>
            
            <Button
              size="large"
              icon={<SaveOutlined />}
            >
              Save Settings
            </Button>
          </div>
        </div>

        <div className="right-panel">
          {/* Progress Section */}
          <Card className="progress-card">
            <Title level={4}>Generation Progress</Title>
            <div className="progress-info">
              <div className="progress-status">
                <Text strong>{phase}</Text>
                {eta && <Text type="secondary"> - ETA: {eta}</Text>}
              </div>
              <Progress
                percent={progress}
                status={isGenerating ? 'active' : progress === 100 ? 'success' : 'normal'}
                strokeColor={{
                  '0%': '#108ee9',
                  '100%': '#87d068',
                }}
              />
            </div>
          </Card>

          {/* Console Log */}
          <Card className="console-card">
            <Title level={4}>Console 
              <Button 
                size="small" 
                style={{ marginLeft: 10 }}
                onClick={() => {
                  const timestamp = new Date().toLocaleTimeString();
                  logMessage(`Test message at ${timestamp}`);
                }}
              >
                Test Log
              </Button>
            </Title>
            <TextArea
              ref={logRef}
              className="console-log"
              placeholder="Generation logs will appear here..."
              readOnly
              autoSize={{ minRows: 15, maxRows: 25 }}
              style={{ backgroundColor: '#0a0a0f', color: '#00ff88', fontFamily: 'monospace' }}
            />
          </Card>

          {/* Video Preview */}
          {videoUrl && (
            <Card className="preview-card">
              <Title level={4}>Generated Video</Title>
              <video
                src={videoUrl}
                controls
                className="video-preview"
                style={{ width: '100%', borderRadius: '8px' }}
              />
              <div className="video-actions">
                <Button type="primary" href={videoUrl} download>
                  Download Video
                </Button>
                <Button>Add to Gallery</Button>
              </div>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
};

export default Wan22Professional;