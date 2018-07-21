pragma solidity ^0.4.17;
pragma experimental ABIEncoderV2;
import "../Intergration/Reputation.sol";

contract VerifyModelByOutput
{
    address owner;
    address winner;
    uint bounty;
    bool assignmentComplete = false;
    uint highestScore;
    uint minimumScore;
    string ownerEmailAddress;
    string[] codeURLS;
    string assignmentInformationWebsiteURL;
    //can validate output as a simple boolean classification or something else
    //like validating multiple different outcomes with different data
    //can represent all this as bytes32 or if you want, change it to something simplier
    //like boolean etc for your needs
    //if output is small enough,
    //you could even represent all the outputs in one bytes32
    struct Submission
    {
        bytes32[] output;
        address submitter;
        //codeURL is optional, maybe the submitter wants to give the code to everyone
        //or shares a link that only the owner can open.
        string codeURL;
    }

    bytes32[] correctOutput;
    Submission[] submissions;

    constructor(
        string ownerEmail,
        uint requiredScore,
        string assignmentURL,
        address reputationContract) public payable
    {
        owner = msg.sender;
        bounty = msg.value;
        ownerEmailAddress = ownerEmail;
        //if below this score then no one can win.
        minimumScore = requiredScore;
        assignmentInformationWebsiteURL = assignmentURL;
        //require a reputatble owner, this is experimental
        Reputation reputation = Reputation(reputationContract);
        var (positive, negative) = reputation.getNumberOfPositiveAndNegativeReviews(owner);
        require(positive > 20 && positive > negative * 5);
    }
    
    function getAssignmentWebsite() returns(string) 
    {
        return assignmentInformationWebsiteURL;
    }

    function topupBounty() public payable
    {
        require(msg.sender == owner);
        bounty += msg.value;
    }

    function getBounty() public view returns(uint)
    {
        return bounty;
    }

    //owner can cross check submissions before submitting the correct results
    function submitCorrectOutputForSubmissions(bytes32[] output) public
    {
        require(msg.sender == owner);
        //if no one applies then the owner should terminate the contract
        require(submissions.length != 0);
        correctOutput = output;
        assignmentComplete = true;
        winner = checkForWinner();
    }

    function submitOutput(Submission submission) public
    {
        require(assignmentComplete == false);
        submissions.push(submission);
    }

    function checkForWinner() internal returns(address)
    {
        //being verbose is probably a good thing in solidity
        require(assignmentComplete == true);
        highestScore = 0;
        address applicant;
        for(uint i = 0; i < submissions.length; i++)
        {
            uint accuracy = checkAccuracyRate(submissions[i].output);
            if(accuracy > highestScore && accuracy >= minimumScore)
            {
                highestScore = accuracy;
                applicant = submissions[i].submitter;
            }
        }
        return applicant;
    }

    function getCodeURLSForSubmitter(address submitter) public returns (string[])
    {
        string[] urls;
        for(uint i = 0; i < submissions.length; i++)
        {
            if(submissions[i].submitter == submitter)
            {
                urls.push(submissions[i].codeURL);
            }
        }
        return urls;
    }

    function checkAccuracyRate(bytes32[] output) internal view returns(uint)
    {
        require(assignmentComplete == true);
        uint score = 0;
        for(uint i = 0; i < output.length; i++)
        {
            if(output[i] == correctOutput[i])
            {
                score += 1;
            }
        }
        return score;
    }

    //owner needs to approve the payout as they will probably want the winner to hand over
    //their model to them. If they do not then the owner will not be satisfied.
    //it is up to the owner if they want to open source the model or not
    function approvePayout() public
    {
        require(msg.sender == owner);
        winner.transfer(bounty);
    }

    function cancelContract() public
    {
        require(msg.sender == owner);
        //owner cannot kill the contract once they have accepted
        //the assignment as complete
        //this prevents cheating from the owner and
        //creates an incentive for them to collaborate with the winner
        //This is not foulproof as the owner can still cheat by not completing the assignment
        //TODO need a solution to this else can use reputation.
        require(assignmentComplete == false);
        selfdestruct(owner);
    }
}
