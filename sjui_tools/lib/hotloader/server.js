const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const path = require('path');
const fs = require('fs');
const chokidar = require('chokidar');
const { exec } = require('child_process');

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
    
    // Legacy layout download endpoint (for compatibility with HotLoader client)
    this.app.get('/*', (req, res) => {
      const filePath = req.query.file_path;
      const dirName = req.query.dir_name;
      
      if (!filePath || !dirName) {
        return res.status(400).send('Missing file_path or dir_name parameter');
      }
      
      const projectRoot = this.findProjectRoot();
      let fullPath;
      
      switch(dirName) {
        case 'styles':
          fullPath = path.join(projectRoot, 'Styles', `${filePath}.json`);
          break;
        case 'scripts':
          fullPath = path.join(projectRoot, 'Scripts', `${filePath}.js`);
          break;
        default:
          fullPath = path.join(projectRoot, 'Layouts', `${filePath}.json`);
      }
      
      if (fs.existsSync(fullPath)) {
        const content = fs.readFileSync(fullPath);
        res.type('application/octet-stream').send(content);
      } else {
        res.status(404).send(`File not found: ${fullPath}`);
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
    // Extract file info from path
    const relativePath = path.relative(this.findProjectRoot(), file);
    const parts = relativePath.split(path.sep);
    const dirName = parts[0].toLowerCase(); // "Layouts" -> "layouts"
    const fileName = path.basename(file, path.extname(file)); // Remove extension
    
    // Format message as array of strings (compatible with client)
    const message = JSON.stringify([
      relativePath,  // layoutPath
      dirName,       // dirName
      fileName       // fileName without extension
    ]);
    
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
      .on('change', filePath => {
        console.log(`File ${filePath} has been changed`);
        this.notifyClients(filePath, 'changed');
        
        // Run sjui build if layout file changed
        if (filePath.includes('/Layouts/') && filePath.endsWith('.json')) {
          this.runBuildCommand();
        }
      })
      .on('unlink', path => {
        console.log(`File ${path} has been removed`);
        this.notifyClients(path, 'removed');
      });
    
    console.log(`Watching directories: ${layoutsDir}, ${stylesDir}`);
  }

  runBuildCommand() {
    console.log('Layout file changed, running sjui build...');
    
    const projectRoot = this.findProjectRoot();
    
    // Try to use globally installed sjui first, then look for local installation
    exec(`cd "${projectRoot}" && which sjui`, (error, stdout, stderr) => {
      let sjuiCommand = 'sjui';
      
      if (error) {
        // If global sjui not found, try to find it in the project's sjui_tools
        const localSjuiPath = path.join(projectRoot, 'sjui_tools', 'bin', 'sjui');
        if (fs.existsSync(localSjuiPath)) {
          sjuiCommand = localSjuiPath;
        } else {
          console.error('sjui command not found. Please ensure sjui is installed.');
          return;
        }
      } else {
        sjuiCommand = stdout.trim();
      }
      
      // Run the build command
      exec(`cd "${projectRoot}" && "${sjuiCommand}" build`, (error, stdout, stderr) => {
        if (error) {
          console.error(`Error running sjui build: ${error.message}`);
          return;
        }
        if (stderr) {
          console.error(`sjui build stderr: ${stderr}`);
        }
        if (stdout) {
          console.log(`sjui build output: ${stdout}`);
        }
        console.log('sjui build completed');
      });
    });
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