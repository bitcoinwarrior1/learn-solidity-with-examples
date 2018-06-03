//the purpose of this contract is to show potential purpose
//for intergrating services based on tokens
pragma solidity ^0.4.17;
pragma experimental ABIEncoderV2;
//the interface for such intergration contracts as the users will define their own 
//implementations
contract IntergrationERC 
{
    address admin;
    enum Tier 
    {
        //determine the level of service for the token type
        first,
        second,
        third
    }
    struct ApprovedTokensFungible 
    {
        address contractAddress; 
        Tier tier; 
        uint balance;
    }
    
    struct ApprovedTokensNonFungible 
    {
        address contractAddress; 
        Tier tier; 
        uint[] balance;
    }
    mapping (address => uint) balanceFungible;
    mapping (address => uint[]) balanceNonFungible;
    function handleTiers(Tier tier, address caller);
    function addApprovedFungibleTokens(ApprovedTokensFungible[] approvedTokensFungibleToAdd);
    function addApprovedNonFungibleTokens(ApprovedTokensNonFungible[] approvedTokensNonFungibleToAdd);
}

contract IntergrationExample is IntergrationERC
{
    //TODO implement example tiers
    //TODO check balance and tier, once checked the user can get the benefits
    address admin;
    ApprovedTokensFungible[] approvedTokensFungible;
    ApprovedTokensNonFungible[] approvedTokensNonFungible;
    mapping (address => uint) balanceFungible;
    mapping (address => uint[]) balanceNonFungible;
    
    modifier adminOnly() 
    {
        require(msg.sender != admin);
        _;
    }
    
    constructor(
        ApprovedTokensFungible[] intialApprovedTokensFungible, 
        ApprovedTokensNonFungible[] initialApprovedTokensNonFungible,
        address administrator
    ) public
    {
        addApprovedFungibleTokens(intialApprovedTokensFungible);
        addApprovedNonFungibleTokens(initialApprovedTokensNonFungible);
        admin = administrator;
    }
    
    function addApprovedFungibleTokens(ApprovedTokensFungible[] 
            approvedTokensFungibleToAdd) public adminOnly
    {
        for(uint i = 0; i < approvedTokensFungibleToAdd.length; i++)
        {
            approvedTokensFungible.push(approvedTokensFungibleToAdd[i]);    
        }
    }
    
    function addApprovedNonFungibleTokens(ApprovedTokensNonFungible[]
            approvedTokensNonFungibleToAdd) public adminOnly
    {
        for(uint i = 0; i < approvedTokensNonFungibleToAdd.length; i++)
        {
            approvedTokensNonFungible.push(approvedTokensNonFungibleToAdd[i]);    
        }
    }

}
