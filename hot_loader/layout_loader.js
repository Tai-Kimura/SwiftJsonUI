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
    var filePath = path.join(__dirname, "..");
    if (req.query.dir_name.toLowerCase() == "styles") {
      filePath = path.join(filePath, req.query.dir_name, req.query.file_path + ".json");
    } else if (req.query.dir_name.toLowerCase() == "scripts") {
      filePath = path.join(filePath, req.query.dir_name, req.query.file_path + ".js");
    } else {
      // サブディレクトリ対応: file_pathにディレクトリ構造が含まれている場合
      filePath = path.join(filePath, "Layouts", req.query.file_path + ".json");
    }
    
    try {
      var buf = fs.readFileSync(filePath);
      res.send(buf, { 'Content-Type': 'application/json' }, 200);
    } catch (err) {
      console.error('File not found:', filePath, err);
      res.status(404).send('File not found');
    }
});