contract bankPlus {
    /* Define variable owner of the type address*/
    address public owner;
    uint256 fifty = 500000000000000000;
    address public taxContract = 0x29a02cd0f340efb6492c535a951fb33270ad1ef7;
    /*address public dividend = 0xebf91f1fb1df67709cc8346abcd9085c34c92a7e;*/

    mapping (address => uint) balances;

    event _deposit(address _dividend);
    event _payDividend(address _dividend);
    event _withdraw50(address _customer);
    event _sendMoney(address _customer, address _recipient, address _amount);
    /* this function is executed at initialization and sets the owner of the contract */
    function mortal() { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() { if (msg.sender == owner) selfdestruct(owner); }

    /*function cashOut() { owner.send(this.balance / 2 ) ;}//pays out half the contract with the other half taxed*/

    function deposit(address customer){
      uint value = msg.value;
      balances[customer] += value;
    }

    function payDividend(address dividend) returns (bool){
      uint256 dividendAmount = this.balance / 5;
      balances[dividend] = dividendAmount;
      if(dividend.send(dividendAmount)){
        balances[dividend] -= dividendAmount;
        return true;
      }
      else throw;
    }

    function withdraw50(address customer){
      if(balances[customer] > fifty && customer.send(fifty)){
        //sends a 0.5 of an ether
        balances[customer] -= fifty;
      }
      else return;
    }

    function sendMoney(address customer, address recipient, uint256 amount) {
      if(balances[customer] > amount){
        balances[customer] -= amount;
        balances[recipient] += amount; //internal bank transfer
      }
      else return;
    }

    function refund(address recipient, uint amount) returns (string) {
      if(amount < this.balance){
        recipient.send(amount);
        return "refund processed";
      }
      else throw;
    }

    function payBankTax(){
      balances[taxContract] = this.balance / 3; //pays 33% tax
      /*taxContract.call.gas(240000).value(this.balance / 3)(); //calls another contract initiated by the owner*/
      taxContract.send(this.balance / 3);
    }

}

contract bankInfo is bankPlus{
  function getBalanceOf(address customer) constant returns(uint){
    return balances[customer];
  }

  function getBankBalance() returns (uint256){
    return this.balance;
  }

}
