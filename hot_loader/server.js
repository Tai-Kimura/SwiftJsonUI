var express = require('express');
var morgan = require('morgan');
var path = require('path');
var fs = require('fs');
var app = express();

app.use(morgan({ format: 'dev', immediate: true }));
app.use(express.static(__dirname + '/public'));

var http = require("http");
var server = http.createServer(function(req,res) {
    res.write("Hello World!!");
    res.end();
});

// socketioの準備
var io = require('socket.io')(server);

// クライアント接続時の処理
io.on('connection', function(socket) {
    console.log("client connected!!")
    socket.on('disconnect', function() {
        console.log("client disconnected!!")
    });
});

server.listen(8080);

var chokidar = require("chokidar");

//chokidarの初期化
var watcher = chokidar.watch('./public/',{
    ignored:/[\/\\]\./,
    persistent:true
});

//イベント定義
watcher.on('ready',function(){
    console.log("ready watching...");

    watcher.on('add',function(path){
        console.log(path + " added.");
    });

    watcher.on('change',function(path){
        try {
            JSON.parse(fs.readFileSync(path, 'utf8'));
                    console.log(path + " changed.");
            var stars = path.split("/");
            var layoutPath = "layout_loader";
            var dirName = stars[stars.length - 2];
            var filePath = stars[stars.length - 1].replace(/\.json$/g, '');
            io.emit("layoutChanged", layoutPath, dirName, filePath);
        } catch(err) {
            console.log(err);
        }
    });
});