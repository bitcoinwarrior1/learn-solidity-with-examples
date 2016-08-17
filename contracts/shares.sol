import "accounting";

contract shares is accounting{

  address admin;
  mapping (address => uint256) shareholders;
  modifier adminOnly() { if(msg.sender != admin) throw; }

  function dividend(uint256 amount) adminOnly {
    /*for(shareholder of shareholders){
      shareholder.send(amount);
    }*/
  }

  function sellStock(uint256 amount) returns (uint256){
    if(shareholders[msg.sender] > amount && msg.sender.send(amount)){
      shareholders[msg.sender] -= amount;
      return shareholders[msg.sender];
    }
  }

  function buyStock() returns (uint256){
    shareholders[msg.sender] += msg.value;
    return shareholders[msg.sender];
  }
}
