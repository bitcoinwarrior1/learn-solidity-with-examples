//geth --testnet js ./gethCashout.js
personal.unlockAccount("0xdc85a8429998bd4eef79307e556f70bb70d8caf1","bitcoin");
var _greeting = "oh yea" ;
var mortal = web3.eth.contract([{"constant":false,"inputs":[],"name":"kill","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"cashOut","outputs":[],"type":"function"},{"inputs":[],"type":"constructor"}]).at("0xc5622be5861b7200cbace14e28b98c4ab77bd9b4");
//cashout, gets back half contract's value
mortal.cashOut.sendTransaction({from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"})
eth.getCode(mortal.address)
setTimeout(function(){
  eth.getCode(mortal.address)
},600000)
