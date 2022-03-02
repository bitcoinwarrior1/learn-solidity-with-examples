pragma solidity ^0.5.10;

/** @title BitcoinSPV */
/** @author Summa (https://summa.one) */

import {TypedMemView} from "./TypedMemView.sol";
import {SafeMath} from "./SafeMath.sol";

library ViewBTC {
    using TypedMemView for bytes29;
    using SafeMath for uint256;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 public constant DIFF1_TARGET =
        0xffff0000000000000000000000000000000000000000000000000000;

    uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60; // 2 weeks in seconds
    uint256 public constant RETARGET_PERIOD_BLOCKS = 2016; // 2 weeks in blocks

    enum BTCTypes {
        Unknown, // 0x0
        CompactInt, // 0x1
        ScriptSig, // 0x2 - with length prefix
        Outpoint, // 0x3
        TxIn, // 0x4
        IntermediateTxIns, // 0x5 - used in vin parsing
        Vin, // 0x6
        ScriptPubkey, // 0x7 - with length prefix
        PKH, // 0x8 - the 20-byte payload digest
        WPKH, // 0x9 - the 20-byte payload digest
        WSH, // 0xa - the 32-byte payload digest
        SH, // 0xb - the 20-byte payload digest
        OpReturnPayload, // 0xc
        TxOut, // 0xd
        IntermediateTxOuts, // 0xe - used in vout parsing
        Vout, // 0xf
        Header, // 0x10
        HeaderArray, // 0x11
        MerkleNode, // 0x12
        MerkleStep, // 0x13
        MerkleArray // 0x14
    }

    // TODO: any way to bubble up more info?
    /// @notice             requires `memView` to be of a specified type
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
    /// @return             passes if it is the correct type, errors if not
    modifier typeAssert(bytes29 memView, BTCTypes t) {
        memView.assertType(uint40(t));
        _;
    }

    /// Revert with an error message re: non-minimal VarInts
    function revertNonMinimal(bytes29 ref)
        private
        pure
        returns (string memory)
    {
        (, uint256 g) = TypedMemView.encodeHex(
            ref.indexUint(0, uint8(ref.len()))
        );
        string memory err = string(
            abi.encodePacked("Non-minimal var int. Got 0x", uint144(g))
        );
        revert(err);
    }

    /// @notice             reads a compact int from the view at the specified index
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param _index       the index
    /// @return             the compact int at the specified index
    function indexCompactInt(bytes29 memView, uint256 _index)
        internal
        pure
        returns (uint64 number)
    {
        uint256 flag = memView.indexUint(_index, 1);
        if (flag <= 0xfc) {
            return uint64(flag);
        } else if (flag == 0xfd) {
            number = uint64(memView.indexLEUint(_index + 1, 2));
            if (compactIntLength(number) != 3) {
                revertNonMinimal(memView.slice(_index, 3, 0));
            }
        } else if (flag == 0xfe) {
            number = uint64(memView.indexLEUint(_index + 1, 4));
            if (compactIntLength(number) != 5) {
                revertNonMinimal(memView.slice(_index, 5, 0));
            }
        } else if (flag == 0xff) {
            number = uint64(memView.indexLEUint(_index + 1, 8));
            if (compactIntLength(number) != 9) {
                revertNonMinimal(memView.slice(_index, 9, 0));
            }
        }
    }

    /// @notice         gives the total length (in bytes) of a CompactInt-encoded number
    /// @param number   the number as uint64
    /// @return         the compact integer as uint8
    function compactIntLength(uint64 number) internal pure returns (uint8) {
        if (number <= 0xfc) {
            return 1;
        } else if (number <= 0xffff) {
            return 3;
        } else if (number <= 0xffffffff) {
            return 5;
        } else {
            return 9;
        }
    }

    /// @notice             extracts the LE txid from an outpoint
    /// @param _outpoint    the outpoint
    /// @return             the LE txid
    function txidLE(bytes29 _outpoint)
        internal
        pure
        typeAssert(_outpoint, BTCTypes.Outpoint)
        returns (bytes32)
    {
        return _outpoint.index(0, 32);
    }

    /// @notice             extracts the index as an integer from the outpoint
    /// @param _outpoint    the outpoint
    /// @return             the index
    function outpointIdx(bytes29 _outpoint)
        internal
        pure
        typeAssert(_outpoint, BTCTypes.Outpoint)
        returns (uint32)
    {
        return uint32(_outpoint.indexLEUint(32, 4));
    }

    /// @notice          extracts the outpoint from an input
    /// @param _input    the input
    /// @return          the outpoint as a typed memory
    function outpoint(bytes29 _input)
        internal
        pure
        typeAssert(_input, BTCTypes.TxIn)
        returns (bytes29)
    {
        return _input.slice(0, 36, uint40(BTCTypes.Outpoint));
    }

    /// @notice           extracts the script sig from an input
    /// @param _input     the input
    /// @return           the script sig as a typed memory
    function scriptSig(bytes29 _input)
        internal
        pure
        typeAssert(_input, BTCTypes.TxIn)
        returns (bytes29)
    {
        uint64 scriptLength = indexCompactInt(_input, 36);
        return
            _input.slice(
                36,
                compactIntLength(scriptLength) + scriptLength,
                uint40(BTCTypes.ScriptSig)
            );
    }

    /// @notice         extracts the sequence from an input
    /// @param _input   the input
    /// @return         the sequence
    function sequence(bytes29 _input)
        internal
        pure
        typeAssert(_input, BTCTypes.TxIn)
        returns (uint32)
    {
        uint64 scriptLength = indexCompactInt(_input, 36);
        uint256 scriptEnd = 36 + compactIntLength(scriptLength) + scriptLength;
        return uint32(_input.indexLEUint(scriptEnd, 4));
    }

    /// @notice         determines the length of the first input in an array of inputs
    /// @param _inputs  the vin without its length prefix
    /// @return         the input length
    function inputLength(bytes29 _inputs)
        internal
        pure
        typeAssert(_inputs, BTCTypes.IntermediateTxIns)
        returns (uint256)
    {
        uint64 scriptLength = indexCompactInt(_inputs, 36);
        return
            uint256(compactIntLength(scriptLength)) +
            uint256(scriptLength) +
            36 +
            4;
    }

    /// @notice         extracts the input at a specified index
    /// @param _vin     the vin
    /// @param _index   the index of the desired input
    /// @return         the desired input
    function indexVin(bytes29 _vin, uint256 _index)
        internal
        pure
        typeAssert(_vin, BTCTypes.Vin)
        returns (bytes29)
    {
        uint256 _nIns = uint256(indexCompactInt(_vin, 0));
        uint256 _viewLen = _vin.len();
        require(_index < _nIns, "Vin read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nIns)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vin.postfix(
                _viewLen.sub(_offset),
                uint40(BTCTypes.IntermediateTxIns)
            );
            _offset += inputLength(_remaining);
        }

        _remaining = _vin.postfix(
            _viewLen.sub(_offset),
            uint40(BTCTypes.IntermediateTxIns)
        );
        uint256 _len = inputLength(_remaining);
        return _vin.slice(_offset, _len, uint40(BTCTypes.TxIn));
    }

    /// @notice         extracts the raw LE bytes of the output value
    /// @param _output  the output
    /// @return         the raw LE bytes of the output value
    function valueBytes(bytes29 _output)
        internal
        pure
        typeAssert(_output, BTCTypes.TxOut)
        returns (bytes8)
    {
        return bytes8(_output.index(0, 8));
    }

    /// @notice         extracts the value from an output
    /// @param _output  the output
    /// @return         the value
    function value(bytes29 _output)
        internal
        pure
        typeAssert(_output, BTCTypes.TxOut)
        returns (uint64)
    {
        return uint64(_output.indexLEUint(0, 8));
    }

    /// @notice             extracts the scriptPubkey from an output
    /// @param _output      the output
    /// @return             the scriptPubkey
    function scriptPubkey(bytes29 _output)
        internal
        pure
        typeAssert(_output, BTCTypes.TxOut)
        returns (bytes29)
    {
        uint64 scriptLength = indexCompactInt(_output, 8);
        return
            _output.slice(
                8,
                compactIntLength(scriptLength) + scriptLength,
                uint40(BTCTypes.ScriptPubkey)
            );
    }

    /// @notice             determines the length of the first output in an array of outputs
    /// @param _outputs     the vout without its length prefix
    /// @return             the output length
    function outputLength(bytes29 _outputs)
        internal
        pure
        typeAssert(_outputs, BTCTypes.IntermediateTxOuts)
        returns (uint256)
    {
        uint64 scriptLength = indexCompactInt(_outputs, 8);
        return
            uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 8;
    }

    /// @notice         extracts the output at a specified index
    /// @param _vout    the vout
    /// @param _index   the index of the desired output
    /// @return         the desired output
    function indexVout(bytes29 _vout, uint256 _index)
        internal
        pure
        typeAssert(_vout, BTCTypes.Vout)
        returns (bytes29)
    {
        uint256 _nOuts = uint256(indexCompactInt(_vout, 0));
        uint256 _viewLen = _vout.len();
        require(_index < _nOuts, "Vout read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nOuts)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vout.postfix(
                _viewLen - _offset,
                uint40(BTCTypes.IntermediateTxOuts)
            );
            _offset += outputLength(_remaining);
        }

        _remaining = _vout.postfix(
            _viewLen - _offset,
            uint40(BTCTypes.IntermediateTxOuts)
        );
        uint256 _len = outputLength(_remaining);
        return _vout.slice(_offset, _len, uint40(BTCTypes.TxOut));
    }

    /// @notice         extracts the Op Return Payload
    /// @param _spk     the scriptPubkey
    /// @return         the Op Return Payload (or null if not a valid Op Return output)
    function opReturnPayload(bytes29 _spk)
        internal
        pure
        typeAssert(_spk, BTCTypes.ScriptPubkey)
        returns (bytes29)
    {
        uint64 _bodyLength = indexCompactInt(_spk, 0);
        uint64 _payloadLen = uint64(_spk.indexUint(2, 1));
        if (
            _bodyLength > 77 ||
            _bodyLength < 4 ||
            _spk.indexUint(1, 1) != 0x6a ||
            _spk.indexUint(2, 1) != _bodyLength - 2
        ) {
            return TypedMemView.nullView();
        }
        return _spk.slice(3, _payloadLen, uint40(BTCTypes.OpReturnPayload));
    }

    /// @notice         extracts the payload from a scriptPubkey
    /// @param _spk     the scriptPubkey
    /// @return         the payload (or null if not a valid PKH, SH, WPKH, or WSH output)
    function payload(bytes29 _spk)
        internal
        pure
        typeAssert(_spk, BTCTypes.ScriptPubkey)
        returns (bytes29)
    {
        uint256 _spkLength = _spk.len();
        uint256 _bodyLength = indexCompactInt(_spk, 0);
        if (
            _bodyLength > 0x22 ||
            _bodyLength < 0x16 ||
            _bodyLength + 1 != _spkLength
        ) {
            return TypedMemView.nullView();
        }

        // Legacy
        if (
            _bodyLength == 0x19 &&
            _spk.indexUint(0, 4) == 0x1976a914 &&
            _spk.indexUint(_spkLength - 2, 2) == 0x88ac
        ) {
            return _spk.slice(4, 20, uint40(BTCTypes.PKH));
        } else if (
            _bodyLength == 0x17 &&
            _spk.indexUint(0, 3) == 0x17a914 &&
            _spk.indexUint(_spkLength - 1, 1) == 0x87
        ) {
            return _spk.slice(3, 20, uint40(BTCTypes.SH));
        }

        // Witness v0
        if (_spk.indexUint(1, 1) == 0) {
            uint256 _payloadLen = _spk.indexUint(2, 1);
            if (
                (_bodyLength != 0x22 && _bodyLength != 0x16) ||
                _payloadLen != _bodyLength - 2
            ) {
                return TypedMemView.nullView();
            }
            uint40 newType = uint40(
                _payloadLen == 0x20 ? BTCTypes.WSH : BTCTypes.WPKH
            );
            return _spk.slice(3, _payloadLen, newType);
        }

        return TypedMemView.nullView();
    }

    /// @notice     (loosely) verifies an spk and converts to a typed memory
    /// @dev        will return null in error cases. Will not check for disabled opcodes.
    /// @param _spk the spk
    /// @return     the typed spk (or null if error)
    function tryAsSPK(bytes29 _spk)
        internal
        pure
        typeAssert(_spk, BTCTypes.Unknown)
        returns (bytes29)
    {
        if (_spk.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _len = indexCompactInt(_spk, 0);
        if (_spk.len() == compactIntLength(_len) + _len) {
            return _spk.castTo(uint40(BTCTypes.ScriptPubkey));
        } else {
            return TypedMemView.nullView();
        }
    }

    /// @notice     verifies the vin and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _vin the vin
    /// @return     the typed vin (or null if error)
    function tryAsVin(bytes29 _vin)
        internal
        pure
        typeAssert(_vin, BTCTypes.Unknown)
        returns (bytes29)
    {
        if (_vin.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nIns = indexCompactInt(_vin, 0);
        uint256 _viewLen = _vin.len();
        if (_nIns == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nIns));
        for (uint256 i = 0; i < _nIns; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vin.postfix(
                _viewLen - _offset,
                uint40(BTCTypes.IntermediateTxIns)
            );
            _offset += inputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vin.castTo(uint40(BTCTypes.Vin));
    }

    /// @notice         verifies the vout and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _vout    the vout
    /// @return         the typed vout (or null if error)
    function tryAsVout(bytes29 _vout)
        internal
        pure
        typeAssert(_vout, BTCTypes.Unknown)
        returns (bytes29)
    {
        if (_vout.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nOuts = indexCompactInt(_vout, 0);
        uint256 _viewLen = _vout.len();
        if (_nOuts == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nOuts));
        for (uint256 i = 0; i < _nOuts; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vout.postfix(
                _viewLen - _offset,
                uint40(BTCTypes.IntermediateTxOuts)
            );
            _offset += outputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vout.castTo(uint40(BTCTypes.Vout));
    }

    /// @notice         verifies the header and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _header  the header
    /// @return         the typed header (or null if error)
    function tryAsHeader(bytes29 _header)
        internal
        pure
        typeAssert(_header, BTCTypes.Unknown)
        returns (bytes29)
    {
        if (_header.len() != 80) {
            return TypedMemView.nullView();
        }
        return _header.castTo(uint40(BTCTypes.Header));
    }

    /// @notice         Index a header array.
    /// @dev            Errors on overruns
    /// @param _arr     The header array
    /// @param index    The 0-indexed location of the header to get
    /// @return         the typed header at `index`
    function indexHeaderArray(bytes29 _arr, uint256 index)
        internal
        pure
        typeAssert(_arr, BTCTypes.HeaderArray)
        returns (bytes29)
    {
        uint256 _start = index.mul(80);
        return _arr.slice(_start, 80, uint40(BTCTypes.Header));
    }

    /// @notice     verifies the header array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the header array
    /// @return     the typed header array (or null if error)
    function tryAsHeaderArray(bytes29 _arr)
        internal
        pure
        typeAssert(_arr, BTCTypes.Unknown)
        returns (bytes29)
    {
        if (_arr.len() % 80 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.HeaderArray));
    }

    /// @notice     verifies the merkle array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the merkle array
    /// @return     the typed merkle array (or null if error)
    function tryAsMerkleArray(bytes29 _arr)
        internal
        pure
        typeAssert(_arr, BTCTypes.Unknown)
        returns (bytes29)
    {
        if (_arr.len() % 32 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.MerkleArray));
    }

    /// @notice         extracts the merkle root from the header
    /// @param _header  the header
    /// @return         the merkle root
    function merkleRoot(bytes29 _header)
        internal
        pure
        typeAssert(_header, BTCTypes.Header)
        returns (bytes32)
    {
        return _header.index(36, 32);
    }

    /// @notice         extracts the target from the header
    /// @param _header  the header
    /// @return         the target
    function target(bytes29 _header)
        internal
        pure
        typeAssert(_header, BTCTypes.Header)
        returns (uint256)
    {
        uint256 _mantissa = _header.indexLEUint(72, 3);
        uint256 _exponent = _header.indexUint(75, 1).sub(3);
        return _mantissa.mul(256**_exponent);
    }

    /// @notice         calculates the difficulty from a target
    /// @param _target  the target
    /// @return         the difficulty
    function toDiff(uint256 _target) internal pure returns (uint256) {
        return DIFF1_TARGET.div(_target);
    }

    /// @notice         extracts the difficulty from the header
    /// @param _header  the header
    /// @return         the difficulty
    function diff(bytes29 _header)
        internal
        pure
        typeAssert(_header, BTCTypes.Header)
        returns (uint256)
    {
        return toDiff(target(_header));
    }

    /// @notice         extracts the timestamp from the header
    /// @param _header  the header
    /// @return         the timestamp
    function time(bytes29 _header)
        internal
        pure
        typeAssert(_header, BTCTypes.Header)
        returns (uint32)
    {
        return uint32(_header.indexLEUint(68, 4));
    }

    /// @notice         extracts the parent hash from the header
    /// @param _header  the header
    /// @return         the parent hash
    function parent(bytes29 _header)
        internal
        pure
        typeAssert(_header, BTCTypes.Header)
        returns (bytes32)
    {
        return _header.index(4, 32);
    }

    /// @notice         calculates the Proof of Work hash of the header
    /// @param _header  the header
    /// @return         the Proof of Work hash
    function workHash(bytes29 _header)
        internal
        view
        typeAssert(_header, BTCTypes.Header)
        returns (bytes32)
    {
        return _header.hash256();
    }

    /// @notice         calculates the Proof of Work hash of the header, and converts to an integer
    /// @param _header  the header
    /// @return         the Proof of Work hash as an integer
    function work(bytes29 _header)
        internal
        view
        typeAssert(_header, BTCTypes.Header)
        returns (uint256)
    {
        return TypedMemView.reverseUint256(uint256(workHash(_header)));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @dev             Not recommended to call directly.
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _merkleStep(bytes32 _a, bytes32 _b)
        internal
        view
        returns (bytes32 digest)
    {
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            mstore(ptr, _a)
            mstore(add(ptr, 0x20), _b)
            pop(staticcall(gas, 2, ptr, 0x40, ptr, 0x20)) // sha2 #1
            pop(staticcall(gas, 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
            digest := mload(ptr)
        }
    }

    /// @notice         verifies a merkle proof
    /// @param _leaf    the leaf
    /// @param _proof   the merkle proof
    /// @param _root    the merkle root
    /// @param _index   the index
    /// @return         true if valid, false if otherwise
    function checkMerkle(
        bytes32 _leaf,
        bytes29 _proof,
        bytes32 _root,
        uint256 _index
    ) internal view typeAssert(_proof, BTCTypes.MerkleArray) returns (bool) {
        uint256 nodes = _proof.len() / 32;
        if (nodes == 0) {
            return _leaf == _root;
        }

        uint256 _idx = _index;
        bytes32 _current = _leaf;

        for (uint256 i = 0; i < nodes; i++) {
            bytes32 _next = _proof.index(i * 32, 32);
            if (_idx % 2 == 1) {
                _current = _merkleStep(_next, _current);
            } else {
                _current = _merkleStep(_current, _next);
            }
            _idx >>= 1;
        }

        return _current == _root;
    }

    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD.div(4)) {
            _elapsedTime = RETARGET_PERIOD.div(4);
        }
        if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
            _elapsedTime = RETARGET_PERIOD.mul(4);
        }

        /*
            NB: high targets e.g. ffff0020 can cause overflows here
                so we divide it by 256**2, then multiply by 256**2 later
                we know the target is evenly divisible by 256**2, so this isn't an issue
        */
        uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
        return _adjusted.div(RETARGET_PERIOD).mul(65536);
    }
}
