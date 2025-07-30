var express = require("express");
var morgan = require("morgan");
var path = require("path");
var fs = require("fs");
var app = express();

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

//chokidarの初期化
var watcher = chokidar.watch("../*/*.json", {
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
    var filePath = stars[stars.length - 1];
    if (filePath.endsWith("json")) {
      filePath = stars[stars.length - 1].replace(/\.json$/g, "");
      try {
        JSON.parse(fs.readFileSync(path, "utf8"));
        console.log(path + " changed.");
        webSocket?.send(JSON.stringify([layoutPath, dirName, filePath]));
      } catch (err) {
        console.log(err);
      }
    } else if (filePath.endsWith("js")) {
      filePath = stars[stars.length - 1].replace(/\.js$/g, "");
      console.log(path + " changed.");
      webSocket?.send(JSON.stringify([layoutPath, dirName, filePath]));
    }
  });
});
