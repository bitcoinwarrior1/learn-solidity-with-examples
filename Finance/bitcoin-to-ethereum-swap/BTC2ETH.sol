import "./btcrelayInterface" as btcrelayInterface;
import "./BtcParser" as BtcParser;

pragma solidity ^0.4.0;
// "0xbe086099e0ff00fc0cfbc77a8dd09375ae889fbd", "0x85af7e7A6F15874C139695d6d8DC276a39c2d601", 30, 100
//mainnet: 0xB649A551202D89c51f20eEd94545C7bA47be9841
contract BTC2ETH is BtcParser
{
    address public btcrelayAddress;
    bytes32[] public claimedTxs;
    address public admin;
    address public paymaster;
    uint public ether2BitcoinRate;
    bytes20 public bitcoinAddress;
    BtcParser public btcParser = new BtcParser();
    uint public feeRatio;

    constructor(bytes20 btcAddress, address adminAddr, uint initialRate, uint initialFeeRatio) public
    {
        admin = adminAddr;
        paymaster = msg.sender;
        bitcoinAddress = btcAddress;
        //default mainnet
        btcrelayAddress = 0x41f274c0023f83391DE4e0733C609DF5a124c3d4;
        ether2BitcoinRate = initialRate;
        feeRatio = initialFeeRatio;
    }

    function withdrawFunds(uint amount) public
    {
        require(msg.sender == admin);
        admin.transfer(amount);
    }

    function getFeeRatio() public returns(uint)
    {
        return feeRatio;
    }

    function replacePaymaster(address newPaymaster) public
    {
        require(msg.sender == admin);
        paymaster = newPaymaster;
    }

    //admin/paymaster tops up the contract here
    function() public payable
    {
        require(msg.sender == admin || msg.sender == paymaster);
    }

    function getRelayAddress() public returns(address)
    {
        return btcrelayAddress;
    }

    function getBitcoinAddress() public returns(bytes20)
    {
        return bitcoinAddress;
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

    //called by btcrelay contract on successful verification of a relayed transaction
    //uses the public key of the bitcoin address to generate the address
    //of the corresponding ether address
    //the same private key can claim the ether as was used to send the bitcoin
    function processTransaction(bytes rawTransaction, uint256 transactionHash) public returns (int256)
    {
        require(msg.sender == btcrelayAddress);
        bytes32 hashedRawTx = keccak256(rawTransaction);
        checkClaims(claimedTxs, hashedRawTx);
        bytes memory senderPubKey = getPubKeyFromTx(rawTransaction);
        address sender = address(keccak256(senderPubKey));
        var (amt1, address1, amt2, address2) = btcParser.getFirstTwoOutputs(rawTransaction);
        require(address1 == bitcoinAddress); //first output goes to us, second is change
        uint amountToTransfer = amt1 * ether2BitcoinRate;
        uint feeToAdmin = amountToTransfer / feeRatio;
        sender.transfer(amountToTransfer - feeToAdmin);
        claimedTxs.push(keccak256(rawTransaction));
        //admin gets a fee for providing service and liquidity
        admin.transfer(feeToAdmin);
        return int256(amountToTransfer);
    }

    function checkClaims(bytes32[] claimTxs, bytes32 hashedRawTx) internal
    {
        for(uint i = 0; i < claimedTxs.length; i++)
        {
            require(claimedTxs[i] != hashedRawTx);
        }
    }

    function seeClaimedTxs() public returns(bytes32[])
    {
        return claimedTxs;
    }

    function endContract() public
    {
        require(msg.sender == admin);
        selfdestruct(admin);
    }

}
