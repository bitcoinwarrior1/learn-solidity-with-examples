personal.unlockAccount(eth.coinbase, "bitcoin");

personal.unlockAccount(eth.accounts[1], "James!");

var sangallicoin = web3.eth.contract([{"constant":false,"inputs":[{"name":"withdrawId","type":"uint256"},{"name":"customer","type":"address"},{"name":"amount","type":"uint256"}],"name":"denyWithdrawal","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[],"name":"checkBalance","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[],"name":"deposit","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"amountToBuy","type":"uint256"},{"name":"price","type":"uint256"}],"name":"buy","outputs":[{"name":"","type":"bool"}],"type":"function"},{"constant":false,"inputs":[{"name":"amount","type":"uint256"},{"name":"price","type":"uint256"}],"name":"sellOffer","outputs":[{"name":"","type":"bool"}],"type":"function"},{"constant":false,"inputs":[{"name":"withdrawAmount","type":"uint256"},{"name":"user","type":"address"},{"name":"penalty","type":"uint256"},{"name":"successfulId","type":"uint256"}],"name":"withdraw","outputs":[{"name":"remainingBal","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[],"name":"goBust","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"amount","type":"uint256"}],"name":"attemptWithdrawal","outputs":[{"name":"","type":"string"}],"type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"amount","type":"uint256"},{"indexed":true,"name":"price","type":"uint256"},{"indexed":true,"name":"seller","type":"address"}],"name":"_sellOffer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"amount","type":"uint256"},{"indexed":true,"name":"price","type":"uint256"},{"indexed":false,"name":"seller","type":"address"},{"indexed":true,"name":"buyer","type":"address"}],"name":"_buy","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"amount","type":"uint256"},{"indexed":true,"name":"customer","type":"address"},{"indexed":false,"name":"withdrawalId","type":"uint256"}],"name":"_attemptWithdrawal","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"id","type":"uint256"},{"indexed":true,"name":"customer","type":"address"},{"indexed":true,"name":"amount","type":"uint256"}],"name":"_denyWithdrawal","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"id","type":"uint256"},{"indexed":true,"name":"customer","type":"address"},{"indexed":true,"name":"amount","type":"uint256"}],"name":"_successfulWithdrawal","type":"event"}]).at("0x0dc11bf46ffb147266173ed052dd07e2ead7b6ed");

sangallicoin._attemptWithdrawal().watch(function(error, result){
 console.log(JSON.stringify(result.args));
});

sangallicoin._denyWithdrawal().watch(function(error, result){
  console.log(JSON.stringify(result.args));
});

sangallicoin._successfulWithdrawal().watch(function(error, result){
  console.log(JSON.stringify(result.args));
});

sangallicoin._sellOffer().watch(function(error, result){
  console.log(JSON.stringify(result.args));
});

sangallicoin._buy().watch(function(error, result){
  console.log(JSON.stringify(result.args));
});

sangallicoin.deposit.sendTransaction({from: eth.accounts[0], value: 100000000000000000, gas:100000});

sangallicoin.denyWithdrawal.sendTransaction(21, "0xdc85a8429998bd4eef79307e556f70bb70d8caf1", 5000000000, {from: eth.coinbase, gas:1000000})

sangallicoin.attemptWithdrawal.sendTransaction(100000000000000000, {from:eth.accounts[0]});

sangallicoin.withdraw.sendTransaction(40000000000000000,"0xdc85a8429998bd4eef79307e556f70bb70d8caf1",  20000000000, 21,{from:eth.coinbase, gas:1000000});

sangallicoin.checkBalance.call({from:eth.coinbase});

sangallicoin.checkBalance.call({from:eth.accounts[1]});

sangallicoin.sellOffer.sendTransaction(10000000000000000, 20000000000000000, {from:eth.coinbase, gas:100000}); //selling sangalliCoins at double the IPO price

sangallicoin.buy.sendTransaction(10000000000000000, 20000000000000000, {from:eth.accounts[1], value: 20000000000000000, gas:1000000}); //buying sangalliCoins at double the IPO price

sangallicoin.transfer.sendTransaction(eth.accounts[0], 19999999999999998, {from:eth.accounts[1], gas:100000})

//0x0dc11bf46ffb147266173ed052dd07e2ead7b6ed
