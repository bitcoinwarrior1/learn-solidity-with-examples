pragma solidity ^0.4.0;

contract escrow
{
    //architecture is such that one contract is to be used for one trade
    //between two parties
    //rationale is that you have reduced attack surface and prevent confusion
    //as to what deal is which, creating a neat setting of one contract for
    //each deal (easier to audit), also means that the negative consequences
    //of losing a private key of a party is reduced

    bool funded; //can only be funded once, so one contract for one deal
    address buyer;
    address seller;
    address authority; //sent back to this address if no agreement is reached
    uint tradeValue;
    uint contractFundedTimestamp;
    bool sellerSatisfied = false;
    bool buyerSatisfied = false;
    uint expiryTimestamp;
    bytes32 tradeId;

    event contractIsFunded(uint timestamp);
    event contractInitiated(uint timestamp, bytes32 tradeId);
    event contractEnded(uint timestamp, bytes32 tradeId);

    modifier buyerOrSellerOnly()
    {
        if(msg.sender != buyer || msg.sender != seller) throw;
        else _;
    }

    modifier cannotBeExpired()
    {
        if(block.timestamp >= expiryTimestamp)
        {
            fallBack(); //pay out to authority
            throw;
        }
        else _;
    }

    function() { throw; } //return ether minus gas if
    //you send ether to the contract incorrectly

    function escrow(address specifiedSeller, address specifiedBuyer,
        bytes32 tradeTitle, uint expiry)
    {
        seller = specifiedSeller;
        buyer = specifiedBuyer;
        authority = msg.sender;
        contractInitiated(block.timestamp, tradeTitle);
        expiryTimestamp = block.timestamp + expiry;
        tradeId = tradeTitle;
    }

    function fundContract() payable
    {
        if(msg.sender != buyer || funded) throw;
        tradeValue = msg.value;
        funded = true;
        contractFundedTimestamp = block.timestamp;
        contractIsFunded(contractFundedTimestamp);
    }

    function satisifed() buyerOrSellerOnly cannotBeExpired
    {
        if(msg.sender == seller)
        {
            sellerSatisfied = true;
        }
        else
        {
            buyerSatisfied = true;
        }

        if(buyerSatisfied && sellerSatisfied)
        {
            payout();
        }
    }

    //frees up space on the blockchain by suiciding
    //when the contract is settled

    function payout() internal //can only be called by the contract itself
    {
        contractEnded(block.timestamp, tradeId);
        suicide(seller);
    }

    function fallBack() internal
    {
        //kill the contract and send the ether to the authority
        contractEnded(block.timestamp, tradeId);
        suicide(authority);
    }

}
