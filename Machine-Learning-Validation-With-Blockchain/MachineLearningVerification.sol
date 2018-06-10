/*
    Creator: James Sangalli
    Purpose: the purpose of this contract is to create an incentive for machine
    learning models to produce the correct known but manually generated outputs.

    by hashing the correct output data and checking it against the authors hash
    (which is generated from the correct manual data),
    someone who generates a correct output can claim the ether and has proven their 
    model works.

    Note: this is just a fun thought experiment.

    Example: classify the data appropriately, have a large dataset with the correct answers stored privately and hashed.
    Model that successfully classifies the data will produce the correct hash and be able to take the prize.
*/

//This is the interface for the applicant to implement with their own solution
contract MachineLearningSolutionAttempt 
{
    address applicant;
    
    constructor() public { applicant = msg.sender; }
    
    //attempt to solve the model here by implementing a mode
    //return the output of the model and the applicant address
    //if it works properly then the applicant address is compensated
    function model(bytes32 data) public returns (bytes32 output, address applicantPayoutAddress);
}

pragma solidity ^0.4.17;
contract MachineLearningVerification
{
    address author;
    bytes32 modelData;
    uint expiry;
    uint authorContribution;
    bool claimed = false;
    address winner;
    address winningContract;

    modifier notExpired()
    {
        if (block.timestamp > expiry) revert();
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

    constructor(bytes32 data, uint expiryTimestamp) public payable
    {
        author = msg.sender;
        modelData = data;
        expiry = expiryTimestamp;
        authorContribution = msg.value;
    }

    //if the correct hash is produced from the data of the correct output in a model
    //then the user gets ether.
    //contract calls the applicants model from another contract to validate
    function verifyInput(address applicantContract) notExpired notClaimed public
    {
        //instantiate the applicants solution attempt
        //check it outputs the correct solution
        MachineLearningSolutionAttempt mlAttempt;
        mlAttempt = MachineLearningSolutionAttempt(applicantContract);
        var (output, applicant) = mlAttempt.model(modelData);
        bytes32 hashOfValue = keccak256(abi.encodePacked(output));
        bytes32 hashOfCorrectOutput = keccak256(abi.encodePacked(modelData));
        if(hashOfValue == hashOfCorrectOutput)
        {
            claimed = true;
            winningContract = applicantContract;
            applicant.send(this.balance);
        }
    }

    function increaseAuthorContribution() payable public notExpired
    {
        require(msg.sender == author);
        authorContribution += msg.value;
    }

    function endContract() public notExpired
    {
        require(!claimed);
        selfdestruct(author);
    }
    
    function getBountyAmount() public view returns(uint) 
    {
        return this.balance;
    }

}
