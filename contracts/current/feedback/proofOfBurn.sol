import './feedback.sol';

contract proofOfBurn is feedback{

  address proofOfBurnAddr = 0x0000000000000000000000000000000000000000;

  function showBurnedCoins(address user) returns (uint){
    return users[user].burnedCoins;
  }

  function burnCoins() returns (uint){
    if(proofOfBurnAddr.send(msg.value)){
      users[msg.sender].burnedCoins += msg.value;
      _coinsBurned(msg.sender, msg.value);
      return users[msg.sender].burnedCoins;
    }
    else throw;
  }

}
