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

pragma solidity ^0.4.17;
contract MachineLearningVerification
{
    address author;
    bytes32 hashOfCorrectOutput;
    uint expiry;
    uint authorContribution;
    bool claimed = false;
    address winner;
    string winningFormula;

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

    constructor(bytes32 outputHash, uint expiryTimestamp) public payable
    {
        author = msg.sender;
        hashOfCorrectOutput = outputHash;
        expiry = expiryTimestamp;
        authorContribution = msg.value;
    }

    //if the correct hash is produced from the data of the correct output in a model
    //then the user gets ether.
    //TODO prevent miner from cheating with this input, might require zksnarks
    function verifyInput(bytes32 outputHash, string formula) notExpired notClaimed public
    {
        //need to hash the data and then hash it again with contract address
        //else you would have to submit all the data and hash it (expensive)
        //also should be specific to the contract
        bytes32 hashOfValue = keccak256(outputHash, this);
        if(hashOfValue == hashOfCorrectOutput)
        {
            claimed = true;
            winningFormula = formula;
        }
    }

    //if author is satisifed with the winning forumla he can approve the payout
    //author should be able to reproduce valid outputs using the formula
    //and potentially be able to apply it to other data sets
    function payoutWinner() public
    {
        require(msg.sender == author);
        require(winner != address(0));
        require(claimed);
        //winner gets all the ether in the contract and the contract ends
        selfdestruct(winner);
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
    
    function getBountyAmount() public returns(uint) 
    {
        return this.balance;
    }

}
