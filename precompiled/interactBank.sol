personal.unlockAccount("0xdc85a8429998bd4eef79307e556f70bb70d8caf1","bitcoin");
var bank = web3.eth.contract([{"constant":false,"inputs":[],"name":"payDividend","outputs":[{"name":"","type":"bool"}],"type":"function"},{"constant":true,"inputs":[],"name":"dividend","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":false,"inputs":[],"name":"payBankTax","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"customer","type":"address"}],"name":"withdraw50","outputs":[],"type":"function"},{"constant":true,"inputs":[],"name":"taxContract","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],"name":"refund","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"cashOut","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"getBankBalance","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"type":"function"},{"constant":true,"inputs":[{"name":"customer","type":"address"}],"name":"getBalanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":false,"inputs":[{"name":"customer","type":"address"},{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],"name":"sendMoney","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"mortal","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"customer","type":"address"}],"name":"deposit","outputs":[],"type":"function"}]).at("0x4a6b7216c8687a5b6689adb05f51e531ad202d35");
eth.sendTransaction({from: '0xdc85a8429998bd4eef79307e556f70bb70d8caf1', to: '0x4a6b7216c8687a5b6689adb05f51e531ad202d35', value: web3.toWei(0.5, "ether")});

personal.unlockAccount("0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab","James!")
//interact with contract:
bank.deposit.sendTransaction("0xdc85a8429998bd4eef79307e556f70bb70d8caf1",{from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1", value: 500000000000000000});
bank.withdraw100.sendTransaction("0xdc85a8429998bd4eef79307e556f70bb70d8caf1",{from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});
bank.getBalanceOf.sendTransaction("0xdc85a8429998bd4eef79307e556f70bb70d8caf1",{from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});
bank.refund.sendTransaction("0xdc85a8429998bd4eef79307e556f70bb70d8caf1",10000000000000000,{from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});

eth.getCode(bank.address)

bank.deposit.sendTransaction("0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab",{from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1", value: 500000000000000000});
personal.unlockAccount("0x21aadccb23591608f06f37fd5cb9aa264ae9fa3c","");

bank.withdraw5.sendTransaction("0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab",{from:"0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab"});
bank.refund.sendTransaction("0x21aadccb23591608f06f37fd5cb9aa264ae9fa3c",10000000000000000,{from:"0x21aadccb23591608f06f37fd5cb9aa264ae9fa3c"})

bank.payDividend.sendTransaction({from:"0xdc85a8429998bd4eef79307e556f70bb70d8caf1"});
