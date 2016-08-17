import "storeCredit.sol";

contract store is storeCredit {

  address owner;
  address [] sellers;

  event _setOwner();
  event _addSeller(address indexed seller);
  event _buy(address indexed seller, uint256 indexed price, string indexed product);

  function setOwner(){
    _setOwner();
    owner = msg.sender;
  }

  function addSeller(address seller){
    _addSeller(seller);
    sellers.push(seller);
  }

  function buy(address seller, uint256 price, string product) returns (bool){
    _buy(seller,price,product);
    if(balances[msg.sender] > price && seller.send(price)) return true;
  }
}
