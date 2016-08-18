contract feedback {

  address [] admins;

  modifier adminOnly() {
    for(uint i = 0; i < admins.length; i++){
      if(msg.sender == admins[i]){
        _ return; //exit the modifier
      }
    }
    throw;
  }

  modifier paid() { if(msg.value != 0.0001 ether) throw; _ } //prevents spam and pays for admins

  struct profile {
    uint positive;
    uint negative;
    uint total;
    string username;
    string location;
    address [] traders;
    bool [] givenFeedback;
    uint burnedCoins;
  }

  mapping (address => profile) users;

  event _positiveFeedback(address indexed user);
  event _negativeFeedback(address indexed user);
  event _paidAdmins();
  event _addUser(string indexed username, string indexed location, address indexed user);
  event _addAdmin(address indexed newAdmin);
  event _newTrade(address vendor, address buyer);
  event _removedUser(address user);
  event _coinsBurned(address user, uint amountBurned);

  function(){ throw; }

  function feedback(){ admins.push(msg.sender); }

  function addUser(string username, string location) returns (string) {
    users[msg.sender].positive = 0;
    users[msg.sender].negative = 0;
    users[msg.sender].total = 0;
    users[msg.sender].username = username;
    users[msg.sender].location = location;
    _addUser(username,location,msg.sender);
    return username;
  }

  function addAdmin(address newAdmin) adminOnly returns (address){
    admins.push(newAdmin);
    _addAdmin(newAdmin);
  }

  function trade(address vendor, address recipient) paid {
      if(msg.sender == vendor && vendor != recipient){
          users[vendor].traders.push(recipient);
          users[vendor].givenFeedback.push(false);
          _newTrade(vendor,recipient);
      }
  }

  function giveFeedback(address vendor, bool isPositive) paid {
    for(uint i = 0; i < users[vendor].traders.length; i++){
      if(users[vendor].traders[i] == msg.sender
      && users[vendor].givenFeedback[i] == false){
        if(isPositive){
          users[vendor].positive ++;
           _positiveFeedback(vendor);
        }
        else{
          users[vendor].negative ++;
          _negativeFeedback(vendor);
        }
      }
    }
    payAdmins();
  }

  function payAdmins() internal returns (bool){
    if(this.balance > 1 ether){
        for(uint i = 0; i > admins.length; i++){
          if(admins[i].send(this.balance/admins.length)) {
            _paidAdmins();
            return true;
          }
        }
    }
    else return false;
  }

  function viewFeedback(address user) returns (uint, uint, uint){
      return(users[user].positive, users[user].negative, users[user].total);
  }

  function removeUser(address addr) adminOnly returns (bool){
    delete users[addr];
    _removedUser(addr);
    return true;
  }

}
