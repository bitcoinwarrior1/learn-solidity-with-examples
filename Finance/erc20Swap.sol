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
        uint price, 
        uint amount,
        address erc20ContractAddress,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) public payable returns(bool) {
        bytes32 message = formMessage(amount, expiry, price, erc20ContractAddress);
        address seller = ecrecover(message, v, r, s);
        erc20 erc20Contract = erc20(erc20ContractAddress);
        require(erc20Contract.allowance(seller, address(this)) >= amount);
        require(claimedSignatures[r] != seller);
        //don't allow the deal to be done multiple times
        claimedSignatures[r] = seller;
        return erc20Contract.transferFrom(seller, msg.sender, amount);
    }
    
    function formMessage(
        uint amount,
        uint expiry,
        uint price,
        address contractAddress
    ) internal pure returns(bytes32) {
        bytes memory message = new bytes(105);
        for(uint i = 0; i < 32; i++) {
            message[i] = byte(bytes32(amount << (8 * i)));
        }
        for(uint i = 0; i < 32; i++) {
            message[i + 32] = byte(bytes32(expiry << (8 * i)));
        }
        for(uint i = 0; i < 32; i++) {
            message[i + 64] = byte(bytes32(price << (8 * i)));
        }
        for(uint i = 0; i < 20; i++) {
            message[i + 96] = byte(bytes20(contractAddress) << (8 * i));
        }
        return keccak256(message);
    }
    
    
}
