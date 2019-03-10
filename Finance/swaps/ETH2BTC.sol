import "https://raw.githubusercontent.com/James-Sangalli/learn-solidity-with-examples/master/Finance/bitcoin-to-ethereum-swap/BtcParser.sol";
import "https://raw.githubusercontent.com/summa-tx/bitcoin-spv/master/contracts/ValidateSPV.sol";
pragma experimental ABIEncoderV2;
pragma solidity 0.4.25;

contract ETH2BTC {

    struct Order {
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

    //"0xbe086099e0ff00fc0cfbc77a8dd09375ae889fbd", "0x85af7e7A6F15874C139695d6d8DC276a39c2d601", 30, 100
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
        etherToBitcoinRate = initialRate;
    }

    function() public payable { revert(); }

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

    //market maker can only withdraw the order funds on proof of a bitcoin transaction to the buyer
    function proveBitcoinTransaction(
      bytes rawTransaction,
      uint256 transactionHash,
      bytes32 _txid,
      bytes32 _merkleRoot,
      bytes _proof,
      uint _index
    ) public returns (bool)
    {
        bytes memory senderPubKey = BtcParser.getPubKeyFromTx(rawTransaction);
        bytes20 senderAddress = bytes20(sha256(sha256(senderPubKey)));
        //require that the market maker sent the bitcoin
        require(senderAddress == bitcoinAddress);
        require(ValidateSPV.prove(_txid, _merkleRoot, _proof, _index));
        //first output goes to the order maker by deriving their btc address
        //from their ether pub key
        var (amt1, address1, amt2, address2) = BtcParser.getFirstTwoOutputs(rawTransaction);
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
                //withdraw the ether for the trade
                admin.transfer(orders[address1][i].etherAmount);
                return true;
            }
        }
        return false;
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
        uint btcAmount = msg.value * etherToBitcoinRate;
        //two weeks from order, should be processed well before this date but includes a margin of safety
        uint dueDate = block.timestamp + 1296000;
        Order memory newOrder = Order(msg.value, btcAmount, dueDate, refundAddr);
        orders[receiverBtcAddress].push(newOrder);
    }

    function getOrders(bytes20 bitcoinAddress) public view returns(Order[])
    {
        return orders[bitcoinAddress];
    }

    function hashOrder(Order order) internal returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                order.etherAmount,
                order.bitcoinAmountAtRate,
                order.dueTimestamp,
                order.refundAddress
            )
        );
    }

    //call this if bitcoin transaction never arrives and order is still present
    function getRefundForOrder(Order order, bytes20 orderOwner) public
    {
        bool orderIsPresent = false;
        uint pos = 0;
        bytes32 hashOfOrder = hashOrder(order);
        for(uint i = 0; i < orders[orderOwner].length; i++)
        {
            Order memory currentOrder = orders[orderOwner][i];
            bytes32 orderHash = hashOrder(currentOrder);
            if(orderHash == hashOfOrder)
            {
                orderIsPresent = true;
                pos = i;
                break;
            }
        }
        require(orderIsPresent);
        require(order.dueTimestamp < block.timestamp);
        order.refundAddress.transfer(order.etherAmount);
        delete orders[orderOwner][pos];
    }

}
