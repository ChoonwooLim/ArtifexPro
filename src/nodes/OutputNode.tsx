import React, { memo } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { Card, Select, Input } from 'antd';
import { SaveOutlined } from '@ant-design/icons';

interface OutputNodeData {
  label: string;
  format: string;
  codec: string;
  filename?: string;
}

const OutputNode: React.FC<NodeProps<OutputNodeData>> = ({ data, selected }) => {
  return (
    <Card
      size="small"
      title={
        <span>
          <SaveOutlined /> {data.label}
        </span>
      }
      style={{
        width: 250,
        border: selected ? '2px solid #52c41a' : '1px solid #d9d9d9',
        backgroundColor: selected ? '#f6ffed' : 'white',
      }}
    >
      <div style={{ padding: '8px 0' }}>
        <label>Format:</label>
        <Select
          defaultValue={data.format || 'mp4'}
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'mp4', label: 'MP4' },
            { value: 'mov', label: 'MOV' },
            { value: 'webm', label: 'WebM' },
            { value: 'avi', label: 'AVI' },
          ]}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Codec:</label>
        <Select
          defaultValue={data.codec || 'h265'}
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'h264', label: 'H.264 (Compatibility)' },
            { value: 'h265', label: 'H.265 (Quality)' },
            { value: 'av1', label: 'AV1 (Future)' },
            { value: 'prores', label: 'ProRes (Pro)' },
          ]}
        />
      </div>

      <div style={{ padding: '8px 0' }}>
        <label>Filename:</label>
        <Input
          placeholder="output_video"
          style={{ marginTop: 4 }}
        />
      </div>

      <Handle type="target" position={Position.Left} />
    </Card>
  );
};

export default memo(OutputNode);