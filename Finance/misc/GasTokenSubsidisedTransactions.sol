pragma solidity 0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    //gas token specific
    function free(uint value) public;
}

contract GasTokenSubsidizedTransactionsERC20 {
    address public admin;
    uint public priceOfGasToken;
    address gasTokenContractAddress = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
    ERC20Interface gasTokenContract = ERC20Interface(gasTokenContractAddress);
    
    constructor(uint initialGasTokenPrice) public {
        admin = msg.sender;
        priceOfGasToken = initialGasTokenPrice;
    }
    
    //User must approve this contract for transfers 
    function transferFromDelegate(
        address from, 
        address to, 
        uint amount,
        address contractToCall
    ) public payable {
        require(from == msg.sender);
        uint numberOfGasTokensToUse = msg.value / priceOfGasToken;
        gasTokenContract.free(numberOfGasTokensToUse);
        ERC20Interface transferFromContract = ERC20Interface(contractToCall);
        transferFromContract.transferFrom(from, to, amount);
    }

}
