contract bankWithGreeter {
    /* Define variable owner of the type address*/
    address owner;
    uint256 fifth = 50000000000000000;
    uint256 twenty = 200000000000000000;
    uint256 hundred = 1000000000000000000;
    uint256 votes = 0;
    /* this function is executed at initialization and sets the owner of the contract */
    function mortal() { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() { if (msg.sender == owner) selfdestruct(owner); }

    function cashOut() { owner.send(this.balance / 2 ) ;}//pays out half the contract with the other half taxed

    function withDraw5(){
      if(this.balance > fifth) owner.send(fifth); //sends a 5th of an ether
      else return;
    }

    function withDraw20(){
      if(this.balance > twenty) owner.send(twenty); //sends 0.2 eth
      else return;
    }

    function withDraw100() {
      if(this.balance > hundred) owner.send(hundred); //withdraw a full ether
      else return;
    }

    function refund(address recipient, uint amount) returns (string) {
      if(amount < this.balance) recipient.send(amount);
      else return "Refund amount too large";
    }

    function voteToKill() returns (uint256){
      if(votes > 3) kill();
      if(msg.sender == owner) votes++;
      return votes;
    }
}

contract bankGreet is bankWithGreeter {
    /* define variable greeting of the type string */
    string greeting;

    /* this runs when the contract is executed */
    function greeter(string _greeting) public { greeting = _greeting; }

    /* main function */
    function greet() constant returns (string) { return greeting; }

    function checkBalance() constant returns(uint256) { return this.balance; }
}
