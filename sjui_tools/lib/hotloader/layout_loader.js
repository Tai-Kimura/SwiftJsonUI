// HotLoader Layout Loader
// This file is served by the Ruby server and provides layout loading functionality

var HotLoader = {
  baseUrl: null,
  wsUrl: null,
  
  init: function() {
    // Get the current host and port from the page location
    var host = window.location.hostname || 'localhost';
    var port = window.location.port || '8081';
    this.baseUrl = 'http://' + host + ':' + port;
    this.wsUrl = 'ws://' + host + ':' + port + '/websocket';
  },
  
  loadLayout: function(layoutName, callback) {
    if (!this.baseUrl) this.init();
    var url = this.baseUrl + '/layout/' + layoutName;
    
    fetch(url)
      .then(function(response) {
        if (!response.ok) {
          throw new Error('Layout not found: ' + layoutName);
        }
        return response.json();
      })
      .then(function(data) {
        callback(null, data);
      })
      .catch(function(error) {
        callback(error, null);
      });
  },
  
  loadLayoutFromPath: function(path, callback) {
    if (!this.baseUrl) this.init();
    var parts = path.split('/');
    var url;
    
    if (parts.length > 1) {
      // Has subfolder
      var folder = parts.slice(0, -1).join('/');
      var name = parts[parts.length - 1];
      url = this.baseUrl + '/layout/' + folder + '/' + name;
    } else {
      // No subfolder
      url = this.baseUrl + '/layout/' + path;
    }
    
    fetch(url)
      .then(function(response) {
        if (!response.ok) {
          throw new Error('Layout not found: ' + path);
        }
        return response.json();
      })
      .then(function(data) {
        callback(null, data);
      })
      .catch(function(error) {
        callback(error, null);
      });
  },
  
  setupWebSocket: function(onUpdate) {
    if (!this.wsUrl) this.init();
    var ws = new WebSocket(this.wsUrl);
    
    ws.onopen = function() {
      console.log('HotLoader WebSocket connected');
    };
    
    ws.onmessage = function(event) {
      var data = JSON.parse(event.data);
      if (data.type === 'file_changed' && onUpdate) {
        onUpdate(data);
      }
    };
    
    ws.onerror = function(error) {
      console.error('HotLoader WebSocket error:', error);
    };
    
    ws.onclose = function() {
      console.log('HotLoader WebSocket disconnected. Attempting to reconnect...');
      // Attempt to reconnect after 3 seconds
      setTimeout(function() {
        HotLoader.setupWebSocket(onUpdate);
      }, 3000);
    };
    
    return ws;
  }
};

// Export for Node.js/CommonJS
if (typeof module !== 'undefined' && module.exports) {
  module.exports = HotLoader;
}

// Export for browser
if (typeof window !== 'undefined') {
  window.HotLoader = HotLoader;
}