import "https://github.com/ethereum/btcrelay/blob/develop/btcrelay.se" as BtcRelay;
import "https://github.com/James-Sangalli/Solidity-Contract-Examples/blob/eth-2-btc-swap/Finance/bitcoin-to-ethereum-swap/BtcParser.sol" as BtcParser;
pragma solidity ^0.4.0;
contract BTC2ETH is BTC
{
    address _btcrelayAddress = 0x41f274c0023f83391DE4e0733C609DF5a124c3d4;
    bytes[] claimedTxs; 
    address admin;
    uint16 ether2BitcoinRate;
    bytes20 bitcoinAddress;
    
    constructor(bytes20 btcAddress) public
    {
        admin = msg.sender;
        bitcoinAddress = btcAddress;
    }
    
    //admin tops up the contract here
    function topupContract() public payable 
    {
        require(msg.sender == admin);
    }
    
    function setEther2BitcoinPrice(uint16 rate) public
    {
        require(msg.sender == admin);
        ether2BitcoinRate = rate;
    }
    
    function getCurrentRate() public view returns(uint16)
    {
        return ether2BitcoinRate;
    }
    
    // rawTransaction - raw bytes of the transaction
    // transactionIndex - transaction's index within the block, as int256
    // merkleSibling - array of the sibling hashes comprising the Merkle proof, as int256[]
    // blockHash - hash of the block that contains the transaction, as int256
    //uses the public key of the bitcoin address to generate the address
    //of the corresponding ether address
    //the same private key can claim the ether as was used to send the bitcoin
    function bitcoin2EthereumSwap(
        bytes rawTransaction, 
        int256 transactionIndex, 
        int256[] merkleSibling, 
        int256 blockHash
    ) public
    {
        //verify transaction, if valid add it to the list
        //derive the corresponding ethereum address by getting the public key
        //of the bitcoin sender and casting it to the address
        //pay out the amount of eth to the address applied by the daily rate
        bytes32 hashedRawTx = keccak256(rawTransaction);
        for(uint i = 0; i < claimedTxs.length; i++) 
        {
            require(claimedTxs[i] != hashedRawTx);
        }

        bytes4 relayFunction = bytes4(keccak256(
            "verify(bytes rawTransaction,int256 transactionIndex,int256[] merkleSibling,int256 blockHash)"
        ));
        
        BtcRelay btcrelay = new BtcRelay.at(_btcrelayAddress);
        BtcParser btcParser = new BtcParser;
        
        uint256 response = btcrelay.verifyTx.call(
            relayFunction, 
            rawTransaction, 
            transactionIndex, 
            merkleSibling,
            blockHash
        );
        require(response > 0); //returns 0 if nothing found
        var (amt1, address1, amt2, address2) = BtcParser.getFirstTwoOutputs(rawTransaction);
        require(address1 == bitcoinAddress || address2 == bitcoinAddress);
        bytes20 senderPubKey = btcParser.parseOutputScript(
            rawTransaction,
            0, 
            rawTransaction.length
        );
        address sender = address(keccak256(abi.encodePacked(senderPubKey)));
        sender.transfer(amt1 * ether2BitcoinRate);
        claimedTxs.push(keccak256(rawTransaction));
    }
    
}
