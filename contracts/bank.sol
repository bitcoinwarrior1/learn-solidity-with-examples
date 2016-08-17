contract bank {
    /* Define variable owner of the type address*/
    address owner;
    uint256 fifth = 50000000000000000;
    uint256 twenty = 200000000000000000;
    uint256 fifty = 500000000000000000;
    uint256 hundred = 1000000000000000000;

    mapping (address => uint) balances;

    /* this function is executed at initialization and sets the owner of the contract */
    function mortal() { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() { if (msg.sender == owner) selfdestruct(owner); }

    function cashOut() { owner.send(this.balance / 2 ) ;}//pays out half the contract with the other half taxed

    function deposit(address customer){
      uint value = msg.value;
      balances[customer] += value;
    }

    function getBalanceOf(address customer) constant returns(uint){
      return balances[customer];
    }

    function withdraw5(address customer){
      if(balances[customer] > fifth){
        customer.send(fifth); //sends a 5th of an ether
        balances[customer] -= fifth;
      }
      else return;
    }

    function withdraw20(address customer){
      if(balances[customer] > twenty){
        customer.send(twenty); //sends a 0.2 of an ether
        balances[customer] -= twenty;
      }
      else return;
    }

    function withdraw50(address customer){
      if(balances[customer] > fifty){
        customer.send(fifty); //sends a 0.5 of an ether
        balances[customer] -= fifty;
      }
      else return;
    }

    function withdraw100(address customer) {
      if(balances[customer] > hundred){
        customer.send(hundred); //sends 1 ether
        balances[customer] -= hundred;
      }
      else return;
    }

    function refund(address recipient, uint amount) returns (string) {
      if(amount < this.balance){
        recipient.send(amount);
        return "refund processed";
      }
      else return "Refund amount too large";
    }

}
