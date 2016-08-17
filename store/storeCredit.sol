contract storeCredit {

  address merchant; //where fees are sent
  mapping (address => uint256) balances;

  function tradeTokens(bool buy) returns (uint256){
    if(buy) balances[msg.sender] += (msg.value - msg.value / 100);
    else if(buy == false) balances[msg.sender] -= (msg.value + msg.value / 100);
    else throw;
    payFee(msg.value / 100);
    return balances[msg.sender];
  }

  function payFee(uint256 value){ merchant.send(value); }

}
