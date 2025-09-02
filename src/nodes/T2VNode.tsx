import React, { memo } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { Card, Input, Select, Slider } from 'antd';
import { VideoCameraOutlined } from '@ant-design/icons';

const { TextArea } = Input;

interface T2VNodeData {
  label: string;
  model: string;
  prompt: string;
  resolution: string;
  duration: number;
  quality?: string;
}

const T2VNode: React.FC<NodeProps<T2VNodeData>> = ({ data, selected }) => {
  return (
    <Card
      size="small"
      title={
        <span>
          <VideoCameraOutlined /> {data.label}
        </span>
      }
      style={{
        width: 300,
        border: selected ? '2px solid #1890ff' : '1px solid #d9d9d9',
      }}
    >
      <div style={{ padding: '8px 0' }}>
        <label>Model:</label>
        <Select
          defaultValue={data.model}
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'Wan2.2-T2V-A14B', label: 'Wan2.2-T2V-A14B (27B MoE)' },
            { value: 'Wan2.1-T2V-14B', label: 'Wan2.1-T2V-14B' },
          ]}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Prompt:</label>
        <TextArea
          placeholder="Describe the video you want to generate..."
          rows={3}
          style={{ marginTop: 4 }}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Resolution:</label>
        <Select
          defaultValue={data.resolution}
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: '480p', label: '480p (854×480)' },
            { value: '720p', label: '720p (1280×720)' },
            { value: '1080p', label: '1080p (1920×1080)' },
          ]}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Duration: {data.duration}s</label>
        <Slider
          min={1}
          max={10}
          defaultValue={data.duration}
          marks={{ 1: '1s', 5: '5s', 10: '10s' }}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Quality Preset:</label>
        <Select
          defaultValue="production"
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'draft', label: 'Draft (Fast)' },
            { value: 'preview', label: 'Preview (Balanced)' },
            { value: 'production', label: 'Production (High)' },
            { value: 'cinema', label: 'Cinema (Ultra)' },
          ]}
        />
      </div>

      <Handle type="target" position={Position.Left} />
      <Handle type="source" position={Position.Right} />
    </Card>
  );
};

export default memo(T2VNode);