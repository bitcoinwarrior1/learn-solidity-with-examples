import "./btcrelayInterface" as btcrelayInterface;
import "./BtcParser" as BtcParser;

pragma solidity ^0.4.0;
// "0x0000000000000005BE086099E0FF00FC0CFBC77A8DD09375AE889FBD259A0367", "0x85af7e7A6F15874C139695d6d8DC276a39c2d601", 30, 100
//mainnet: 0xd4775c9AbfB88e0e64011d564ae6A1C120826464
contract BTC2ETH is BtcParser, btcrelayInterface
{
    address _btcrelayAddress;
    bytes32[] claimedTxs;
    address admin;
    address paymaster; 
    uint ether2BitcoinRate;
    bytes20 bitcoinAddress;
    btcrelayInterface btcrelay;
    BtcParser btcParser = new BtcParser();
    uint feeRatio;

    constructor(bytes20 btcAddress, address adminAddr, uint initialRate, uint initialFeeRatio) public
    {
        admin = adminAddr;
        paymaster = msg.sender;
        bitcoinAddress = btcAddress;
        //default mainnet
        _btcrelayAddress = 0x41f274c0023f83391DE4e0733C609DF5a124c3d4;
        btcrelay = btcrelayInterface(_btcrelayAddress);
        ether2BitcoinRate = initialRate;
        feeRatio = initialFeeRatio;
    }

    //admin/paymaster tops up the contract here
    function() public payable
    {
        require(msg.sender == admin || msg.sender == paymaster);
    }

    function setEther2BitcoinPrice(uint rate) public
    {
        require(msg.sender == admin);
        ether2BitcoinRate = rate;
    }

    function setFeeRation(uint newFeeRatio) public
    {
        require(msg.sender == admin);
        feeRatio = newFeeRatio;
    }

    function getCurrentRate() public view returns(uint)
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

        checkClaims(claimedTxs, hashedRawTx);

        uint256 response = btcrelay.verifyTx(
            rawTransaction,
            transactionIndex,
            merkleSibling,
            blockHash
        );

        require(response > 0); //returns 0 if nothing found
        bytes32 senderPubKey = getSenderPub(rawTransaction, blockHash);
        address sender = address(keccak256(senderPubKey));
        var (amt1, address1, amt2, address2) = btcParser.getFirstTwoOutputs(rawTransaction);
        uint amountToTransfer = amt1 * ether2BitcoinRate;
        makeTransfers(amountToTransfer, sender, rawTransaction, blockHash);
    }

    //need to split up functions else the stack will run out
    function makeTransfers(
        uint amountToTransfer,
        address sender,
        bytes rawTransaction,
        int256 blockHash) internal
    {
        uint feeToAdmin = amountToTransfer / feeRatio;
        sender.transfer(amountToTransfer - feeToAdmin);
        claimedTxs.push(keccak256(rawTransaction));
        //admin gets a fee for providing service and liquidity
        admin.transfer(feeToAdmin);
    }

    function checkClaims(bytes32[] claimTxs, bytes32 hashedRawTx) internal
    {
        for(uint i = 0; i < claimedTxs.length; i++)
        {
            require(claimedTxs[i] != hashedRawTx);
        }
    }

    function getSenderPub(bytes rawTransaction, int256 blockHash) returns(bytes20)
    {
        var (amt1, address1, amt2, address2) = btcParser.getFirstTwoOutputs(rawTransaction);
        require(address1 == bitcoinAddress); //first output goes to us, second is change
        bytes20 senderPubKey = btcParser.parseOutputScript(
            rawTransaction,
            0,
            rawTransaction.length
        );
        return senderPubKey;
    }

}
