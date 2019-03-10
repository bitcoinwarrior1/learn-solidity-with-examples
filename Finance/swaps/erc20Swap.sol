pragma solidity ^0.5.1;

contract erc20 {
    function transferFrom(address to, address from, uint amount) public returns(bool);
    function balanceOf(address owner) public returns (uint);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
}

contract erc20Swap {

    mapping (bytes32 => address) claimedSignatures;

    //requires that the seller has enabled an allowance to the contract
    function swapTokenForNativeCurrency(
        uint expiry,
        uint amount,
        address erc20ContractAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        bytes32 message = keccak256(abi.encodePacked(amount, expiry, msg.value, erc20ContractAddress));
        address seller = ecrecover(message, v, r, s);
        erc20 erc20Contract = erc20(erc20ContractAddress);
        require(erc20Contract.transferFrom(seller, msg.sender, amount));
        require(claimedSignatures[r] != seller);
        //don't allow the deal to be done multiple times
        claimedSignatures[r] = seller;
    }

}
