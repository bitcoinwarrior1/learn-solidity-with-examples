pragma solidity ^0.5.10;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );

    //gas token specific
    function free(uint256 value) public;
}

contract GasTokenSubsidizedTransactionsERC20 {
    address public admin;
    uint256 public priceOfGasToken;
    address gasTokenContractAddress =
        0x0000000000b3F879cb30FE243b4Dfee438691c04;
    ERC20Interface gasTokenContract = ERC20Interface(gasTokenContractAddress);

    constructor(uint256 initialGasTokenPrice) public {
        admin = msg.sender;
        priceOfGasToken = initialGasTokenPrice;
    }

    //User must approve this contract for transfers
    function transferFromDelegate(
        address from,
        address to,
        uint256 amount,
        address contractToCall
    ) public payable {
        require(from == msg.sender);
        uint256 numberOfGasTokensToUse = msg.value / priceOfGasToken;
        gasTokenContract.free(numberOfGasTokensToUse);
        ERC20Interface transferFromContract = ERC20Interface(contractToCall);
        transferFromContract.transferFrom(from, to, amount);
    }
}
