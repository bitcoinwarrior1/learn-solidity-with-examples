import "./sangalliCoin.sol";

contract market is sangalliCoin {

  address [] sellers;
  uint256 [] pricePerCoin;
  uint256 [] amount;

  event _sellOffer(uint256 indexed amount, uint256 indexed price, address indexed seller);
  event _buy(uint256 indexed amount, uint256 indexed price, address seller, address indexed buyer);

  function sellOffer(uint256 amount, uint256 price) noEther returns (bool) {
    if(balances[msg.sender] > amount * price){
      sellers.push(msg.sender);
      pricePerCoin.push(price);
      _sellOffer(amount, price, msg.sender);
      return true;
    }
    else throw;
  }

  function buy(uint256 amountToBuy, uint256 price) returns (bool){
    if(msg.value >= amountToBuy * price){
      for(uint i = 0; i < pricePerCoin.length; i++){
        if(price == pricePerCoin[i] && amountToBuy == amount[i]){
          if(sellers[i].send(amountToBuy * price)){
            balances[sellers[i]] -= amountToBuy * price;
            balances[msg.sender] += amountToBuy * price;
            //remove arrays
            delete sellers[i];
            delete pricePerCoin[i];
            delete amount[i];
            //trigger event
            _buy(amountToBuy, price, sellers[i], msg.sender);
            return true; //trade successful
          }
        }
      }
      throw; //if trade is not complete then return the ether to the sender by throwing
      //this is envoked if it gets to the end of the contract without returning true
    }
    else throw; //if user doesn't have sufficient funds then funds will be refunded
  }
}
