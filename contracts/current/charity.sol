pragma solidity ^0.4.11;
//donate with transparency and instant rebates
contract charity
{
    address charityAddress;
    bytes32 organisation;
    bytes32 websiteURL;

    event donation(address donor, uint amount);

    function() { throw; }

    function charity(bytes32 siteURL)
    {
        charityAddress = msg.sender;
        websiteURL = siteURL;
    }

    function donate()
    {
        //with tax rebate of 33%, remainder is sent away
        if(msg.sender.send(msg.value / 3) && charityAddress.send(this.balance))
        {
            donation(msg.sender, msg.value);
        }
        else throw;
    }

    function getCharityAddress() returns (address)
    {
        return charityAddress;
    }
}
