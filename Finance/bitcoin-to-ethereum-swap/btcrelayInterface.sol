//fool the compiler into allowing contract with only method signatures
//I used this because btcrelay is already deployed but is in serpent
//to mitigate the fact that you cannot use serpent in solidity
//I used the function signatures without the logic and called them using the existing deployment
//Since it is implemented in serpent and the bytecode is the same
//you can call the functions with the function signatures and do not have to implement the logic
//as it is already done in the deployment
pragma solidity ^0.4.0;
contract btcrelayInterface
{
    bytes4 relayDestination = bytes4(keccak256("processTransaction(bytes,uint256) returns(int256)"));
    uint256 heaviestBlock;
    //highest score among all blocks (so far)
    uint256 highScore;

    function setInitialParent(bytes32 blockHash, uint256 height, uint256 chainWork) public returns(uint256){}

    function storeBlockHeader(string blockHeaderBytes) public returns (uint256){}

    function verifyTx(bytes txBytes, uint256 txIndex, bytes32[] sibling, uint256 txBlockHash) public payable returns (uint256){}

    function helperVerifyHash__(
        uint256 txHash,
        uint256 txIndex,
        bytes32[] siblings,
        bytes32 txBlockHash
    ) public payable returns(uint256){}

    function relayTx(
        bytes32 txBytes,
        bytes32[] siblings,
        bytes32 txBlockHash,
        address contractAddress
    ) public payable returns(uint256){}

    function computeMerkle(
        bytes32 txHash,
        uint256 txIndex,
        bytes32[] siblings
    ) public returns (uint256){}

    function within6Confirmations(bytes32 txBlockHash) public returns(bool){}

    function getFeeRecipient(uint256 blockHash) public returns(address){}

}
