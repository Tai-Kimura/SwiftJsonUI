const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const path = require('path');
const fs = require('fs');
const chokidar = require('chokidar');

class HotLoaderServer {
  constructor(options = {}) {
    this.port = process.env.PORT || options.port || 8081;
    this.ip = this.getLocalIp() || '0.0.0.0';
    this.clients = new Set();
    this.app = express();
    this.server = http.createServer(this.app);
    this.wss = new WebSocket.Server({ server: this.server });
    
    this.setupRoutes();
    this.setupWebSocket();
  }

  getLocalIp() {
    const { networkInterfaces } = require('os');
    const nets = networkInterfaces();
    
    // Try en0 first (common for macOS Wi-Fi)
    if (nets.en0) {
      const en0 = nets.en0.find(net => net.family === 'IPv4' && !net.internal);
      if (en0) return en0.address;
    }
    
    // Try other interfaces
    for (const name of Object.keys(nets)) {
      for (const net of nets[name]) {
        if (net.family === 'IPv4' && !net.internal && !net.address.startsWith('169.254')) {
          return net.address;
        }
      }
    }
    
    return null;
  }

  setupRoutes() {
    // Enable CORS
    this.app.use((req, res, next) => {
      res.header('Access-Control-Allow-Origin', '*');
      res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
      next();
    });

    // Root endpoint
    this.app.get('/', (req, res) => {
      console.log(`HTTP request to / from: ${req.ip}`);
      res.send('SwiftJsonUI HotLoader Server');
    });

    // Layout API
    this.app.get('/layout/:name', (req, res) => {
      const layoutName = req.params.name;
      const projectRoot = this.findProjectRoot();
      const layoutsDir = path.join(projectRoot, 'Layouts');
      const layoutFile = path.join(layoutsDir, `${layoutName}.json`);
      
      if (fs.existsSync(layoutFile)) {
        res.json(JSON.parse(fs.readFileSync(layoutFile, 'utf8')));
      } else {
        res.status(404).json({ error: `Layout not found: ${layoutName}` });
      }
    });
  }

  setupWebSocket() {
    this.wss.on('connection', (ws, req) => {
      const clientIp = req.socket.remoteAddress;
      console.log(`WebSocket client connected from ${clientIp} (Total: ${this.wss.clients.size})`);
      
      ws.on('close', () => {
        console.log(`WebSocket client disconnected (Total: ${this.wss.clients.size})`);
      });
      
      ws.on('error', (error) => {
        console.error('WebSocket error:', error);
      });
    });
  }

  notifyClients(file, changeType) {
    const message = JSON.stringify({
      type: 'file_changed',
      file: file,
      change_type: changeType,
      timestamp: Date.now()
    });
    
    this.wss.clients.forEach(client => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });
    
    console.log(`Notified ${this.wss.clients.size} clients`);
  }

  findProjectRoot() {
    // Find project root by looking for sjui.config.json
    let currentDir = process.cwd();
    while (currentDir !== '/') {
      if (fs.existsSync(path.join(currentDir, 'sjui.config.json'))) {
        return currentDir;
      }
      currentDir = path.dirname(currentDir);
    }
    return process.cwd();
  }

  setupFileWatcher() {
    const projectRoot = this.findProjectRoot();
    const layoutsDir = path.join(projectRoot, 'Layouts');
    const stylesDir = path.join(projectRoot, 'Styles');
    
    const watcher = chokidar.watch([layoutsDir, stylesDir], {
      ignored: /(^|[\/\\])\../,
      persistent: true
    });
    
    watcher
      .on('add', path => console.log(`File ${path} has been added`))
      .on('change', path => {
        console.log(`File ${path} has been changed`);
        this.notifyClients(path, 'changed');
      })
      .on('unlink', path => {
        console.log(`File ${path} has been removed`);
        this.notifyClients(path, 'removed');
      });
    
    console.log(`Watching directories: ${layoutsDir}, ${stylesDir}`);
  }

  start() {
    this.server.listen(this.port, this.ip, () => {
      console.log(`Starting HotLoader server on ${this.ip}:${this.port}...`);
      console.log(`WebSocket endpoint: ws://${this.ip}:${this.port}/`);
      console.log(`Layout API: http://${this.ip}:${this.port}/layout/:name`);
      console.log('Press Ctrl+C to stop');
    });
    
    this.setupFileWatcher();
  }
}

// Start server
const server = new HotLoaderServer();
server.start();