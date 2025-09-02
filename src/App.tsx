import React, { useState } from 'react';
import { ConfigProvider, Layout, theme, Button, Space } from 'antd';
import NodeEditor from './components/NodeEditor';
import Timeline from './components/Timeline';
import Sidebar from './components/Sidebar';
import { SimpleGenerator } from './components/SimpleGenerator';
import './App.css';

const { Header, Sider, Content } = Layout;

const App: React.FC = () => {
  const [view, setView] = useState<'simple' | 'advanced'>('simple');
  const { token } = theme.useToken();

  return (
    <ConfigProvider
      theme={{
        algorithm: theme.darkAlgorithm,
        token: {
          colorPrimary: '#1890ff',
        },
      }}
    >
      <Layout style={{ height: '100vh' }}>
        <Header style={{ 
          background: token.colorBgContainer, 
          padding: '0 24px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          borderBottom: '1px solid rgba(255,255,255,0.1)'
        }}>
          <h1 style={{ color: token.colorText, margin: 0 }}>
            ArtifexPro Studio - AI Video Generation
          </h1>
          <Space>
            <Button 
              type={view === 'simple' ? 'primary' : 'default'}
              onClick={() => setView('simple')}
            >
              Simple Mode
            </Button>
            <Button 
              type={view === 'advanced' ? 'primary' : 'default'}
              onClick={() => setView('advanced')}
            >
              Advanced Mode
            </Button>
          </Space>
        </Header>
        
        {view === 'simple' ? (
          <Content style={{ overflow: 'auto' }}>
            <SimpleGenerator />
          </Content>
        ) : (
          <Layout>
            <Sider width={300} style={{ background: token.colorBgContainer }}>
              <Sidebar />
            </Sider>
            
            <Content style={{ display: 'flex', flexDirection: 'column' }}>
              <div style={{ flex: 1, minHeight: 0 }}>
                <NodeEditor />
              </div>
              <div style={{ height: '300px', borderTop: '1px solid rgba(255,255,255,0.1)' }}>
                <Timeline />
              </div>
            </Content>
          </Layout>
        )}
      </Layout>
    </ConfigProvider>
  );
};

export default App;