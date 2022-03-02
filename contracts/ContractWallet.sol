/*
    The purpose of this contract is to allow anyone to have move and store their ether via this contract
    with the assurance that someone can move the funds for them if they lose their keys.
    
    This is semi trustless as even a malicious guardian of the funds has to wait for the grace period 
    before they can take the funds, the user can easily get their funds back if this happens 
    as the grace period can be quite long.
*/

pragma solidity ^0.5.10;

contract ContractWallet {
    uint256 public gracePeriodInterval;

    struct User {
        address userAddress;
        uint256 balance;
        //time after request for approval to move funds in which user can still move their money
        uint256 gracePeriod;
        address payable guardian;
        bool approvedToMove;
    }

    mapping(address => User) users;

    constructor(uint256 gracePeriodIntervalInit) public {
        gracePeriodInterval = gracePeriodIntervalInit;
    }

    function() external payable {
        //check if user has an account else reject
        require(users[msg.sender].guardian != address(0));
        users[msg.sender].balance += msg.value;
    }

    function createUser(address payable guardian) public payable {
        require(users[msg.sender].guardian != address(0));
        User memory user = User(msg.sender, msg.value, 0, guardian, false);
        users[msg.sender] = user;
    }

    function transferEther(address payable to, uint256 amount) public {
        require(users[msg.sender].balance >= amount);
        to.transfer(amount);
        users[msg.sender].balance -= amount;
    }

    //guardian suspects that the user has lost their key, initiates a move but must wait til gracePeriod is finished
    function guardianRequestToMoveFunds(address toMove) public {
        require(users[toMove].guardian == msg.sender);
        users[toMove].approvedToMove = true;
        //user can move their funds on their own before the grace period,
        //this is to protect malicious moving of funds by guardian
        users[toMove].gracePeriod = block.timestamp + gracePeriodInterval;
    }

    //user has not moved funds since grace period, we assume they have lost their keys
    function withdrawToGuardian(address toMove) public {
        require(users[toMove].guardian == msg.sender);
        require(users[toMove].gracePeriod < block.timestamp);
        users[toMove].guardian.transfer(users[toMove].balance);
        users[toMove].balance = 0;
        delete users[toMove];
    }
}
