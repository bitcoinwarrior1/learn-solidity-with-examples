var express = require('express')
var app = express()
var bodyParser = require('body-parser')
var request = require("superagent")

var path = require("path")
app.use(express.static(__dirname));
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

var value = 100000000000000;
var revokeValue = 50000000000000;

app.post("/v1/:address", function(req,res){
  res.header( 'Access-Control-Allow-Origin','*' );
  var address = req.params.address
  var query = "https://testnet.etherscan.io/api?module=account&action=balancemulti&address="
  query += address;
  query += "&tag=latest&apikey=ANVBH7JCNH1BVHJ1NPB5FH1WKP5C6YSYJW"
  request.get(query, function(err, data){
    res.header( 'Access-Control-Allow-Origin','*' );
    // send to client
    res.json(data.body.result)
  })

})



module.exports = app;
