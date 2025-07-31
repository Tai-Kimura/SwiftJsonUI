/* 1. expressモジュールをロードし、インスタンス化してappに代入。*/
var express = require('express');
var morgan = require('morgan');
var fs = require('fs');
var path = require('path');
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

app.use(morgan({ format: 'dev', immediate: true }));
app.use(express.static(__dirname + '/public'));

/* 2. listen()メソッドを実行して3000番ポートで待ち受け。*/
var server = app.listen(3000, function(){
    console.log("Node.js is listening to PORT:" + server.address().port);
});

// 写真リストを取得するAPI
app.get("/layout_loader", function(req, res){
    console.log(req.query);
    var filePath = path.join(__dirname, "..");
    var dirName = req.query.dir_name.toLowerCase();
    
    // Compare with lowercase config values
    if (dirName === (config.styles_directory || "Styles").toLowerCase()) {
      filePath = path.join(filePath, config.styles_directory || "Styles", req.query.file_path + ".json");
    } else if (dirName === (config.scripts_directory || "Scripts").toLowerCase()) {
      filePath = path.join(filePath, config.scripts_directory || "Scripts", req.query.file_path + ".js");
    } else {
      filePath = path.join(filePath, config.layouts_directory || "Layouts", req.query.file_path + ".json");
    }
    var buf = fs.readFileSync(filePath);
    res.send(buf, { 'Content-Type': 'application/json' }, 200);
});