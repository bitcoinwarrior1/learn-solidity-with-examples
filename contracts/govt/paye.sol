contract paye {

  address taxAddr;
  mapping (address => uint) taxNumbers;
  uint256 taxRate;

  function paye(){
    taxAddr = msg.sender;
    taxRate = 20; //20% flat rate
  }

  function pay(address worker){
    worker.send(msg.value - msg.value * 20 /100);
  }

}
