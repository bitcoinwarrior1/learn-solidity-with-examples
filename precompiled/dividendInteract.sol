personal.unlockAccount("0xdc85a8429998bd4eef79307e556f70bb70d8caf1","bitcoin");
var dividendContract = web3.eth.contract([{"constant":false,"inputs":[],"name":"payDividend","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"checkForEther","outputs":[],"type":"function"}]).at("0x86fd1415e962a065af3dc183d85abfd66470a66a");
//interaction:
dividendContract.payDividend.sendTransaction({from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});
