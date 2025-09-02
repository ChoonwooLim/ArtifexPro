import React, { memo } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { Card, Upload, Button, Select, Slider } from 'antd';
import { AudioOutlined, UploadOutlined } from '@ant-design/icons';

interface S2VNodeData {
  label: string;
  model: string;
  audio?: string;
  style: string;
  duration: number;
}

const S2VNode: React.FC<NodeProps<S2VNodeData>> = ({ data, selected }) => {
  return (
    <Card
      size="small"
      title={
        <span>
          <AudioOutlined /> {data.label}
        </span>
      }
      style={{
        width: 280,
        border: selected ? '2px solid #1890ff' : '1px solid #d9d9d9',
      }}
    >
      <div style={{ padding: '8px 0' }}>
        <label>Model:</label>
        <Select
          defaultValue="Wan2.2-S2V-14B"
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'Wan2.2-S2V-14B', label: 'Wan2.2-S2V-14B' },
          ]}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Audio Input:</label>
        <Upload>
          <Button icon={<UploadOutlined />} style={{ width: '100%', marginTop: 4 }}>
            Select Audio
          </Button>
        </Upload>
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Visual Style:</label>
        <Select
          defaultValue="cinematic"
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'cinematic', label: 'Cinematic' },
            { value: 'abstract', label: 'Abstract' },
            { value: 'realistic', label: 'Realistic' },
            { value: 'animated', label: 'Animated' },
          ]}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Duration: Auto</label>
        <Slider
          disabled
          defaultValue={5}
          tooltip={{ formatter: () => 'Auto-sync with audio' }}
        />
      </div>

      <Handle type="target" position={Position.Left} />
      <Handle type="source" position={Position.Right} />
    </Card>
  );
};

export default memo(S2VNode);