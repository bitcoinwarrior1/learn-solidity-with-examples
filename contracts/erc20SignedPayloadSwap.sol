pragma solidity ^0.5.1;

contract erc20 {
    function transferFrom(
        address to,
        address from,
        uint256 amount
    ) public returns (bool);

    function balanceOf(address owner) public returns (uint256);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);
}

contract erc20SignedPayloadSwap {
    mapping(bytes32 => address) claimedDeals;

    //requires that the seller has enabled an allowance to the contract
    function swapTokenForNativeCurrency(
        uint256 expiry,
        uint256 amount,
        address erc20ContractAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        bytes32 message = keccak256(
            abi.encodePacked(amount, expiry, msg.value, erc20ContractAddress)
        );
        address seller = ecrecover(message, v, r, s);
        erc20 erc20Contract = erc20(erc20ContractAddress);
        require(erc20Contract.transferFrom(seller, msg.sender, amount));
        bytes32 hashedTradeData = keccak256(abi.encodePacked(message, v, r, s));
        require(claimedDeals[hashedTradeData] != seller);
        //don't allow the deal to be done multiple times
        claimedDeals[hashedTradeData] = seller;
    }
}
