//would rather import it and redeploy it anew then rely on the deployed version as it is possible to change the address
//to an attackers one
import "./btcrelayInterface" as btcrelayInterface;
import "./BtcParser" as BtcParser;

pragma solidity ^0.4.0;
pragma experimental ABIEncoderV2;
contract ETH2BTC is BtcParser
{

    struct Order
    {
      uint etherAmount;
      uint bitcoinAmountAtRate;
      uint dueTimestamp;
      address refundAddress;
    }

    mapping (bytes20 => Order[]) orders; //bytes20 is a bitcoin address
    address public btcrelayAddress;
    address public admin;
    uint public etherToBitcoinRate;
    bytes20 public bitcoinAddress;
    BtcParser public btcParser = new BtcParser();

    constructor(
      bytes20 btcAddress,
      address adminAddr,
      uint initialRate,
      uint initialFeeRatio
    ) public
    {
        admin = adminAddr;
        bitcoinAddress = btcAddress;
        //default mainnet
        btcrelayAddress = 0x41f274c0023f83391DE4e0733C609DF5a124c3d4;
        etherToBitcoinRate = initialRate;
    }

    function withdrawFunds(uint amount) public
    {
        require(msg.sender == admin);
        admin.transfer(amount);
    }

    //admin can top up the contract
    function() public payable
    {
        require(msg.sender == admin);
    }

    function getRelayAddress() public returns(address)
    {
        return btcrelayAddress;
    }

    function getBitcoinAddress() public returns(bytes20)
    {
        return bitcoinAddress;
    }

    function setEtherToBitcoinRate(uint rate) public
    {
        require(msg.sender == admin);
        etherToBitcoinRate = rate;
    }

    function getCurrentRate() public view returns(uint)
    {
        return etherToBitcoinRate;
    }

    //called by btcrelay contract on successful verification of a relayed transaction
    function processTransaction(
      bytes rawTransaction,
      uint256 transactionHash
    ) public returns (int256)
    {
        require(msg.sender == btcrelayAddress);
        bytes memory senderPubKey = getPubKeyFromTx(rawTransaction);
        bytes20 senderAddress = bytes20(sha256(sha256(senderPubKey)));
        //require that the market maker sent the bitcoin
        require(senderAddress == bitcoinAddress);
        //first output goes to the order maker by deriving their btc address
        //from their ether pub key
        var (amt1, address1, amt2, address2) = btcParser.getFirstTwoOutputs(rawTransaction);
        for(uint i = 0; i < orders[address1].length; i++)
        {
            //if two identical orders, simply grab the first one
            if(orders[address1][i].bitcoinAmountAtRate == amt1)
            {
                //once order is found, delete it
                //that way it is now claimed and can't be claimed multiple times
                //order can be claimed even if past due date, so long as the sender
                //hasn't already got a refund (in which case it would be refunded and the order deleted)
                //market maker should ensure they relay the bitcoin tx before expiry, else they could
                //be cheated out of their bitcoins by someone claiming to have not received them
                //when in fact they have but it hasn't been relayed
                delete orders[address1][i];
                return 1;
            }
        }
        return 0;
    }

    //sender can provide any bitcoin address they want to receive bitcoin on
    function placeOrder(
        bytes20 receiverBtcAddress,
        address refundAddr
    ) public payable
    {
        require(msg.value > 0);
        //in case user doesn't set the refund address
        if(refundAddr == address(0)) refundAddr = msg.sender;
        //fees can be done by using a slightly above market rate
        uint btcAmount = msg.value * etherToBitcoinRate;
        //two weeks from order, should be processed well before this date but includes a margin of safety
        uint dueDate = block.timestamp + 1296000;
        Order memory newOrder = Order(msg.value, btcAmount, dueDate, refundAddr);
        orders[receiverBtcAddress].push(newOrder);
    }

    function getOrders(bytes20 bitcoinAddress) public returns(Order[])
    {
        return orders[bitcoinAddress];
    }

    //call this if bitcoin transaction never arrives and order is still present
    function getRefundForOrder(
      Order order,
      bytes20 orderOwner
    ) public
    {
        bool orderIsPresent = false;
        uint pos = 0;
        bytes32 hashOfOrder = keccak256(
            abi.encodePacked(
                order.etherAmount,
                order.bitcoinAmountAtRate,
                order.dueTimestamp,
                order.refundAddress
            )
        );
        for(uint i = 0; i < orders[orderOwner].length; i++)
        {
            Order memory currentOrder = orders[orderOwner][i];
            bytes32 orderHash = keccak256(
                abi.encodePacked(
                    currentOrder.etherAmount,
                    currentOrder.bitcoinAmountAtRate,
                    currentOrder.dueTimestamp,
                    currentOrder.refundAddress
                )
            );
            if(orderHash == hashOfOrder)
            {
                orderIsPresent = true;
                pos = i;
                break;
            }
        }
        require(orderIsPresent);
        require(order.dueTimestamp > block.timestamp);
        order.refundAddress.transfer(order.etherAmount);
        delete orders[orderOwner][pos];
    }

    //TODO remove once sure the contract is fine
    function endContract() public
    {
        require(msg.sender == admin);
        selfdestruct(admin);
    }

}
