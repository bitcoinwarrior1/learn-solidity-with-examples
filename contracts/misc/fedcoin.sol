contract fedcoin{
  address chairman;
  mapping (address => uint) balances;
  uint reserveRatio;
  string [] transactionLog;

  function fedcoin(){ chairman = msg.sender; }

  function setReserveRatio(uint ratio){ reserveRatio = ratio; } // divided by 100

  function changeSupply(uint amount, bool increase){
    if(msg.sender != chairman) return;
    if(increase){
      if(amount < reserveRatio * (balances[chairman] / 100)){
         balances[chairman] += amount;
      }
    }
    else balances[chairman] -= amount;
  }

  function withdraw(address recipient, uint amount){
    if(msg.sender == chairman && recipient.send(amount)){
      transactionLog.push(amount.toString() + "Deposited into: " + recipient.toString());
    }
  }

  function shutDownFed(){
    selfdestruct(chairman);
  }

  function lendToBanks(address bank, uint amount) returns (bool success){

  }

  function queryBalance(address addr) constant returns (uint balance) {
      return balances[addr];
  }

}
