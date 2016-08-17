$(() => {
var request = require("superagent");
var address = $("#address").val();
var contractAddress = "";

$("#button").click(sendToServer());

function sendToServer(){
  request
    .post("http://localhost:3000/v1/"+ address + "," + contractAddress)
    .send(address)
    .end( (err,res) => {    // get a response back about the result
      if(res.body) alert("License Valid");
      else alert("Invalid License");
    })
}

});
