import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { Upload, Input, Select, Button, Progress, Checkbox, Tabs, message, Card, Space, Typography } from 'antd';
import { 
  VideoCameraOutlined, 
  AudioOutlined, 
  RobotOutlined, 
  NodeIndexOutlined,
  ClockCircleOutlined,
  StarOutlined,
  CameraOutlined,
  ExportOutlined,
  ThunderboltOutlined,
  UploadOutlined,
  FolderOpenOutlined,
  PlayCircleOutlined,
  StopOutlined,
  SaveOutlined,
  SettingOutlined
} from '@ant-design/icons';
import { apiService } from '../services/api';
import './ProfessionalApp.css';

const { TextArea } = Input;
const { Option } = Select;
const { Title, Text } = Typography;

export const ProfessionalApp: React.FC = () => {
  const [activeView, setActiveView] = useState<string>('wan');
  const [isAnimated, setIsAnimated] = useState(false);
  
  // WAN generation states
  const [task, setTask] = useState<'t2v-A14B' | 'i2v-A14B' | 'ti2v-5B'>('ti2v-5B');
  const [size, setSize] = useState('1280*704');
  const [prompt, setPrompt] = useState('A cinematic sunset over mountain lake');
  const [imagePath, setImagePath] = useState('');
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [lengthSec, setLengthSec] = useState(5);
  const [fps, setFps] = useState(24);
  const [quality, setQuality] = useState('balanced');
  const [running, setRunning] = useState(false);
  const [phase, setPhase] = useState('Idle');
  const [progress, setProgress] = useState(0);
  const [eta, setEta] = useState('');
  const [currentJob, setCurrentJob] = useState<any>(null);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  
  const logRef = useRef<HTMLTextAreaElement>(null);

  const SIZE_OPTIONS: Record<string, string[]> = {
    't2v-A14B': ['480*832', '832*480', '1280*720', '720*1280'],
    'i2v-A14B': ['480*832', '832*480', '1280*720', '720*1280'],
    'ti2v-5B': ['1280*704', '704*1280']
  };

  useEffect(() => {
    setIsAnimated(true);
  }, []);

  const navItems = [
    { id: 'wan', label: 'WAN Generate', icon: <VideoCameraOutlined /> },
    { id: 's2v', label: 'Speech to Video', icon: <AudioOutlined /> },
    { id: 'autoshorts', label: 'VisionCut.AI', icon: <RobotOutlined /> },
    { id: 'editor', label: 'Node Editor', icon: <NodeIndexOutlined /> },
    { id: 'timeline', label: 'Timeline', icon: <ClockCircleOutlined /> },
    { id: 'effects', label: 'Effects', icon: <StarOutlined /> },
    { id: 'cinematic', label: 'Cinematic', icon: <CameraOutlined /> },
    { id: 'export', label: 'Export', icon: <ExportOutlined /> },
    { id: 'flow', label: 'WAN Flow', icon: <ThunderboltOutlined /> }
  ];

  const estText = useMemo(() => {
    const steps = task.includes('ti2v') ? 50 : 40;
    const n = Math.max(1, Math.round((fps * lengthSec) / 4));
    const frameNum = 4 * n + 1;
    const m = size.match(/(\d+)\*(\d+)/);
    const area = m ? Number(m[1]) * Number(m[2]) : 1280 * 704;
    let baseSec = 300;
    
    if (task.includes('ti2v')) {
      baseSec = 540;
    } else if (task.includes('t2v')) {
      baseSec = size.includes('1280') ? 360 : 180;
    } else {
      baseSec = 240;
    }
    
    const est = baseSec * (steps / 40) * (area / (1280 * 704)) * (frameNum / 81);
    const mm = Math.max(0, Math.floor(est / 60));
    const ss = Math.max(0, Math.round(est % 60));
    return `예상 완료 ${mm}m ${ss}s`;
  }, [task, size, lengthSec, fps]);

  const handleGenerate = async () => {
    if (!imageFile && task !== 't2v-A14B') {
      message.error('Please upload an image first');
      return;
    }
    if (!prompt) {
      message.error('Please enter a prompt');
      return;
    }

    setRunning(true);
    setVideoUrl(null);
    setPhase('Starting');
    setProgress(0);

    try {
      // API 호출
      const { job_id } = await apiService.generateTI2V(
        imageFile || new File([], 'dummy'),
        prompt,
        lengthSec,
        quality
      );
      
      message.info('Generation started!');
      setPhase('Processing');

      // 진행 상황 모니터링
      const completedJob = await apiService.pollJobStatus(job_id, (job) => {
        setCurrentJob(job);
        setProgress(job.progress);
        setPhase(job.message || 'Processing');
        
        if (job.progress > 0 && job.progress < 100) {
          const remainingProgress = 100 - job.progress;
          const estimatedSeconds = remainingProgress * 2; // 예상 시간 계산
          const mm = Math.floor(estimatedSeconds / 60);
          const ss = estimatedSeconds % 60;
          setEta(`${mm}m ${ss}s`);
        }
      });

      // 완료
      if (completedJob.output) {
        setVideoUrl(apiService.getVideoUrl(completedJob.output.video_url));
        message.success('Video generated successfully!');
        setPhase('Completed');
        setEta('');
      }
    } catch (error) {
      message.error(`Generation failed: ${error}`);
      setPhase('Failed');
    } finally {
      setRunning(false);
    }
  };

  const quickMode = () => {
    setLengthSec(3);
    setFps(16);
    setQuality('draft');
    message.success('Quick mode settings applied');
  };

  return (
    <div className="professional-app">
      {/* 왼쪽 사이드바 */}
      <div className="sidebar">
        <div className="sidebar-header">
          <h2 className="app-title">Artifex AI Studio</h2>
          <p className="app-subtitle">WAN 2.2 Professional</p>
        </div>
        
        <nav className="sidebar-nav">
          {navItems.map(item => (
            <button
              key={item.id}
              onClick={() => setActiveView(item.id)}
              className={`nav-item ${activeView === item.id ? 'active' : ''}`}
            >
              <span className="nav-icon">{item.icon}</span>
              <span className="nav-label">{item.label}</span>
            </button>
          ))}
        </nav>
        
        <div className="sidebar-footer">
          <div className="version">Version 2.2.0</div>
        </div>
      </div>
      
      {/* 메인 컨텐츠 영역 */}
      <div className="main-content">
        <div className={`content-wrapper ${isAnimated ? 'animated' : ''}`}>
          {activeView === 'wan' && (
            <div className="wan-view">
              {/* Progress Bar */}
              <Card className="progress-card">
                <div className="progress-header">
                  <div className="progress-status">
                    <span className="phase-text">{phase}</span>
                    {phase === 'Processing' && <span className="pulse-indicator" />}
                  </div>
                  <div className="progress-info">
                    {eta && <span className="eta">ETA: {eta}</span>}
                    <span className="progress-percent">{progress}%</span>
                  </div>
                </div>
                <Progress 
                  percent={progress} 
                  strokeColor={{ '0%': '#667eea', '100%': '#764ba2' }}
                  showInfo={false}
                />
              </Card>

              {/* Quick Actions */}
              <Space className="quick-actions" size="middle">
                <Button 
                  icon={<SaveOutlined />}
                  type="primary"
                  className="gradient-button"
                >
                  Save Defaults
                </Button>
                <Button 
                  icon={<ThunderboltOutlined />}
                  onClick={quickMode}
                  className="quick-mode-button"
                >
                  빠른 모드
                </Button>
              </Space>

              {/* Settings Grid */}
              <Card className="settings-card">
                <div className="settings-grid">
                  <div className="setting-item">
                    <label>Task</label>
                    <Select 
                      value={task} 
                      onChange={(t) => {
                        setTask(t);
                        setSize(SIZE_OPTIONS[t][0]);
                      }}
                      className="setting-select"
                    >
                      <Option value="t2v-A14B">T2V-A14B</Option>
                      <Option value="i2v-A14B">I2V-A14B</Option>
                      <Option value="ti2v-5B">TI2V-5B</Option>
                    </Select>
                  </div>
                  
                  <div className="setting-item">
                    <label>Size</label>
                    <Select 
                      value={size} 
                      onChange={setSize}
                      className="setting-select"
                    >
                      {SIZE_OPTIONS[task].map(opt => (
                        <Option key={opt} value={opt}>{opt}</Option>
                      ))}
                    </Select>
                  </div>

                  <div className="setting-item span-2">
                    <label>Prompt</label>
                    <Input 
                      value={prompt} 
                      onChange={(e) => setPrompt(e.target.value)}
                      placeholder="Describe your video..."
                      className="setting-input"
                    />
                  </div>

                  <div className="setting-item">
                    <label>Length (sec)</label>
                    <div className="input-with-info">
                      <Input 
                        type="number"
                        value={lengthSec} 
                        onChange={(e) => setLengthSec(Number(e.target.value))}
                        className="setting-input-small"
                      />
                      <span className="est-text">{estText}</span>
                    </div>
                  </div>

                  <div className="setting-item">
                    <label>FPS</label>
                    <Input 
                      type="number"
                      value={fps} 
                      onChange={(e) => setFps(Number(e.target.value))}
                      className="setting-input-small"
                    />
                  </div>

                  {task !== 't2v-A14B' && (
                    <div className="setting-item span-2">
                      <label>Image</label>
                      <Upload
                        beforeUpload={(file) => {
                          setImageFile(file);
                          setImagePath(file.name);
                          return false;
                        }}
                        maxCount={1}
                        className="image-upload"
                      >
                        <Button icon={<UploadOutlined />} className="upload-button">
                          {imagePath || 'Select Image'}
                        </Button>
                      </Upload>
                    </div>
                  )}

                  <div className="setting-item span-4">
                    <Space size="large">
                      <Checkbox>Offload Model</Checkbox>
                      <Checkbox>Convert Dtype</Checkbox>
                      <Checkbox>T5 CPU</Checkbox>
                    </Space>
                  </div>
                </div>
              </Card>

              {/* Action Buttons */}
              <Space className="action-buttons" size="middle">
                <Button 
                  type="primary"
                  size="large"
                  icon={<PlayCircleOutlined />}
                  onClick={handleGenerate}
                  loading={running}
                  disabled={!prompt}
                  className="generate-button"
                >
                  Generate
                </Button>
                <Button 
                  size="large"
                  icon={<StopOutlined />}
                  disabled={!running}
                  className="cancel-button"
                >
                  Cancel
                </Button>
                {videoUrl && (
                  <Button 
                    size="large"
                    icon={<FolderOpenOutlined />}
                    className="folder-button"
                  >
                    Open Folder
                  </Button>
                )}
              </Space>

              {/* Log Output */}
              <Card className="log-card">
                <TextArea 
                  ref={logRef}
                  className="log-output"
                  value={currentJob?.message || ''}
                  readOnly
                  autoSize={{ minRows: 10, maxRows: 20 }}
                />
              </Card>
              
              {/* Video Preview */}
              {videoUrl && (
                <Card className="video-card">
                  <video 
                    src={videoUrl}
                    controls
                    className="video-preview"
                  />
                </Card>
              )}
            </div>
          )}

          {activeView === 's2v' && (
            <div className="s2v-view">
              <Title level={2} className="view-title">Speech to Video</Title>
              <Card className="s2v-card">
                <Space direction="vertical" style={{ width: '100%' }} size="large">
                  <div className="upload-section">
                    <div className="upload-item">
                      <label>참조 이미지 (Reference Image)</label>
                      <Upload className="file-upload">
                        <Button icon={<UploadOutlined />}>Select Image</Button>
                      </Upload>
                    </div>
                    
                    <div className="upload-item">
                      <label>오디오 파일 (Audio File)</label>
                      <Upload className="file-upload">
                        <Button icon={<AudioOutlined />}>Select Audio</Button>
                      </Upload>
                    </div>
                  </div>
                  
                  <div>
                    <label>프롬프트 (Prompt)</label>
                    <TextArea 
                      placeholder="A person speaking naturally with clear lip sync..."
                      className="prompt-textarea"
                      rows={4}
                    />
                  </div>
                  
                  <div className="s2v-settings">
                    <Select defaultValue="16" className="setting-select">
                      <Option value="8">8 FPS</Option>
                      <Option value="12">12 FPS</Option>
                      <Option value="16">16 FPS</Option>
                      <Option value="24">24 FPS</Option>
                      <Option value="30">30 FPS</Option>
                    </Select>
                    
                    <Input 
                      type="number" 
                      defaultValue="80" 
                      placeholder="프레임 수"
                      className="setting-input"
                    />
                    
                    <Input 
                      type="number" 
                      defaultValue="40" 
                      placeholder="샘플링 스텝"
                      className="setting-input"
                    />
                  </div>
                  
                  <Button 
                    type="primary"
                    size="large"
                    icon={<VideoCameraOutlined />}
                    className="generate-button full-width"
                  >
                    Generate Speech Video
                  </Button>
                </Space>
              </Card>
            </div>
          )}

          {activeView === 'autoshorts' && (
            <div className="autoshorts-view">
              <Title level={2} className="view-title">VisionCut.AI</Title>
              <Card className="autoshorts-card">
                <Tabs defaultActiveKey="1">
                  <Tabs.TabPane tab="Auto Shorts" key="1">
                    <Space direction="vertical" style={{ width: '100%' }} size="large">
                      <TextArea 
                        placeholder="Enter your script or topic..."
                        rows={6}
                        className="script-textarea"
                      />
                      <Select defaultValue="tiktok" style={{ width: '100%' }}>
                        <Option value="tiktok">TikTok (9:16)</Option>
                        <Option value="youtube">YouTube Shorts (9:16)</Option>
                        <Option value="instagram">Instagram Reels (9:16)</Option>
                      </Select>
                      <Button type="primary" size="large" icon={<RobotOutlined />} block>
                        Generate Auto Shorts
                      </Button>
                    </Space>
                  </Tabs.TabPane>
                  <Tabs.TabPane tab="AI Chat" key="2">
                    <div className="chat-container">
                      <div className="chat-messages">
                        <div className="chat-message assistant">
                          Hello! I'm VisionCut AI. How can I help you create amazing videos today?
                        </div>
                      </div>
                      <div className="chat-input">
                        <Input.Search 
                          placeholder="Ask me anything about video creation..."
                          enterButton="Send"
                          size="large"
                        />
                      </div>
                    </div>
                  </Tabs.TabPane>
                </Tabs>
              </Card>
            </div>
          )}

          {/* 다른 뷰들은 placeholder */}
          {['editor', 'timeline', 'effects', 'cinematic', 'export', 'flow'].includes(activeView) && (
            <div className="placeholder-view">
              <Card>
                <Title level={3}>{navItems.find(n => n.id === activeView)?.label}</Title>
                <Text type="secondary">This feature is coming soon...</Text>
              </Card>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};