import React, { memo } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { Card, Select, Slider, Upload, Button } from 'antd';
import { PictureOutlined, UploadOutlined } from '@ant-design/icons';

interface I2VNodeData {
  label: string;
  model: string;
  image?: string;
  motion_scale: number;
  duration: number;
}

const I2VNode: React.FC<NodeProps<I2VNodeData>> = ({ data, selected }) => {
  return (
    <Card
      size="small"
      title={
        <span>
          <PictureOutlined /> {data.label}
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
          defaultValue="Wan2.2-I2V-A14B"
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'Wan2.2-I2V-A14B', label: 'Wan2.2-I2V-A14B (MoE)' },
          ]}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Input Image:</label>
        <Upload>
          <Button icon={<UploadOutlined />} style={{ width: '100%', marginTop: 4 }}>
            Select Image
          </Button>
        </Upload>
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Motion Scale: {data.motion_scale || 1.0}</label>
        <Slider
          min={0.5}
          max={2.0}
          step={0.1}
          defaultValue={data.motion_scale || 1.0}
          marks={{ 0.5: 'Subtle', 1: 'Normal', 2: 'Dynamic' }}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Duration: {data.duration || 5}s</label>
        <Slider
          min={1}
          max={10}
          defaultValue={data.duration || 5}
        />
      </div>

      <Handle type="target" position={Position.Left} />
      <Handle type="source" position={Position.Right} />
    </Card>
  );
};

export default memo(I2VNode);