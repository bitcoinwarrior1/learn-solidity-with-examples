contract Government {

  address president;
  uint deadline; //in unix time
  address winner;
  address [] candidates;

  mapping (address => uint) votes;
  mapping (address => uint) taxVotes; //amount of votes determined by the amount of taxes paid

  modifier presidentOnly(){ if(msg.sender != president) throw; _ }

  function Government(){
    president = msg.sender;
  }

  function setDeadline(uint256 timestamp) presidentOnly {
    if(timestamp > now) deadline = timestamp;
    else throw;
  }

  function vote(address candidate){
    bool added;
    for(uint i = 0; i < candidates.length; i++){
      if(candidate == candidates[i]) added = true;
      else added = false;
    }
    if(!added) candidates.push(candidate);
    votes[candidate] += taxVotes[msg.sender];
    taxVotes[msg.sender] = 0;
  }

  function payTaxes() returns (uint){
    taxVotes[msg.sender] += msg.value;
    return taxVotes[msg.sender];
  }

  function checkWhoWon() returns (address){
    if(now >= deadline){
      uint winnerVoteCount = 0;
      address winner;
      for(uint i = 0; i < candidates.length; i++){
        if(votes[candidates[i]] > winnerVoteCount){
          winnerVoteCount = votes[candidates[i]];
          winner = candidates[i];
        }
      }
      if(winner.send(this.balance)){ //winner takes all the funds
        return winner;
      }
      else throw;
    }
    else throw;
  }

}
