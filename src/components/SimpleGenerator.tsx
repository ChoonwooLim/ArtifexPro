import React, { useState } from 'react';
import { Upload, Button, Input, Select, Progress, Card, message, Tabs, Space, Typography } from 'antd';
import { UploadOutlined, VideoCameraOutlined, AudioOutlined, LoadingOutlined } from '@ant-design/icons';
import { apiService, Job } from '../services/api';

const { TextArea } = Input;
const { Option } = Select;
const { Title, Text } = Typography;

export const SimpleGenerator: React.FC = () => {
  const [activeTab, setActiveTab] = useState('ti2v');
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [prompt, setPrompt] = useState('');
  const [style, setStyle] = useState('cinematic');
  const [duration, setDuration] = useState(5);
  const [quality, setQuality] = useState('balanced');
  const [generating, setGenerating] = useState(false);
  const [currentJob, setCurrentJob] = useState<Job | null>(null);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);

  const handleTI2VGenerate = async () => {
    if (!imageFile) {
      message.error('Please upload an image first');
      return;
    }
    if (!prompt) {
      message.error('Please enter a prompt');
      return;
    }

    setGenerating(true);
    setVideoUrl(null);

    try {
      // 생성 시작
      const { job_id } = await apiService.generateTI2V(imageFile, prompt, duration, quality);
      message.info('Generation started!');

      // 진행 상황 모니터링
      const completedJob = await apiService.pollJobStatus(job_id, (job) => {
        setCurrentJob(job);
      });

      // 완료
      if (completedJob.output) {
        setVideoUrl(apiService.getVideoUrl(completedJob.output.video_url));
        message.success('Video generated successfully!');
      }
    } catch (error) {
      message.error(`Generation failed: ${error}`);
    } finally {
      setGenerating(false);
    }
  };

  const handleS2VGenerate = async () => {
    if (!audioFile) {
      message.error('Please upload an audio file first');
      return;
    }

    setGenerating(true);
    setVideoUrl(null);

    try {
      const { job_id } = await apiService.generateS2V(audioFile, style, duration);
      message.info('Generation started!');

      const completedJob = await apiService.pollJobStatus(job_id, (job) => {
        setCurrentJob(job);
      });

      if (completedJob.output) {
        setVideoUrl(apiService.getVideoUrl(completedJob.output.video_url));
        message.success('Video generated successfully!');
      }
    } catch (error) {
      message.error(`Generation failed: ${error}`);
    } finally {
      setGenerating(false);
    }
  };

  const ti2vTab = (
    <Card>
      <Space direction="vertical" style={{ width: '100%' }} size="large">
        <div>
          <Title level={4}>Image Upload</Title>
          <Upload
            beforeUpload={(file) => {
              setImageFile(file);
              return false;
            }}
            maxCount={1}
          >
            <Button icon={<UploadOutlined />}>Select Image</Button>
          </Upload>
          {imageFile && <Text type="secondary">Selected: {imageFile.name}</Text>}
        </div>

        <div>
          <Title level={4}>Prompt</Title>
          <TextArea
            rows={3}
            placeholder="Describe the video you want to generate..."
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
          />
        </div>

        <Space>
          <div>
            <Text>Duration (seconds)</Text>
            <Input
              type="number"
              min={1}
              max={30}
              value={duration}
              onChange={(e) => setDuration(Number(e.target.value))}
              style={{ width: 100, marginLeft: 10 }}
            />
          </div>

          <div>
            <Text>Quality</Text>
            <Select value={quality} onChange={setQuality} style={{ width: 120, marginLeft: 10 }}>
              <Option value="draft">Draft</Option>
              <Option value="balanced">Balanced</Option>
              <Option value="high">High</Option>
            </Select>
          </div>
        </Space>

        <Button
          type="primary"
          icon={<VideoCameraOutlined />}
          onClick={handleTI2VGenerate}
          loading={generating}
          disabled={!imageFile || !prompt}
          size="large"
          block
        >
          Generate TI2V
        </Button>
      </Space>
    </Card>
  );

  const s2vTab = (
    <Card>
      <Space direction="vertical" style={{ width: '100%' }} size="large">
        <div>
          <Title level={4}>Audio Upload</Title>
          <Upload
            beforeUpload={(file) => {
              setAudioFile(file);
              return false;
            }}
            maxCount={1}
          >
            <Button icon={<AudioOutlined />}>Select Audio</Button>
          </Upload>
          {audioFile && <Text type="secondary">Selected: {audioFile.name}</Text>}
        </div>

        <Space>
          <div>
            <Text>Style</Text>
            <Select value={style} onChange={setStyle} style={{ width: 150, marginLeft: 10 }}>
              <Option value="cinematic">Cinematic</Option>
              <Option value="abstract">Abstract</Option>
              <Option value="nature">Nature</Option>
              <Option value="cyberpunk">Cyberpunk</Option>
              <Option value="anime">Anime</Option>
            </Select>
          </div>

          <div>
            <Text>Duration (seconds)</Text>
            <Input
              type="number"
              min={1}
              max={60}
              value={duration}
              onChange={(e) => setDuration(Number(e.target.value))}
              style={{ width: 100, marginLeft: 10 }}
            />
          </div>
        </Space>

        <Button
          type="primary"
          icon={<AudioOutlined />}
          onClick={handleS2VGenerate}
          loading={generating}
          disabled={!audioFile}
          size="large"
          block
        >
          Generate S2V
        </Button>
      </Space>
    </Card>
  );

  return (
    <div style={{ padding: 20 }}>
      <Title level={2}>ArtifexPro Video Generator</Title>
      
      <Tabs 
        activeKey={activeTab} 
        onChange={setActiveTab}
        items={[
          {
            key: 'ti2v',
            label: 'Text+Image to Video (TI2V)',
            children: ti2vTab
          },
          {
            key: 's2v',
            label: 'Sound to Video (S2V)',
            children: s2vTab
          }
        ]}
      />

      {/* 진행 상황 표시 */}
      {generating && currentJob && (
        <Card style={{ marginTop: 20 }}>
          <Title level={4}>
            {generating ? <LoadingOutlined /> : null} Generation Progress
          </Title>
          <Progress percent={currentJob.progress} status="active" />
          <Text type="secondary">{currentJob.message || 'Processing...'}</Text>
        </Card>
      )}

      {/* 비디오 결과 */}
      {videoUrl && (
        <Card style={{ marginTop: 20 }}>
          <Title level={4}>Generated Video</Title>
          <video controls style={{ width: '100%', maxWidth: 800 }}>
            <source src={videoUrl} type="video/mp4" />
            Your browser does not support the video tag.
          </video>
          <div style={{ marginTop: 10 }}>
            <Button href={videoUrl} download>Download Video</Button>
          </div>
        </Card>
      )}
    </div>
  );
};