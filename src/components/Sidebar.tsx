import React from 'react';
import { Card, Button, Space, Divider, Typography, Progress, Tag } from 'antd';
import {
  AudioOutlined,
  FileImageOutlined,
  ExpandOutlined,
  SaveOutlined,
  ThunderboltOutlined,
  CloudServerOutlined,
} from '@ant-design/icons';
import ModelStatus from './ModelStatus';

const { Title, Text } = Typography;

const Sidebar: React.FC = () => {
  const onDragStart = (event: React.DragEvent, nodeType: string) => {
    event.dataTransfer.setData('application/reactflow', nodeType);
    event.dataTransfer.effectAllowed = 'move';
  };

  const nodeTypes = [
    { type: 'ti2v', icon: <FileImageOutlined />, label: 'TI2V-5B (Text+Image)', color: '#722ed1', available: true },
    { type: 's2v', icon: <AudioOutlined />, label: 'S2V-14B (Audio)', color: '#fa8c16', available: true },
    { type: 'upscale', icon: <ExpandOutlined />, label: 'AI Upscale', color: '#13c2c2', available: true },
    { type: 'output', icon: <SaveOutlined />, label: 'Output', color: '#52c41a', available: true },
  ];

  return (
    <div style={{ padding: 16, height: '100%', overflowY: 'auto' }}>
      <Title level={4} style={{ marginBottom: 16 }}>Node Library</Title>
      
      <Space direction="vertical" style={{ width: '100%' }}>
        {nodeTypes.map((node) => (
          <Button
            key={node.type}
            icon={node.icon}
            style={{ 
              width: '100%', 
              justifyContent: 'flex-start',
              borderColor: node.color,
              color: node.color
            }}
            draggable
            onDragStart={(e) => onDragStart(e, node.type)}
          >
            {node.label}
          </Button>
        ))}
      </Space>

      <Divider />

      <Card size="small" title="System Status">
        <Space direction="vertical" style={{ width: '100%' }}>
          <div>
            <Text>Pop!_OS Backend</Text>
            <Tag color="success" style={{ float: 'right' }}>
              <CloudServerOutlined /> Connected
            </Tag>
          </div>
          
          <div>
            <Text>GPU (RTX 3090)</Text>
            <Progress percent={35} size="small" status="active" />
            <Text type="secondary" style={{ fontSize: 12 }}>
              8.4GB / 24GB VRAM
            </Text>
          </div>

          <div>
            <Text>Active Jobs</Text>
            <Tag color="processing" style={{ float: 'right' }}>
              <ThunderboltOutlined /> 2 Running
            </Tag>
          </div>
        </Space>
      </Card>

      <Divider />

      <ModelStatus />
    </div>
  );
};

export default Sidebar;