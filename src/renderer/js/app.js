/**
 * ArtifexPro Studio - Main Application JavaScript
 * Professional Video Editing Suite with AI Generation
 */

class ArtifexPro {
    constructor() {
        this.currentProject = null;
        this.timeline = null;
        this.preview = null;
        this.selectedTool = 'select';
        this.isPlaying = false;
        this.currentTime = 0;
        this.duration = 0;
        this.zoomLevel = 100;
        
        this.init();
    }
    
    async init() {
        await this.setupUI();
        await this.initializeTimeline();
        await this.initializePreview();
        await this.connectBackend();
        this.bindEvents();
        this.loadProject();
    }
    
    async setupUI() {
        // Window controls
        document.getElementById('minimize-btn').addEventListener('click', () => {
            window.electronAPI.minimize();
        });
        
        document.getElementById('maximize-btn').addEventListener('click', () => {
            window.electronAPI.maximize();
        });
        
        document.getElementById('close-btn').addEventListener('click', () => {
            window.electronAPI.close();
        });
        
        // Tab switching
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.switchTab(e.target);
            });
        });
        
        // Tool selection
        document.querySelectorAll('.tool-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.selectTool(e.target.dataset.tool);
            });
        });
    }
    
    switchTab(tabBtn) {
        const container = tabBtn.closest('.sidebar');
        const tabName = tabBtn.dataset.tab;
        
        // Update active tab
        container.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        tabBtn.classList.add('active');
        
        // Update active panel
        container.querySelectorAll('.panel').forEach(panel => {
            panel.classList.remove('active');
        });
        container.querySelector(`#${tabName}-panel`).classList.add('active');
    }
    
    selectTool(toolName) {
        this.selectedTool = toolName;
        document.querySelectorAll('.tool-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tool === toolName);
        });
    }
    
    async initializeTimeline() {
        this.timeline = new Timeline('timeline');
        
        // Timeline zoom controls
        const zoomSlider = document.getElementById('timeline-zoom');
        zoomSlider.addEventListener('input', (e) => {
            this.setZoomLevel(e.target.value);
        });
        
        document.getElementById('zoom-in').addEventListener('click', () => {
            this.setZoomLevel(Math.min(200, this.zoomLevel + 10));
        });
        
        document.getElementById('zoom-out').addEventListener('click', () => {
            this.setZoomLevel(Math.max(10, this.zoomLevel - 10));
        });
    }
    
    setZoomLevel(level) {
        this.zoomLevel = level;
        document.getElementById('timeline-zoom').value = level;
        if (this.timeline) {
            this.timeline.setZoom(level);
        }
    }
    
    async initializePreview() {
        const canvas = document.getElementById('preview-canvas');
        this.preview = new VideoPreview(canvas);
        
        // Playback controls
        document.getElementById('play-pause').addEventListener('click', () => {
            this.togglePlayback();
        });
        
        document.getElementById('play-start').addEventListener('click', () => {
            this.seekTo(0);
        });
        
        document.getElementById('play-end').addEventListener('click', () => {
            this.seekTo(this.duration);
        });
        
        document.getElementById('play-backward').addEventListener('click', () => {
            this.seekTo(Math.max(0, this.currentTime - 5));
        });
        
        document.getElementById('play-forward').addEventListener('click', () => {
            this.seekTo(Math.min(this.duration, this.currentTime + 5));
        });
    }
    
    togglePlayback() {
        this.isPlaying = !this.isPlaying;
        const playBtn = document.getElementById('play-pause');
        const icon = playBtn.querySelector('use');
        icon.setAttribute('href', this.isPlaying ? '#icon-pause' : '#icon-play');
        
        if (this.isPlaying) {
            this.startPlayback();
        } else {
            this.stopPlayback();
        }
    }
    
    startPlayback() {
        if (!this.playbackInterval) {
            this.playbackInterval = setInterval(() => {
                this.currentTime += 1/30; // 30 fps
                if (this.currentTime >= this.duration) {
                    this.currentTime = this.duration;
                    this.togglePlayback();
                }
                this.updateTimecode();
                this.updatePlayhead();
            }, 1000/30);
        }
    }
    
    stopPlayback() {
        if (this.playbackInterval) {
            clearInterval(this.playbackInterval);
            this.playbackInterval = null;
        }
    }
    
    seekTo(time) {
        this.currentTime = Math.max(0, Math.min(this.duration, time));
        this.updateTimecode();
        this.updatePlayhead();
        if (this.preview) {
            this.preview.seekTo(this.currentTime);
        }
    }
    
    updateTimecode() {
        const hours = Math.floor(this.currentTime / 3600);
        const minutes = Math.floor((this.currentTime % 3600) / 60);
        const seconds = Math.floor(this.currentTime % 60);
        const frames = Math.floor((this.currentTime % 1) * 30);
        
        const timecode = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}:${String(frames).padStart(2, '0')}`;
        document.getElementById('timecode').textContent = timecode;
    }
    
    updatePlayhead() {
        const playhead = document.getElementById('playhead');
        if (playhead && this.duration > 0) {
            const position = (this.currentTime / this.duration) * 100;
            playhead.style.left = `${position}%`;
        }
    }
    
    async connectBackend() {
        // Initialize Socket.IO connection
        this.socket = io('http://localhost:5000');
        
        this.socket.on('connect', () => {
            console.log('Connected to backend');
            this.updateStatus('Connected to AI Engine');
        });
        
        this.socket.on('generation_progress', (data) => {
            this.updateGenerationProgress(data.percent, data.message);
        });
        
        this.socket.on('disconnect', () => {
            console.log('Disconnected from backend');
            this.updateStatus('Disconnected from AI Engine');
        });
    }
    
    bindEvents() {
        // Import media
        document.getElementById('import-media').addEventListener('click', async () => {
            const result = await window.electronAPI.openFile({
                title: 'Import Media',
                filters: [
                    { name: 'Media Files', extensions: ['mp4', 'avi', 'mov', 'jpg', 'png', 'wav', 'mp3'] },
                    { name: 'All Files', extensions: ['*'] }
                ],
                properties: ['openFile', 'multiSelections']
            });
            
            if (!result.canceled) {
                this.importMedia(result.filePaths);
            }
        });
        
        // AI Generation
        document.getElementById('generate-video').addEventListener('click', () => {
            this.generateVideo();
        });
        
        // Menu events
        window.electronAPI.onMenuAction('new-project', () => this.newProject());
        window.electronAPI.onMenuAction('open-project', () => this.openProject());
        window.electronAPI.onMenuAction('save-project', () => this.saveProject());
        window.electronAPI.onMenuAction('import-media', () => this.importMediaDialog());
        window.electronAPI.onMenuAction('export-video', () => this.exportVideo());
        window.electronAPI.onMenuAction('preferences', () => this.showPreferences());
        window.electronAPI.onMenuAction('ai-generator', () => this.showAIGenerator());
        window.electronAPI.onMenuAction('effects-library', () => this.showEffectsLibrary());
        window.electronAPI.onMenuAction('color-grading', () => this.showColorGrading());
        window.electronAPI.onMenuAction('audio-mixer', () => this.showAudioMixer());
        window.electronAPI.onMenuAction('shortcuts', () => this.showShortcuts());
        window.electronAPI.onMenuAction('about', () => this.showAbout());
    }
    
    async generateVideo() {
        const mode = document.getElementById('ai-mode').value;
        const prompt = document.getElementById('ai-prompt').value;
        const duration = document.getElementById('ai-duration').value;
        const quality = document.getElementById('ai-quality').value;
        
        if (!prompt) {
            alert('Please enter a prompt for video generation');
            return;
        }
        
        // Show progress bar
        const progressBar = document.getElementById('generation-progress');
        progressBar.classList.remove('hidden');
        
        // Prepare generation parameters
        const params = {
            task: mode === 't2v' ? 't2v-A14B' : mode === 'i2v' ? 'i2v-A14B' : 's2v-14B',
            prompt: prompt,
            duration: parseInt(duration),
            quality: quality
        };
        
        try {
            const response = await fetch('http://localhost:5000/api/generate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(params)
            });
            
            const result = await response.json();
            
            if (result.success) {
                this.updateStatus('Video generated successfully!');
                // Import generated video to timeline
                this.importGeneratedVideo(result.output_path);
            } else {
                this.updateStatus('Generation failed: ' + result.error);
            }
        } catch (error) {
            console.error('Generation error:', error);
            this.updateStatus('Generation failed: ' + error.message);
        } finally {
            progressBar.classList.add('hidden');
        }
    }
    
    updateGenerationProgress(percent, message) {
        const progressFill = document.querySelector('.progress-fill');
        const progressText = document.querySelector('.progress-text');
        
        progressFill.style.width = `${percent}%`;
        progressText.textContent = `${percent}% - ${message}`;
    }
    
    importMedia(filePaths) {
        filePaths.forEach(filePath => {
            const fileName = filePath.split(/[\\/]/).pop();
            const mediaItem = this.createMediaItem(fileName, filePath);
            document.getElementById('media-library').appendChild(mediaItem);
        });
        this.updateStatus(`Imported ${filePaths.length} media file(s)`);
    }
    
    createMediaItem(name, path) {
        const item = document.createElement('div');
        item.className = 'media-item';
        item.innerHTML = `
            <div class="media-thumbnail">
                <img src="${this.getMediaThumbnail(path)}" alt="${name}">
            </div>
            <div class="media-name">${name}</div>
        `;
        item.dataset.path = path;
        item.addEventListener('dragstart', (e) => {
            e.dataTransfer.setData('media-path', path);
        });
        item.draggable = true;
        return item;
    }
    
    getMediaThumbnail(path) {
        // In production, generate actual thumbnails
        return 'assets/media-placeholder.png';
    }
    
    importGeneratedVideo(outputPath) {
        // Add generated video to timeline
        if (this.timeline) {
            this.timeline.addClip({
                path: outputPath,
                track: 'v1',
                startTime: this.currentTime,
                duration: 5 // Default duration
            });
        }
    }
    
    updateStatus(message) {
        document.getElementById('status-message').textContent = message;
    }
    
    newProject() {
        this.currentProject = {
            name: 'Untitled Project',
            created: new Date(),
            timeline: [],
            settings: {}
        };
        document.getElementById('project-name').textContent = this.currentProject.name;
        this.updateStatus('New project created');
    }
    
    async openProject() {
        const result = await window.electronAPI.openFile({
            title: 'Open Project',
            filters: [
                { name: 'ArtifexPro Project', extensions: ['apx'] },
                { name: 'All Files', extensions: ['*'] }
            ],
            properties: ['openFile']
        });
        
        if (!result.canceled) {
            const projectData = await window.electronAPI.readFile(result.filePaths[0]);
            if (projectData.success) {
                this.currentProject = JSON.parse(projectData.data);
                this.loadProject();
            }
        }
    }
    
    async saveProject() {
        if (!this.currentProject) {
            this.newProject();
        }
        
        const result = await window.electronAPI.saveFile({
            title: 'Save Project',
            defaultPath: `${this.currentProject.name}.apx`,
            filters: [
                { name: 'ArtifexPro Project', extensions: ['apx'] }
            ]
        });
        
        if (!result.canceled) {
            const projectData = JSON.stringify(this.currentProject, null, 2);
            await window.electronAPI.writeFile(result.filePath, projectData);
            this.updateStatus('Project saved');
        }
    }
    
    loadProject() {
        if (!this.currentProject) {
            this.newProject();
        }
        
        document.getElementById('project-name').textContent = this.currentProject.name;
        
        // Load timeline
        if (this.timeline && this.currentProject.timeline) {
            this.timeline.loadData(this.currentProject.timeline);
        }
        
        this.updateStatus('Project loaded');
    }
    
    async exportVideo() {
        // Show export dialog
        const exportSettings = {
            format: 'mp4',
            resolution: '1080p',
            framerate: 30,
            bitrate: '10M',
            codec: 'h264'
        };
        
        // In production, show proper export dialog
        const confirmed = confirm('Export video with default settings?');
        if (!confirmed) return;
        
        try {
            const response = await fetch('http://localhost:5000/api/export', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    input_path: this.currentProject?.timeline?.[0]?.path || '',
                    settings: exportSettings
                })
            });
            
            const result = await response.json();
            if (result.success) {
                this.updateStatus('Video exported successfully');
            }
        } catch (error) {
            console.error('Export error:', error);
            this.updateStatus('Export failed: ' + error.message);
        }
    }
    
    showAIGenerator() {
        this.switchTab(document.querySelector('[data-tab="ai-tools"]'));
    }
    
    showEffectsLibrary() {
        this.switchTab(document.querySelector('[data-tab="effects"]'));
    }
    
    showColorGrading() {
        this.switchTab(document.querySelector('[data-tab="color"]'));
    }
    
    showAudioMixer() {
        // In production, show audio mixer panel
        this.updateStatus('Audio mixer coming soon');
    }
    
    showPreferences() {
        // In production, show preferences dialog
        this.updateStatus('Preferences coming soon');
    }
    
    showShortcuts() {
        // In production, show keyboard shortcuts
        alert('Keyboard Shortcuts:\n\nCtrl+N - New Project\nCtrl+O - Open Project\nCtrl+S - Save Project\nCtrl+I - Import Media\nCtrl+E - Export Video\nSpace - Play/Pause\nCtrl+G - AI Generator');
    }
    
    showAbout() {
        alert('ArtifexPro Studio v1.0.0\n\nProfessional AI-Powered Video Generation & Editing Suite\n\nPowered by Wan2.2 AI Engine\n\n© 2024 ArtifexPro Team');
    }
}

// Timeline class
class Timeline {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.tracks = [];
        this.clips = [];
        this.zoom = 100;
    }
    
    setZoom(level) {
        this.zoom = level;
        this.render();
    }
    
    addClip(clipData) {
        this.clips.push(clipData);
        this.render();
    }
    
    loadData(timelineData) {
        this.clips = timelineData;
        this.render();
    }
    
    render() {
        // Render timeline clips
        this.clips.forEach(clip => {
            this.renderClip(clip);
        });
    }
    
    renderClip(clip) {
        const track = document.querySelector(`[data-track="${clip.track}"] .track-content`);
        if (!track) return;
        
        const clipElement = document.createElement('div');
        clipElement.className = 'timeline-clip';
        clipElement.style.left = `${clip.startTime * this.zoom}px`;
        clipElement.style.width = `${clip.duration * this.zoom}px`;
        clipElement.textContent = clip.path.split(/[\\/]/).pop();
        
        track.appendChild(clipElement);
    }
}

// Video Preview class
class VideoPreview {
    constructor(canvas) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.video = null;
        
        this.setupCanvas();
    }
    
    setupCanvas() {
        // Set canvas size
        this.canvas.width = 1920;
        this.canvas.height = 1080;
        
        // Draw placeholder
        this.ctx.fillStyle = '#000';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        this.ctx.fillStyle = '#444';
        this.ctx.font = '48px Arial';
        this.ctx.textAlign = 'center';
        this.ctx.fillText('No Video Loaded', this.canvas.width/2, this.canvas.height/2);
    }
    
    loadVideo(path) {
        this.video = document.createElement('video');
        this.video.src = path;
        this.video.addEventListener('loadeddata', () => {
            this.render();
        });
    }
    
    seekTo(time) {
        if (this.video) {
            this.video.currentTime = time;
            this.render();
        }
    }
    
    render() {
        if (this.video) {
            this.ctx.drawImage(this.video, 0, 0, this.canvas.width, this.canvas.height);
        }
    }
}

// Initialize application
document.addEventListener('DOMContentLoaded', () => {
    window.app = new ArtifexPro();
});