import "./social.sol";

contract profile is social {

  function writeMessage(string message) noEther returns (bool){
    users[msg.sender].feed.push(message);
    _writeMessage(msg.sender,message);
    return true;
  }

  function getUserName(address) noEther returns (string){
    return users[msg.sender].name;
  }

  function getLatestMessageFromUser(address person) friendsOnly(msg.sender)
  noEther returns (string) {
    string latest = users[person].feed[users[person].feed.length - 1];
    return latest;
  }

  function getMostPopularFeed() noEther returns(string){
    uint mostFriends = 0;
    address mostPopular;

    for(uint i = 0; i < memberCount; i++){
      if(users[members[i]].friends.length - 1 > mostFriends){
        mostPopular = members[i];
        mostFriends = users[members[i]].friends.length - 1;
      }
    }
    return users[mostPopular].feed[users[mostPopular].feed.length - 1];
  }

}
