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

  function getLatestMessageFromUser(address person) friendsOnly(msg.sender) noEther returns (string) {
    string latest = users[person].feed[users[person].feed.length - 1];
    return latest;
  }

}
