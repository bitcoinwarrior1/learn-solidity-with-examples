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
    mapping(address => uint) contributions;
    uint expiry;
    //contribution must be burned to prevent author gaming the system
    uint authorContribution;
    bool claimed = false;
    address[] contributors;
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    address winner;
    string winningFormula;

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
        burnAddress.transfer(msg.value);
    }

    //if the correct hash is produced from the data of the correct output in a model
    //then the user gets ether.
    //this has issues, what stops the creator (who knows the correct output manually)
    //from taking all the ether?
    //TODO use reputation or make it impossible for the creator to profit?
    //will use the latter first, maybe something else will come along
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

    function addContribution() payable public
        isSmallerThanAuthorContribution(msg.value) notExpired notClaimed
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

    function increaseAuthorContribution() payable public notExpired
    {
        require(msg.sender == author);
        authorContribution += msg.value;
        burnAddress.transfer(msg.value);
    }

    function endContract() public notExpired
    {
        require(!claimed);
        for(uint i = 0; i < contributors.length; i++)
        {
            //refund contributors
            contributors[i].transfer(contributions[contributors[i]]);
        }
        selfdestruct(author);
    }

}
