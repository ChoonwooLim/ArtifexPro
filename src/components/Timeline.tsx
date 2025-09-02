import React, { useRef, useEffect, useState } from 'react';
import { Button, Space, Slider } from 'antd';
import { 
  PlayCircleOutlined, 
  PauseCircleOutlined, 
  StepBackwardOutlined,
  StepForwardOutlined,
  PlusOutlined 
} from '@ant-design/icons';

interface Track {
  id: string;
  name: string;
  type: 'video' | 'audio' | 'effect';
  clips: Clip[];
}

interface Clip {
  id: string;
  start: number;
  duration: number;
  color: string;
  label: string;
}

const Timeline: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [zoom, setZoom] = useState(1);
  const [tracks, setTracks] = useState<Track[]>([
    {
      id: '1',
      name: 'Video 1',
      type: 'video',
      clips: [
        { id: 'c1', start: 0, duration: 5, color: '#1890ff', label: 'T2V Output' },
        { id: 'c2', start: 5, duration: 3, color: '#52c41a', label: 'Upscaled' },
      ],
    },
    {
      id: '2',
      name: 'Audio 1',
      type: 'audio',
      clips: [
        { id: 'c3', start: 2, duration: 6, color: '#722ed1', label: 'BGM' },
      ],
    },
    {
      id: '3',
      name: 'Effects',
      type: 'effect',
      clips: [
        { id: 'c4', start: 1, duration: 2, color: '#fa8c16', label: 'Fade In' },
        { id: 'c5', start: 7, duration: 1, color: '#fa8c16', label: 'Fade Out' },
      ],
    },
  ]);

  useEffect(() => {
    drawTimeline();
  }, [tracks, currentTime, zoom]);

  const drawTimeline = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw background
    ctx.fillStyle = '#141414';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Draw time ruler
    ctx.strokeStyle = '#444';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, 30);
    ctx.lineTo(canvas.width, 30);
    ctx.stroke();

    // Draw time markers
    ctx.fillStyle = '#888';
    ctx.font = '10px Arial';
    for (let i = 0; i <= 20; i++) {
      const x = i * 50 * zoom;
      ctx.fillText(`${i}s`, x + 2, 20);
      ctx.beginPath();
      ctx.moveTo(x, 25);
      ctx.lineTo(x, 35);
      ctx.stroke();
    }

    // Draw tracks
    tracks.forEach((track, trackIndex) => {
      const y = 50 + trackIndex * 60;

      // Track background
      ctx.fillStyle = '#1a1a1a';
      ctx.fillRect(0, y, canvas.width, 50);

      // Track label
      ctx.fillStyle = '#fff';
      ctx.font = '12px Arial';
      ctx.fillText(track.name, 5, y + 25);

      // Draw clips
      track.clips.forEach(clip => {
        const x = clip.start * 50 * zoom;
        const width = clip.duration * 50 * zoom;

        // Clip background
        ctx.fillStyle = clip.color;
        ctx.fillRect(x, y + 5, width, 40);

        // Clip label
        ctx.fillStyle = '#fff';
        ctx.font = '11px Arial';
        ctx.fillText(clip.label, x + 5, y + 25);
      });
    });

    // Draw playhead
    const playheadX = currentTime * 50 * zoom;
    ctx.strokeStyle = '#ff4d4f';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(playheadX, 0);
    ctx.lineTo(playheadX, canvas.height);
    ctx.stroke();
  };

  const handlePlayPause = () => {
    setIsPlaying(!isPlaying);
    if (!isPlaying) {
      const interval = setInterval(() => {
        setCurrentTime(prev => {
          if (prev >= 10) {
            setIsPlaying(false);
            clearInterval(interval);
            return 0;
          }
          return prev + 0.1;
        });
      }, 100);
    }
  };

  const handleAddTrack = () => {
    const newTrack: Track = {
      id: `${tracks.length + 1}`,
      name: `Track ${tracks.length + 1}`,
      type: 'video',
      clips: [],
    };
    setTracks([...tracks, newTrack]);
  };

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: '#0a0a0a' }}>
      <div style={{ padding: '8px', background: '#1a1a1a', borderBottom: '1px solid #333' }}>
        <Space>
          <Button 
            icon={<StepBackwardOutlined />} 
            onClick={() => setCurrentTime(0)}
          />
          <Button 
            type="primary" 
            icon={isPlaying ? <PauseCircleOutlined /> : <PlayCircleOutlined />}
            onClick={handlePlayPause}
          >
            {isPlaying ? 'Pause' : 'Play'}
          </Button>
          <Button 
            icon={<StepForwardOutlined />} 
            onClick={() => setCurrentTime(10)}
          />
          <Button 
            icon={<PlusOutlined />}
            onClick={handleAddTrack}
          >
            Add Track
          </Button>
          <span style={{ color: '#fff', marginLeft: 16 }}>
            Time: {currentTime.toFixed(1)}s
          </span>
          <span style={{ color: '#fff', marginLeft: 16 }}>
            Zoom:
          </span>
          <Slider 
            min={0.5} 
            max={3} 
            step={0.1} 
            value={zoom}
            onChange={setZoom}
            style={{ width: 100 }}
          />
        </Space>
      </div>
      <div style={{ flex: 1, overflow: 'auto' }}>
        <canvas 
          ref={canvasRef}
          width={2000}
          height={300}
          style={{ display: 'block' }}
        />
      </div>
    </div>
  );
};

export default Timeline;