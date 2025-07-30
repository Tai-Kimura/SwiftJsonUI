var express = require("express");
var morgan = require("morgan");
var path = require("path");
var fs = require("fs");
var app = express();

app.use(morgan({ format: "dev", immediate: true }));
app.use(express.static(__dirname + "/public"));

const socket = require("ws");

// WebSocketサーバーを作成
const server = new socket.Server({ port: 8081 });

let webSocket;

// // socketioの準備
// var io = require('socket.io')(server);

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

//chokidarの初期化
var watcher = chokidar.watch("../**/*.json", {
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
    var dirName = stars[stars.length - 2].toLowerCase();
    var fileName = stars[stars.length - 1];
    
    // サブディレクトリ対応: Layoutsフォルダからの相対パスを取得
    var layoutsIndex = stars.indexOf("Layouts");
    var filePath;
    
    if (layoutsIndex !== -1 && layoutsIndex < stars.length - 2) {
      // Layoutsフォルダ内のサブディレクトリの場合
      var subDirParts = stars.slice(layoutsIndex + 1, stars.length - 1);
      var fileNameWithoutExt = fileName.replace(/\.(json|js)$/g, "");
      filePath = subDirParts.length > 0 ? subDirParts.join("/") + "/" + fileNameWithoutExt : fileNameWithoutExt;
    } else {
      // 従来のルートディレクトリの場合
      filePath = fileName.replace(/\.(json|js)$/g, "");
    }
    
    if (fileName.endsWith("json")) {
      try {
        JSON.parse(fs.readFileSync(path, "utf8"));
        console.log(path + " changed.");
        webSocket?.send(JSON.stringify([layoutPath, dirName, filePath]));
      } catch (err) {
        console.log(err);
      }
    } else if (fileName.endsWith("js")) {
      console.log(path + " changed.");
      webSocket?.send(JSON.stringify([layoutPath, dirName, filePath]));
    }
  });
});
