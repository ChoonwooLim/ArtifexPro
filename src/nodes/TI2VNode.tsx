import React, { memo } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { Card, Input, Upload, Button, Slider, Select } from 'antd';
import { FileImageOutlined, UploadOutlined } from '@ant-design/icons';

const { TextArea } = Input;

interface TI2VNodeData {
  label: string;
  model: string;
  image?: string;
  prompt: string;
  duration: number;
}

const TI2VNode: React.FC<NodeProps<TI2VNodeData>> = ({ data, selected }) => {
  return (
    <Card
      size="small"
      title={
        <span>
          <FileImageOutlined /> {data.label}
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
          defaultValue="Wan2.2-TI2V-5B"
          style={{ width: '100%', marginTop: 4 }}
          options={[
            { value: 'Wan2.2-TI2V-5B', label: 'Wan2.2-TI2V-5B (RTX 4090)' },
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
        <label>Text Prompt:</label>
        <TextArea
          placeholder="Describe the motion and style..."
          rows={2}
          style={{ marginTop: 4 }}
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

export default memo(TI2VNode);