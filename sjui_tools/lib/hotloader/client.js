// HotLoader Client
// This file provides client-side functionality for hot reloading

(function() {
  'use strict';
  
  var HotLoaderClient = {
    ws: null,
    layoutCache: {},
    updateCallbacks: [],
    
    init: function(options) {
      options = options || {};
      this.serverUrl = options.serverUrl || 'localhost:8080';
      this.autoReconnect = options.autoReconnect !== false;
      
      this.connectWebSocket();
    },
    
    connectWebSocket: function() {
      var self = this;
      var wsUrl = 'ws://' + this.serverUrl + '/websocket';
      
      try {
        this.ws = new WebSocket(wsUrl);
        
        this.ws.onopen = function() {
          console.log('HotLoader connected to server');
          self.onConnected();
        };
        
        this.ws.onmessage = function(event) {
          self.handleMessage(JSON.parse(event.data));
        };
        
        this.ws.onerror = function(error) {
          console.error('HotLoader WebSocket error:', error);
        };
        
        this.ws.onclose = function() {
          console.log('HotLoader disconnected from server');
          self.onDisconnected();
          
          if (self.autoReconnect) {
            setTimeout(function() {
              console.log('Attempting to reconnect...');
              self.connectWebSocket();
            }, 3000);
          }
        };
      } catch (error) {
        console.error('Failed to connect to HotLoader server:', error);
      }
    },
    
    handleMessage: function(message) {
      console.log('HotLoader received message:', message);
      
      if (message.type === 'file_changed') {
        this.invalidateCache(message.file);
        this.notifyUpdateCallbacks(message);
      }
    },
    
    invalidateCache: function(file) {
      // Remove from cache any layouts that might be affected
      var fileName = file.split('/').pop().replace('.json', '');
      delete this.layoutCache[fileName];
    },
    
    notifyUpdateCallbacks: function(message) {
      this.updateCallbacks.forEach(function(callback) {
        try {
          callback(message);
        } catch (error) {
          console.error('Error in update callback:', error);
        }
      });
    },
    
    onUpdate: function(callback) {
      if (typeof callback === 'function') {
        this.updateCallbacks.push(callback);
      }
    },
    
    removeUpdateCallback: function(callback) {
      var index = this.updateCallbacks.indexOf(callback);
      if (index > -1) {
        this.updateCallbacks.splice(index, 1);
      }
    },
    
    loadLayout: function(layoutName, callback) {
      var self = this;
      
      // Check cache first
      if (this.layoutCache[layoutName]) {
        callback(null, this.layoutCache[layoutName]);
        return;
      }
      
      // Load from server
      var url = 'http://' + this.serverUrl + '/layout/' + layoutName;
      
      var xhr = new XMLHttpRequest();
      xhr.open('GET', url, true);
      xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
          if (xhr.status === 200) {
            try {
              var data = JSON.parse(xhr.responseText);
              self.layoutCache[layoutName] = data;
              callback(null, data);
            } catch (error) {
              callback(error, null);
            }
          } else {
            callback(new Error('Failed to load layout: ' + layoutName), null);
          }
        }
      };
      xhr.send();
    },
    
    onConnected: function() {
      // Override this method to handle connection events
    },
    
    onDisconnected: function() {
      // Override this method to handle disconnection events
    },
    
    disconnect: function() {
      this.autoReconnect = false;
      if (this.ws) {
        this.ws.close();
      }
    }
  };
  
  // Export for various environments
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = HotLoaderClient;
  } else if (typeof define === 'function' && define.amd) {
    define([], function() {
      return HotLoaderClient;
    });
  } else if (typeof window !== 'undefined') {
    window.HotLoaderClient = HotLoaderClient;
  }
})();