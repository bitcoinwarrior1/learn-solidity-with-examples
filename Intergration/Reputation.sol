pragma experimental ABIEncoderV2;
pragma solidity ^0.4.17;
//simple reputation contract that requires you to burn ether
//to vote on the person
//this prevents sybil attacks
contract Reputation
{
    uint feedbackSubmissionFee;
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    //true = positive, false = negative
    struct Feedback
    {
        bool isPositive;
        address reviewer;
        string optionalMessage;
    }

    mapping(address => Feedback[]) ratings;

    constructor(uint feedbackFee) public
    {
        feedbackFee = feedbackSubmissionFee;
    }

    function submitFeedback(Feedback feedback, address recipientOfFeedback) payable public
    {
        require(msg.value == feedbackSubmissionFee);
        burnAddress.transfer(msg.value);
        ratings[recipientOfFeedback].push(feedback);
    }

    function getFeedbackForAddress(address recipient) public view returns(Feedback[])
    {
        return ratings[recipient];
    }

    function getNumberOfPositiveAndNegativeReviews(address recipient) public view
        returns(uint positive, uint negative)
    {
        Feedback[] feedback = ratings[recipient];
        positive = 0;
        negative = 0;
        for(uint i = 0; i < feedback.length; i++)
        {
            if(feedback[i].isPositive) {
                positive++;
            }
            else
            {
                negative++;
            }
        }
    }
}