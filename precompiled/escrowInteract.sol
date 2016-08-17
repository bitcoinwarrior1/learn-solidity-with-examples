personal.unlockAccount("0xdc85a8429998bd4eef79307e556f70bb70d8caf1","bitcoin");
var escrowContract = web3.eth.contract([{"constant":true,"inputs":[],"name":"seller","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":false,"inputs":[],"name":"approve","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"killContract","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"seller","type":"address"},{"name":"buyer","type":"address"}],"name":"setup","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"abort","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"refund","outputs":[],"type":"function"},{"constant":true,"inputs":[],"name":"buyer","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":false,"inputs":[],"name":"payOut","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"deposit","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"fee","outputs":[],"type":"function"}]).at("0xec538547ebbfdc9687585864688e1e2bca5d9cb2");
escrowContract.setup.sendTransaction("0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab","0x21aadccb23591608f06f37fd5cb9aa264ae9fa3c", {from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});

//output:
/*setup: 0x067e75f36e797bc2cecadba6e95740d081fc7157e57a73e5be41c2f6b27f94dc*/
eth.sendTransaction({from: '0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab', to: '0xec538547ebbfdc9687585864688e1e2bca5d9cb2', value: web3.toWei(0.25, "ether")});
/*0x4c0b11ab4d4bed06b0f80a2162e6c2316df7776cdf780d88df3ac9ba8b515020*/
//approve:
personal.unlockAccount("0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab","James!")
escrowContract.approve.sendTransaction({from:"0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab"})
personal.unlockAccount("0x21aadccb23591608f06f37fd5cb9aa264ae9fa3c","")
escrowContract.approve.sendTransaction({from:"0x21aadccb23591608f06f37fd5cb9aa264ae9fa3c"})

escrowContract.killContract.sendTransaction({from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"})
//0x0cf1a7e3598a0e3207f5dab937a64d585d6f01ea19ab6187f8328f71f6c2f026
