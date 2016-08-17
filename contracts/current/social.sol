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

  mapping(address => profile) users;

  event _createUser(address indexed newUser);
  event _writeMessage(address indexed user, string indexed message);

  function social(){
    socialBot = msg.sender;
  }

  function createUser(string name){
    users[msg.sender].name = name;
    users[msg.sender].joinDate = now;
    users[msg.sender].feed.push(name);
    users[msg.sender].friends.push(socialBot);
    _createUser(msg.sender);
  }

}
