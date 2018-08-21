pragma solidity ^0.4.0;
//fool the compiler into allowing contract with only method signatures
//I used this because btcrelay is already deployed but is in serpent
//to mitigate the fact that you cannot use serpent in solidity
//I used the function signatures without the logic and called them using the existing deployment
//Since it is implemented in serpent and the bytecode is the same
//you can call the functions with the function signatures and do not have to implement the logic
//as it is already done in the deployment
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

contract BtcParser {
    // Convert a variable integer into something useful and return it and
    // the index to after it.
    function parseVarInt(bytes txBytes, uint pos) returns (uint, uint) {
        // the first byte tells us how big the integer is
        var ibit = uint8(txBytes[pos]);
        pos += 1;  // skip ibit

        if (ibit < 0xfd) {
            return (ibit, pos);
        } else if (ibit == 0xfd) {
            return (getBytesLE(txBytes, pos, 16), pos + 2);
        } else if (ibit == 0xfe) {
            return (getBytesLE(txBytes, pos, 32), pos + 4);
        } else if (ibit == 0xff) {
            return (getBytesLE(txBytes, pos, 64), pos + 8);
        }
    }
    // convert little endian bytes to uint
    function getBytesLE(bytes data, uint pos, uint bits) returns (uint) {
        if (bits == 8) {
            return uint8(data[pos]);
        } else if (bits == 16) {
            return uint16(data[pos])
                 + uint16(data[pos + 1]) * 2 ** 8;
        } else if (bits == 32) {
            return uint32(data[pos])
                 + uint32(data[pos + 1]) * 2 ** 8
                 + uint32(data[pos + 2]) * 2 ** 16
                 + uint32(data[pos + 3]) * 2 ** 24;
        } else if (bits == 64) {
            return uint64(data[pos])
                 + uint64(data[pos + 1]) * 2 ** 8
                 + uint64(data[pos + 2]) * 2 ** 16
                 + uint64(data[pos + 3]) * 2 ** 24
                 + uint64(data[pos + 4]) * 2 ** 32
                 + uint64(data[pos + 5]) * 2 ** 40
                 + uint64(data[pos + 6]) * 2 ** 48
                 + uint64(data[pos + 7]) * 2 ** 56;
        }
    }
    // scan the full transaction bytes and return the first two output
    // values (in satoshis) and addresses (in binary)
    function getFirstTwoOutputs(bytes txBytes) public
             returns (uint, bytes25, uint, bytes25)
    {
        uint pos;
        uint[] memory input_script_lens = new uint[](2);
        uint[] memory output_script_lens = new uint[](2);
        uint[] memory script_starts = new uint[](2);
        uint[] memory output_values = new uint[](2);
        bytes25[] memory output_addresses = new bytes25[](2);

        pos = 4;  // skip version

        (input_script_lens, pos) = scanInputs(txBytes, pos, 0);

        (output_values, script_starts, output_script_lens, pos) = scanOutputs(txBytes, pos, 2);

        for (uint i = 0; i < 2; i++) {
            var pkhash = parseOutputScript(txBytes, script_starts[i], output_script_lens[i]);
            output_addresses[i] = pkhash;
        }

        return (output_values[0], output_addresses[0],
                output_values[1], output_addresses[1]);
    }
    // Check whether `btcAddress` is in the transaction outputs *and*
    // whether *at least* `value` has been sent to it.
    function checkValueSent(bytes txBytes, bytes25 btcAddress, uint value)
             returns (bool)
    {
        uint pos = 4;  // skip version
        (, pos) = scanInputs(txBytes, pos, 0);  // find end of inputs

        // scan *all* the outputs and find where they are
        var (output_values, script_starts, output_script_lens,) = scanOutputs(txBytes, pos, 0);

        // look at each output and check whether it at least value to btcAddress
        for (uint i = 0; i < output_values.length; i++) {
            var pkhash = parseOutputScript(txBytes, script_starts[i], output_script_lens[i]);
            if (pkhash == btcAddress && output_values[i] >= value) {
                return true;
            }
        }
    }
    // scan the inputs and find the script lengths.
    // return an array of script lengths and the end position
    // of the inputs.
    // takes a 'stop' argument which sets the maximum number of
    // outputs to scan through. stop=0 => scan all.
    function scanInputs(bytes txBytes, uint pos, uint stop) public
             returns (uint[], uint)
    {
        uint n_inputs;
        uint halt;
        uint script_len;

        (n_inputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_inputs) {
            halt = n_inputs;
        } else {
            halt = stop;
        }

        uint[] memory script_lens = new uint[](halt);

        for (var i = 0; i < halt; i++) {
            pos += 36;  // skip outpoint
            (script_len, pos) = parseVarInt(txBytes, pos);
            script_lens[i] = script_len;
            pos += script_len + 4;  // skip sig_script, seq
        }

        return (script_lens, pos);
    }
    // scan the outputs and find the values and script lengths.
    // return array of values, array of script lengths and the
    // end position of the outputs.
    // takes a 'stop' argument which sets the maximum number of
    // outputs to scan through. stop=0 => scan all.
    function scanOutputs(bytes txBytes, uint pos, uint stop) public
             returns (uint[], uint[], uint[], uint)
    {
        uint n_outputs;
        uint halt;
        uint script_len;

        (n_outputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_outputs) {
            halt = n_outputs;
        } else {
            halt = stop;
        }

        uint[] memory script_starts = new uint[](halt);
        uint[] memory script_lens = new uint[](halt);
        uint[] memory output_values = new uint[](halt);

        for (var i = 0; i < halt; i++) {
            output_values[i] = getBytesLE(txBytes, pos, 64);
            pos += 8;

            (script_len, pos) = parseVarInt(txBytes, pos);
            script_starts[i] = pos;
            script_lens[i] = script_len;
            pos += script_len;
        }

        return (output_values, script_starts, script_lens, pos);
    }
    // Slice 20 contiguous bytes from bytes `data`, starting at `start`
    function slicebytes25(bytes data, uint start) public returns (bytes25) {
        uint160 slice = 0;
        for (uint160 i = 0; i < 20; i++) {
            slice += uint160(data[i + start]) << (8 * (19 - i));
        }
        return bytes25(slice);
    }
    // returns true if the bytes located in txBytes by pos and
    // script_len represent a P2PKH script
    function isP2PKH(bytes txBytes, uint pos, uint script_len) returns (bool) {
        return (script_len == 25)           // 20 byte pubkeyhash + 5 bytes of script
            && (txBytes[pos] == 0x76)       // OP_DUP
            && (txBytes[pos + 1] == 0xa9)   // OP_HASH160
            && (txBytes[pos + 2] == 0x14)   // bytes to push
            && (txBytes[pos + 23] == 0x88)  // OP_EQUALVERIFY
            && (txBytes[pos + 24] == 0xac); // OP_CHECKSIG
    }
    // returns true if the bytes located in txBytes by pos and
    // script_len represent a P2SH script
    function isP2SH(bytes txBytes, uint pos, uint script_len) returns (bool) {
        return (script_len == 23)           // 20 byte scripthash + 3 bytes of script
            && (txBytes[pos + 0] == 0xa9)   // OP_HASH160
            && (txBytes[pos + 1] == 0x14)   // bytes to push
            && (txBytes[pos + 22] == 0x87); // OP_EQUAL
    }
    // Get the pubkeyhash / scripthash from an output script. Assumes
    // pay-to-pubkey-hash (P2PKH) or pay-to-script-hash (P2SH) outputs.
    // Returns the pubkeyhash/ scripthash, or zero if unknown output.
    function parseOutputScript(bytes txBytes, uint pos, uint script_len)
             returns (bytes25)
    {
        if (isP2PKH(txBytes, pos, script_len)) {
            return slicebytes25(txBytes, pos + 3);
        } else if (isP2SH(txBytes, pos, script_len)) {
            return slicebytes25(txBytes, pos + 2);
        } else {
            return;
        }
    }
}

//ropsten: 0x574f21d3201eD7f63bf765aE857A85bc84529064
contract BTC2ETH is BtcParser, btcrelayInterface
{
    address _btcrelayAddress;
    bytes32[] claimedTxs;
    address admin;
    uint16 ether2BitcoinRate;
    bytes25 bitcoinAddress;
    btcrelayInterface btcrelay;
    BtcParser btcParser = new BtcParser();

    constructor(bytes25 btcAddress, address btcrelayAddress) public
    {
        admin = msg.sender;
        bitcoinAddress = btcAddress;
        _btcrelayAddress = btcrelayAddress;
        if(_btcrelayAddress == address(0))
        {
            //default mainnet
            _btcrelayAddress = 0x41f274c0023f83391DE4e0733C609DF5a124c3d4;
        }
        btcrelay = btcrelayInterface(_btcrelayAddress);
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
        uint256 transactionIndex,
        bytes32[] merkleSibling,
        uint256 blockHash
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
        bytes25 senderPubKey = getSenderPub(rawTransaction, blockHash);
        address sender = address(keccak256(abi.encodePacked(senderPubKey)));
        var (amt1, address1, amt2, address2) = btcParser.getFirstTwoOutputs(rawTransaction);
        uint amountToTransfer = amt1 * ether2BitcoinRate;
        makeTransfers(amountToTransfer, sender, rawTransaction, blockHash);
    }

    //need to split up functions else the stack will run out
    function makeTransfers(
        uint amountToTransfer,
        address sender,
        bytes rawTransaction,
        uint256 blockHash) internal
    {
        require(msg.sender == address(this));
        //3% fee in total
        uint feeToRelayer = amountToTransfer / 100;
        uint feeToAdmin = amountToTransfer / 50;
        uint deduction = feeToRelayer + feeToAdmin;
        sender.transfer(amountToTransfer - deduction);
        claimedTxs.push(keccak256(rawTransaction));
        address relayerOfBlock = btcrelay.getFeeRecipient(blockHash);
        //added incentive for block relayers
        relayerOfBlock.transfer(feeToRelayer);
        //admin gets 2% fee for providing service and liquidity
        admin.transfer(feeToAdmin);
    }

    function checkClaims(bytes32[] claimTxs, bytes32 hashedRawTx) internal
    {
        for(uint i = 0; i < claimedTxs.length; i++)
        {
            require(claimedTxs[i] != hashedRawTx);
        }
    }

    function getSenderPub(bytes rawTransaction, uint256 blockHash) returns(bytes25)
    {
        var (amt1, address1, amt2, address2) = btcParser.getFirstTwoOutputs(rawTransaction);
        require(address1 == bitcoinAddress || address2 == bitcoinAddress);
        bytes25 senderPubKey = btcParser.parseOutputScript(
            rawTransaction,
            0,
            rawTransaction.length
        );
        return senderPubKey;
    }

}
