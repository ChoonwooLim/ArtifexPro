import React, { useEffect, useState } from 'react';
import { Card, Progress, Tag, Space, Button, Typography } from 'antd';
import { 
  CloudDownloadOutlined, 
  CheckCircleOutlined,
  LoadingOutlined,
  WarningOutlined 
} from '@ant-design/icons';

const { Text, Title } = Typography;

interface ModelInfo {
  name: string;
  size: string;
  status: 'downloading' | 'ready' | 'loading' | 'error';
  progress?: number;
  vramRequired: string;
}

const ModelStatus: React.FC = () => {
  const [models, setModels] = useState<ModelInfo[]>([
    {
      name: 'Wan2.2-TI2V-5B',
      size: '32GB',
      status: 'downloading',
      progress: 0,
      vramRequired: '16-20GB'
    },
    {
      name: 'Wan2.2-S2V-14B',
      size: '31GB',
      status: 'downloading',
      progress: 0,
      vramRequired: '20-24GB'
    }
  ]);

  useEffect(() => {
    // 다운로드 진행률 시뮬레이션 (실제로는 백엔드에서 가져옴)
    const interval = setInterval(() => {
      setModels(prev => prev.map(model => {
        if (model.status === 'downloading' && model.progress! < 100) {
          const newProgress = Math.min(model.progress! + Math.random() * 5, 100);
          return {
            ...model,
            progress: newProgress,
            status: newProgress >= 100 ? 'ready' : 'downloading'
          };
        }
        return model;
      }));
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'ready':
        return <CheckCircleOutlined style={{ color: '#52c41a' }} />;
      case 'downloading':
        return <LoadingOutlined style={{ color: '#1890ff' }} />;
      case 'loading':
        return <LoadingOutlined style={{ color: '#faad14' }} />;
      case 'error':
        return <WarningOutlined style={{ color: '#ff4d4f' }} />;
      default:
        return null;
    }
  };

  const getStatusTag = (status: string) => {
    const colors: Record<string, string> = {
      ready: 'success',
      downloading: 'processing',
      loading: 'warning',
      error: 'error'
    };
    
    return (
      <Tag color={colors[status]}>
        {status.toUpperCase()}
      </Tag>
    );
  };

  return (
    <Card title="Model Status" size="small">
      <Space direction="vertical" style={{ width: '100%' }}>
        {models.map((model, index) => (
          <Card 
            key={index} 
            size="small"
            style={{ backgroundColor: '#fafafa' }}
          >
            <Space direction="vertical" style={{ width: '100%' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Space>
                  {getStatusIcon(model.status)}
                  <Text strong>{model.name}</Text>
                </Space>
                {getStatusTag(model.status)}
              </div>
              
              <Space size="small">
                <Text type="secondary">Size: {model.size}</Text>
                <Text type="secondary">|</Text>
                <Text type="secondary">VRAM: {model.vramRequired}</Text>
              </Space>

              {model.status === 'downloading' && (
                <div>
                  <Progress 
                    percent={Math.round(model.progress || 0)} 
                    status="active"
                    strokeColor={{
                      '0%': '#108ee9',
                      '100%': '#87d068',
                    }}
                  />
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    {((model.progress || 0) * 0.32).toFixed(1)} GB / {model.size}
                  </Text>
                </div>
              )}

              {model.status === 'ready' && (
                <Space>
                  <Button 
                    type="primary" 
                    size="small"
                    icon={<CloudDownloadOutlined />}
                  >
                    Load Model
                  </Button>
                  <Text type="success">Ready to use</Text>
                </Space>
              )}
            </Space>
          </Card>
        ))}

        <div style={{ marginTop: 16, padding: 12, backgroundColor: '#e6f7ff', borderRadius: 4 }}>
          <Text strong>RTX 3090 (24GB VRAM) Status:</Text>
          <div style={{ marginTop: 8 }}>
            <Text>✅ TI2V-5B: Fully compatible</Text>
            <br />
            <Text>✅ S2V-14B: Compatible with CPU offloading</Text>
          </div>
        </div>
      </Space>
    </Card>
  );
};

export default ModelStatus;