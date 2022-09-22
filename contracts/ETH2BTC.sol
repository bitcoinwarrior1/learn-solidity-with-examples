import "./summa-tx/BtcParser.sol";
import "./summa-tx/ValidateSPV.sol";
pragma experimental ABIEncoderV2;
pragma solidity ^0.5.10;

contract ETH2BTC {
    struct Order {
        uint256 etherAmount;
        uint256 bitcoinAmountAtRate;
        uint256 dueTimestamp;
        address payable refundAddress;
    }

    mapping(bytes20 => Order[]) public orders; // btc address to Order
    address public btcrelayAddress;
    address payable public admin;
    uint256 public etherToBitcoinRate;
    bytes20 public bitcoinAddress;

    constructor(
        bytes20 btcAddress,
        address payable adminAddr,
        uint256 initialRate,
        uint256 initialFeeRatio
    ) public {
        admin = adminAddr;
        bitcoinAddress = btcAddress;
        //default mainnet
        etherToBitcoinRate = initialRate;
    }

    function setEtherToBitcoinRate(uint256 rate) public {
        require(msg.sender == admin);
        etherToBitcoinRate = rate;
    }

    //market maker can only withdraw the order funds on proof of a bitcoin transaction to the buyer
    function proveBitcoinTransaction(
        bytes memory rawTransaction,
        uint256 transactionHash,
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes memory _proof,
        uint256 _index
    ) public returns (bool) {
        bytes memory senderPubKey = BtcParser.getPubKeyFromTx(rawTransaction);
        bytes20 senderAddress = bytes20(
            sha256(abi.encodePacked(sha256(senderPubKey)))
        );
        //require that the market maker sent the bitcoin
        require(senderAddress == bitcoinAddress);
        require(ValidateSPV.prove(_txid, _merkleRoot, _proof, _index));
        //first output goes to the order maker by deriving their btc address
        //from their ether pub key
        (
            uint256 amt1,
            bytes20 address1,
            uint256 amt2,
            bytes20 address2
        ) = BtcParser.getFirstTwoOutputs(rawTransaction);
        for (uint256 i = 0; i < orders[address1].length; i++) {
            //if two identical orders, simply grab the first one
            if (orders[address1][i].bitcoinAmountAtRate == amt1) {
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
    function placeOrder(bytes20 receiverBtcAddress, address payable refundAddr)
        public
        payable
    {
        require(msg.value > 0);
        //in case user doesn't set the refund address
        if (refundAddr == address(0)) refundAddr = msg.sender;
        uint256 btcAmount = msg.value * etherToBitcoinRate;
        //two weeks from order, should be processed well before this date but includes a margin of safety
        uint256 dueDate = block.timestamp + 1296000;
        Order memory newOrder = Order(
            msg.value,
            btcAmount,
            dueDate,
            refundAddr
        );
        orders[receiverBtcAddress].push(newOrder);
    }

    function hashOrder(Order memory order) internal returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    order.etherAmount,
                    order.bitcoinAmountAtRate,
                    order.dueTimestamp,
                    order.refundAddress
                )
            );
    }

    // call this if bitcoin transaction never arrives and order is still present
    function getRefundForOrder(Order memory order, bytes20 orderOwner) public {
        bool orderIsPresent = false;
        uint256 pos = 0;
        bytes32 hashOfOrder = hashOrder(order);
        for (uint256 i = 0; i < orders[orderOwner].length; i++) {
            Order memory currentOrder = orders[orderOwner][i];
            bytes32 orderHash = hashOrder(currentOrder);
            if (orderHash == hashOfOrder) {
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

contract ETH2BTCFuzz is ETH2BTC {
    function echidna_fuzz_setEtherToBitcoinRate() public view returns(bool) {
        return etherToBitcoinRate != 2**256 - 1;
    }
}
