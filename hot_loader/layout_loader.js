/* 1. expressモジュールをロードし、インスタンス化してappに代入。*/
var express = require('express');
var morgan = require('morgan');
var fs = require('fs');
var path = require('path');
var app = express();

app.use(morgan({ format: 'dev', immediate: true }));
app.use(express.static(__dirname + '/public'));

/* 2. listen()メソッドを実行して3000番ポートで待ち受け。*/
var server = app.listen(3000, function(){
    console.log("Node.js is listening to PORT:" + server.address().port);
});

// 写真リストを取得するAPI
app.get("/layout_loader", function(req, res, next){
    console.log(req.query);
    var filePath = path.join(__dirname, 'public', req.query.folder, req.query.file_path + ".json");
    var buf = fs.readFileSync(filePath);
    res.send(buf, { 'Content-Type': 'application/json' }, 200);
});