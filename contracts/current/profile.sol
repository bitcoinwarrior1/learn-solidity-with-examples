import "./social.sol";

contract profile is social {

  function writeMessage(string message) returns (bool){
    users[msg.sender].feed.push(message);
    _writeMessage(msg.sender,message);
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
