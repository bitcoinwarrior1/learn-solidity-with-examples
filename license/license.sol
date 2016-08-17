//personal.unlockAccount(eth.accounts[0],"bitcoin")
contract license {

  address [] authorities;
  address [] users;
  address owner;

  event _issueLicense(address indexed user);
  event _setAuthority(address indexed issued);
  event _checkLicense(address indexed user);
  event _revokeLicense(address indexed user);

  modifier ownerOnly() { if(msg.sender != owner) throw; }
  modifier auth() {
      bool exists;
      for(uint256 i=0; i<authorities.length; i++)
        if(msg.sender == users[i]) exists = true;
      if(!exists) throw;
  }
  modifier noEther(){ if(msg.value > 0) throw; }

  function setAuthority(address issued) auth returns(bool) {
    _setAuthority(issued);
    authorities.push(issued);
    return true;
  }

  function checkLicense(address user) noEther returns (bool){
    _checkLicense(user);
    for (uint256 i = 0; i<users.length; i++)
      if(users[i] == user) return true;
    return false;
  }

  function issueLicense(address user) auth returns(bool){
    _issueLicense(user);
    users.push(user);
    user.send(100000000000000); //sends some ether so it can be verified with a block explorer
    return true;
  }

  function revokeLicense(address user) auth returns(bool){
    _revokeLicense(user);
    for(uint256 i = 0; i<users.length; i++){
        if(users[i] == user){
            delete users[i];
            user.send(50000000000000); //sends some ether so it can be verified with a block explorer
            return true;
        }
    }
    return false;
  }
}
