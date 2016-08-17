var cashoutContract = web3.eth.contract([{"constant":false,"inputs":[],"name":"withDraw20","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],"name":"refund","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"withDraw5","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"voteToKill","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[],"name":"withDraw100","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"mortal","outputs":[],"type":"function"},{"inputs":[],"type":"constructor"}]).at("0x29a02cd0f340efb6492c535a951fb33270ad1ef7");
var bankgreetContract = web3.eth.contract([{"constant":false,"inputs":[],"name":"withDraw20","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],"name":"refund","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"withDraw5","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"voteToKill","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"checkBalance","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"greet","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":false,"inputs":[],"name":"withDraw100","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"mortal","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"_greeting","type":"string"}],"name":"greeter","outputs":[],"type":"function"}]).at("0x266447b7c8c4dd71daa7d6a5979181b19c533abc");

//execute functions:
personal.unlockAccount("0xdc85a8429998bd4eef79307e556f70bb70d8caf1","bitcoin");
//topup contract
eth.sendTransaction({from: '0xdc85a8429998bd4eef79307e556f70bb70d8caf1', to: '0x29a02cd0f340efb6492c535a951fb33270ad1ef7', value: web3.toWei(0.5, "ether")});
eth.sendTransaction({from: '0xdc85a8429998bd4eef79307e556f70bb70d8caf1', to: '0x266447b7c8c4dd71daa7d6a5979181b19c533abc', value: web3.toWei(0.5, "ether")})

var _greeting = "Welcome!";
//cashout half of the contract
cashoutContract.cashOut.sendTransaction({from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});
//withdraw 0.2 eth
cashoutContract.withDraw20.sendTransaction({from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});
//get balance
cashoutContract.voteToKill.sendTransaction({from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});
//get bank balance
bankgreetContract.checkBalance.sendTransaction({from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});
