import React, { memo } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { Card, Select, Slider } from 'antd';
import { ExpandOutlined } from '@ant-design/icons';

interface UpscaleNodeData {
  label: string;
  scale: number;
  model: string;
}

const UpscaleNode: React.FC<NodeProps<UpscaleNodeData>> = ({ data, selected }) => {
  return (
    <Card
      size="small"
      title={
        <span>
          <ExpandOutlined /> {data.label}
        </span>
      }
      style={{
        width: 250,
        border: selected ? '2px solid #1890ff' : '1px solid #d9d9d9',
      }}
    >
      <div style={{ padding: '8px 0' }}>
        <label>Upscale Model:</label>
        <Select
          defaultValue={data.model || 'RealESRGAN'}
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'RealESRGAN', label: 'RealESRGAN' },
            { value: 'ESRGAN', label: 'ESRGAN' },
            { value: 'Topaz', label: 'Topaz AI' },
          ]}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Scale: {data.scale || 2}x</label>
        <Slider
          min={1}
          max={4}
          defaultValue={data.scale || 2}
          marks={{ 1: '1x', 2: '2x', 3: '3x', 4: '4x' }}
        />
      </div>

      <Handle type="target" position={Position.Left} />
      <Handle type="source" position={Position.Right} />
    </Card>
  );
};

export default memo(UpscaleNode);