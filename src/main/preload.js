const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Window controls
  minimize: () => ipcRenderer.invoke('app:minimize'),
  maximize: () => ipcRenderer.invoke('app:maximize'),
  close: () => ipcRenderer.invoke('app:close'),
  
  // Dialog methods
  openFile: (options) => ipcRenderer.invoke('dialog:openFile', options),
  saveFile: (options) => ipcRenderer.invoke('dialog:saveFile', options),
  
  // File system operations
  readFile: (filePath) => ipcRenderer.invoke('fs:readFile', filePath),
  writeFile: (filePath, data) => ipcRenderer.invoke('fs:writeFile', filePath, data),
  
  // Window events
  onWindowMaximized: (callback) => ipcRenderer.on('window-maximized', callback),
  onWindowUnmaximized: (callback) => ipcRenderer.on('window-unmaximized', callback),
  
  // Menu events
  onMenuAction: (action, callback) => ipcRenderer.on(`menu-${action}`, callback),
  
  // Backend API communication
  sendToBackend: (channel, data) => {
    const validChannels = [
      'generate-video',
      'process-image',
      'apply-effect',
      'export-video',
      'get-project-status'
    ];
    if (validChannels.includes(channel)) {
      return ipcRenderer.invoke(`backend:${channel}`, data);
    }
  },
  
  // System info
  platform: process.platform,
  version: process.versions.electron
});