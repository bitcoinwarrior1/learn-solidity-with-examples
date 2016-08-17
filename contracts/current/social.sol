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

  function social(){
    socialBot = msg.sender;
  }

  function createUser(string name){
    users[msg.sender].name = name;
    users[msg.sender].joinDate = now;
    users[msg.sender].feed.push(name);
    users[msg.sender].friends.push(socialBot);
  }

  function writeMessage(string message) returns (bool){
    users[msg.sender].feed.push(message);
    return true;
  }

  function getUserName(address) returns (string){
    return users[msg.sender].name;
  }

  function getLatestMessageFromUser(address person) friendsOnly(msg.sender) returns (string) {
    string latest = users[person].feed[users[person].feed.length - 1];
    return latest;
  }

}
