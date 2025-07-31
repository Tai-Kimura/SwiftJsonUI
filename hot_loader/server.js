var express = require("express");
var morgan = require("morgan");
var path = require("path");
var fs = require("fs");
var app = express();

// Load config from binding_builder/config.json
var config = {};
var defaultConfig = {
  'layouts_directory': 'Layouts',
  'styles_directory': 'Styles',
  'scripts_directory': 'Scripts'
};

try {
  var configPath = path.join(__dirname, '..', 'binding_builder', 'config.json');
  if (fs.existsSync(configPath)) {
    var configContent = fs.readFileSync(configPath, 'utf8');
    var loadedConfig = JSON.parse(configContent);
    config = Object.assign({}, defaultConfig, loadedConfig);
  } else {
    config = defaultConfig;
  }
} catch (err) {
  console.error('Error loading config.json:', err);
  config = defaultConfig;
}

app.use(morgan("dev"));
app.use(express.static(__dirname + "/public"));

const socket = require("ws");

// WebSocketサーバーを作成
const server = new socket.Server({ port: 8081 });

let webSocket;

// クライアント接続時の処理
server.on("connection", (ws) => {
  webSocket = ws;
  console.log("client connected!!");
  webSocket.on("disconnect", () => {
    console.log("client disconnect!!");
  });
});

server.on("error", () => {
  console.log("client error!!");
});

server.on("disconnect", () => {
  console.log("client disconnect!!");
});

// server.listen(8081);

var chokidar = require("chokidar");
var { exec } = require("child_process");

//chokidarの初期化
// Watch patterns for each directory
var watchPatterns = [
  `../${config.layouts_directory || 'Layouts'}/**/*.json`,
  `../${config.styles_directory || 'Styles'}/**/*.json`,
  `../${config.scripts_directory || 'Scripts'}/**/*.js`
];

var watcher = chokidar.watch(watchPatterns, {
  ignored: /[\/\\]\./,
  persistent: true,
});

//イベント定義
watcher.on("ready", function () {
  console.log("ready watching...");

  watcher.on("add", function (path) {
    console.log(path + " added.");
  });

  watcher.on("change", function (path) {
    var stars = path.split("/");
    var layoutPath = "layout_loader";
    
    // Find the main directory (Layouts, Styles, or Scripts)
    var dirName = "";
    var filePathParts = [];
    var foundMainDir = false;
    
    for (var i = 0; i < stars.length; i++) {
      var part = stars[i];
      if (!foundMainDir && (
        part.toLowerCase() === (config.layouts_directory || 'Layouts').toLowerCase() ||
        part.toLowerCase() === (config.styles_directory || 'Styles').toLowerCase() ||
        part.toLowerCase() === (config.scripts_directory || 'Scripts').toLowerCase()
      )) {
        dirName = part.toLowerCase();
        foundMainDir = true;
      } else if (foundMainDir) {
        filePathParts.push(part);
      }
    }
    
    // Join subdirectories and filename
    var fullFilePath = filePathParts.join("/");
    
    if (fullFilePath.endsWith(".json")) {
      // Remove extension and keep directory structure
      var filePathWithoutExt = fullFilePath.replace(/\.json$/g, "");
      try {
        JSON.parse(fs.readFileSync(path, "utf8"));
        console.log(path + " changed.");
        
        // Check if the changed file is in the Layouts directory
        if (dirName === (config.layouts_directory || "Layouts").toLowerCase()) {
          console.log("Layout file changed, running sjui build...");
          
          // Execute sjui build command
          exec("cd ../binding_builder && ./sjui build", (error, stdout, stderr) => {
            if (error) {
              console.error("Error running sjui build:", error);
              console.error("stderr:", stderr);
            } else {
              console.log("sjui build completed successfully");
              if (stdout) {
                console.log("stdout:", stdout);
              }
            }
          });
        }
        
        webSocket?.send(JSON.stringify([layoutPath, dirName, filePathWithoutExt]));
      } catch (err) {
        console.log(err);
      }
    } else if (fullFilePath.endsWith(".js")) {
      // Remove extension and keep directory structure
      var filePathWithoutExt = fullFilePath.replace(/\.js$/g, "");
      console.log(path + " changed.");
      webSocket?.send(JSON.stringify([layoutPath, dirName, filePathWithoutExt]));
    }
  });
});
