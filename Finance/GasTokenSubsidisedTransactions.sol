pragma solidity 0.4.24;
//implement empty functions just for signatures which then call the actual deployed contracts
contract GasTokenInterface {
    function freeFromUpTo(address from, uint256 value) public returns (uint256 freed) {}
    function balanceOf(address owner) public constant returns (uint256 balance) {}
}

contract ERCInterface {
    function transfer(address to, uint tokens) public returns (bool success){}
    function approve(address spender, uint tokens) public returns (bool success){}
    function transferFrom(address from, address to, uint tokens) public returns (bool success){}
}

/* This contract allows for cheap transactions when the network in congested by 
    burning up GasTokens purchased during off peak times. Users benefit by getting a much cheaper transactions
    and the admin benefits by selling their gas tokens to the user on transaction at a rate higher than they purchased this from.
    this is win win because you can only use GasToken for discounting and can thus not profit directly from them except in an arrangement like this
    and the user gets cheaper transactions during peak times when tx fees are higher than the set price in the contract for gas tokens. 

    Benefits for wallet providers and exchanges:
    - Cheap txs for your wallet/exchange during peak hour
    - Profitable for the wallet provider as you sell off your gas tokens to the user 
      and the user gets a cheaper tx, this is win-win
    - Pareto efficiency: transactions are expensive, high value and high volume during peaks meaning the majority of 
      your expenses for tansactions will be during such peaks where this service is essential
    - Insurance against high transaction costs for exchanges 
*/
//this compiler version is crucial for this problem: https://github.com/ethereum/solidity/issues/2999
pragma experimental "v0.5.0";
//NOTE: also compatible with ERC721 as it uses the same function signature as ERC20 for transferFrom & approve 
contract GasTokenSubsidisedTransactions {
    GasTokenInterface gasTokenInterface = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);
    //GST2 uses selfdestruct which cost 5000 + 700 gas and refunds 24000
    uint public constant gasPerToken = 18300; 
    uint public costOfToken = 20000000000; //set to 20 gwei for example 
    address admin;
    
    constructor() public {
        admin = msg.sender;
    }
    
    function changeCostOfToken(uint newCost) public {
        require(msg.sender == admin);
        costOfToken = newCost;
    }
    
    /*
        to implement useOurGasToken() in your own contract you can something like the following example: 
        function gasTokenTransfer(address to, uint amt) payable {
            require(tx.gasPrice > GasTokenSubsidisedTransactions.costOfToken);
            GasTokenSubsidisedTransactions.useOurGasToken();
            ....[transfer logic]
        }
        
        This would reduce the gas costs for the user during high peak transactions 
    */
    
    function useOurGasToken() public payable {
        require(msg.value != 0);
        uint amountOfTokensToUse = msg.value / costOfToken;
        require(gasTokenInterface.balanceOf(this) >= amountOfTokensToUse);
        require(gasTokenInterface.freeFromUpTo(this, amountOfTokensToUse) 
            == amountOfTokensToUse);
    }
    
    function getERCContract(
        address contractToCall, 
        uint value
    ) internal returns (ERCInterface) {
        //free up the token at the set price and make the transaction significatly cheaper
        //see notes here: https://github.com/projectchicago/gastoken/blob/master/contract/GST2_ETH.sol#L157 on this calculation
        gasTokenInterface.freeFromUpTo(this, value);
        return ERCInterface(contractToCall);
    }
    
    // This can still be effective for people like exchanges with high volume who 
    // can move their funds to the contract and use the contract for transactions
    function transferFromDelegate(
        address to,
        uint amount, 
        address contractToCall,
        uint gasTokensToConsume
    ) public {
        require(msg.sender == admin);
        ERCInterface contractErc = getERCContract(
            contractToCall, 
            gasTokensToConsume
        );
        contractErc.transferFrom(this, to, amount);
    }
    
    //much cheaper to withdraw on occasion 
    //rather than each time someone uses the delegates
    //this is because you can withdraw many transactions worth of 
    //ether in one go costing 21000 gas vs 21000 gas each delegate call
    function withdrawEther(uint value) public {
        require(msg.sender == admin);
        admin.transfer(value);
    }
}