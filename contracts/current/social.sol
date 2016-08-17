contract social {

  struct profile {
    string [] feed;
    string name;
    uint joinDate; //block time
    address [] friends;
  }

  address socialBot;
  uint members;
  string [] popularFeed;

  modifier friendsOnly (address user){
    for(uint i = 0; i < members; i++){
      if(users[msg.sender].friends[i] == user){
        _ return;
      }
    }
    throw;
  }

  modifier noEther() { if(msg.value != 0) throw; _ }
  modifier signupFee() { if(msg.value != 0.001 ether) throw; _ }

  mapping(address => profile) users;

  event _createUser(address indexed newUser);
  event _writeMessage(address indexed user, string indexed message);

  function(){
    throw;
  }

  function social(){
    socialBot = msg.sender;
  }

  function signup(string name) signupFee {
    socialBot.send(msg.value);
    users[msg.sender].name = name;
    users[msg.sender].joinDate = now;
    users[msg.sender].feed.push(name);
    users[msg.sender].friends.push(socialBot);
    _createUser(msg.sender);
  }

}
