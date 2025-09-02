import React from 'react';
import { ConfigProvider, theme, App as AntApp } from 'antd';
import Wan22Professional from './components/Wan22Professional';
import './App.css';

const App: React.FC = () => {
  // WAN2.2 Professional Studio 사용
  return (
    <ConfigProvider
      theme={{
        algorithm: theme.darkAlgorithm,
        token: {
          colorPrimary: '#667eea',
        },
      }}
    >
      <AntApp>
        <Wan22Professional />
      </AntApp>
    </ConfigProvider>
  );
};

export default App;