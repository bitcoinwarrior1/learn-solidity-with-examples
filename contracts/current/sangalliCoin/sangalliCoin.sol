contract sangalliCoin {

  address sangalli;
  mapping (address => uint) balances;
  uint256 id;

  modifier sangalliOnly{ if(msg.sender != sangalli) throw; _ }
  modifier noEther { if(msg.value > 0) throw; _ }
  event _attemptWithdrawal(uint256 indexed amount, address indexed customer, uint256 withdrawalId);
  event _denyWithdrawal(uint256 indexed id, address indexed customer, uint256 indexed amount);
  event _successfulWithdrawal(uint256 indexed id, address indexed customer, uint256 indexed amount);

  function deposit(){
    if(this.balance > 10000000000000000000) throw;
    //puts in a IPO cap on investment and token issuance. Must trade on market after that
    if(msg.value > 0) balances[msg.sender] += msg.value;
    else throw;
  }

  function transfer(address recipient, uint256 amount) noEther returns (uint256){
    if(balances[msg.sender] >= amount){
      balances[msg.sender] -= amount;
      balances[recipient] += amount;
      return balances[msg.sender];
    }
    else throw;
  }

  function attemptWithdrawal(uint256 amount) noEther returns (string){
     if(balances[msg.sender] >= amount){
        _attemptWithdrawal(amount, msg.sender, id++);
        return "Withdrawal attempted... #sangalliCoin";
     }
     else{
        _attemptWithdrawal(amount, msg.sender, 404);
        return "Insufficient balance #sangalliCoin";
     }
  }

  function sangalliCoin(){
      sangalli = msg.sender;
      id = 0;
  }

  function checkBalance() noEther returns (uint256){
    return balances[msg.sender];
  }

  function denyWithdrawal(uint256 withdrawId, address customer, uint256 amount) noEther returns (string){
    _denyWithdrawal(withdrawId,customer,amount);
    return "Hahaha!!";
  }

  function withdraw(uint withdrawAmount,
    address user,
    uint256 penalty,
    uint256 successfulId) sangalliOnly noEther
    returns (uint remainingBal) {
        if(balances[user] >= withdrawAmount + penalty) {
            balances[user] -= withdrawAmount + penalty;
            if (!user.send(withdrawAmount)) {
                balances[user] += withdrawAmount + penalty;
            }
        }
        _successfulWithdrawal(successfulId, user, withdrawAmount);
        return balances[msg.sender];
    }

    function goBust() sangalliOnly {
      selfdestruct(sangalli);
    }
}
