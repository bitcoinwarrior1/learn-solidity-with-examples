/*
    Creator: James Sangalli
    Purpose: the purpose of this contract is to create an incentive for machine
    learning models to produce the correct known but manually generated outputs. 
    
    by hashing the correct output data and checking it against the authors hash 
    (which is generated from the correct manual data), 
    someone who generates a correct output can claim the ether and has proven their 
    model works.
    
    Note: this is just a fun thought experiment. 
*/

pragma solidity ^0.4.17;
contract MachineLearningVerification 
{
    address author;
    bytes32 hashOfCorrectOutput;
    mapping(address => uint) contributions; 
    uint expiry; 
    uint authorContribution; 
    bool claimed = false;
    address[] contributors;
    
    modifier notExpired() 
    {
        if (block.timestamp > expiry) revert();
        _;
    }
    
    modifier isSmallerThanAuthorContribution(uint newContribution) 
    {
        uint newSum = this.balance + newContribution;
        if (newSum > authorContribution) revert();
        _;
    }
    
    modifier notClaimed() 
    {
        if(claimed == true) 
        {
            revert();
        }
        _;
    }
    
    constructor(bytes32 outputHash, uint expiryTimestamp) public payable
    {
        author = msg.sender;
        hashOfCorrectOutput = outputHash;
        expiry = expiryTimestamp;
        authorContribution = msg.value;
    }
    
    //if the correct hash is produced from the data of the correct output in a model
    //then the user gets ether.
    //this has issues, what stops the creator (who knows the correct output manually)
    //from taking all the ether?
    //TODO use reputation or make it impossible for the creator to profit? 
    //will use the latter first, maybe something else will come along
    //TODO prevent miner from cheating with this input, might require zksnarks
    function verifyInput(bytes32 data) notExpired notClaimed public
    {
        bytes32 hashOfValue = keccak256(data);
        if(hashOfValue == hashOfCorrectOutput) 
        {
            msg.sender.transfer(this.balance);
            claimed = true;
        }
    }
    
    function addContribution() payable public 
        isSmallerThanAuthorContribution(msg.value) notExpired
    {
        bool contributor = false;
        for(uint i = 0; i < contributors.length; i++)
        {
            if(msg.sender == contributors[i]) contributor = true;
        }
        contributions[msg.sender] += msg.value;    
        if(contributor == false)
        {
            contributors.push(msg.sender);
        }
    }
    
    function endContract() public 
    {
        require(block.timestamp > expiry || claimed); 
        for(uint i = 0; i < contributors.length; i++)
        {
            //refund contributors
            contributors[i].transfer(contributions[contributors[i]]);
        }
        //refund author's contribution if not found
        selfdestruct(author);
    }
    
}
