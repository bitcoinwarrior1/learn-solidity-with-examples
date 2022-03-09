pragma solidity ^0.5.10;

/** @title ValidateSPV*/
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";
import {BTCUtils} from "./BTCUtils.sol";

library ValidateSPV {
    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using BytesLib for bytes;
    using SafeMath for uint256;

    enum InputTypes {
        NONE,
        LEGACY,
        COMPATIBILITY,
        WITNESS
    }
    enum OutputTypes {
        NONE,
        WPKH,
        WSH,
        OP_RETURN,
        PKH,
        SH,
        NONSTANDARD
    }

    uint256 constant ERR_BAD_LENGTH =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant ERR_INVALID_CHAIN =
        0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 constant ERR_LOW_WORK =
        0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd;

    function getErrBadLength() internal pure returns (uint256) {
        return ERR_BAD_LENGTH;
    }

    function getErrInvalidChain() internal pure returns (uint256) {
        return ERR_INVALID_CHAIN;
    }

    function getErrLowWork() internal pure returns (uint256) {
        return ERR_LOW_WORK;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root (as in the block header)
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove(
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes memory _intermediateNodes,
        uint256 _index
    ) internal pure returns (bool) {
        // Shortcut the empty-block case
        if (
            _txid == _merkleRoot &&
            _index == 0 &&
            _intermediateNodes.length == 0
        ) {
            return true;
        }

        bytes memory _proof = abi.encodePacked(
            _txid,
            _intermediateNodes,
            _merkleRoot
        );
        // If the Merkle proof failed, bubble up error
        return _proof.verifyHash256Merkle(_index);
    }

    /// @notice             Hashes transaction to get txid
    /// @dev                Supports Legacy and Witness
    /// @param _version     4-bytes version
    /// @param _vin         Raw bytes length-prefixed input vector
    /// @param _vout        Raw bytes length-prefixed output vector
    /// @ param _locktime   4-byte tx locktime
    /// @return             32-byte transaction id, little endian
    function calculateTxId(
        bytes memory _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes memory _locktime
    ) internal pure returns (bytes32) {
        // Get transaction hash double-Sha256(version + nIns + inputs + nOuts + outputs + locktime)
        return abi.encodePacked(_version, _vin, _vout, _locktime).hash256();
    }

    /// @notice         Parses a tx input from raw input bytes
    /// @dev            Supports Legacy and Witness inputs
    /// @param _input   Raw bytes tx input
    /// @return         Tx input sequence number, tx hash, and index
    function parseInput(bytes memory _input)
        internal
        pure
        returns (
            uint32 _sequence,
            bytes32 _hash,
            uint32 _index,
            uint8 _inputType
        )
    {
        // NB: If the scriptsig is exactly 00, we are witness.
        //     Otherwise we are compatibility
        if (_input.keccak256Slice(36, 1) != keccak256(hex"00")) {
            _sequence = _input.extractSequenceLegacy();
            bytes32 _witnessTag = _input.keccak256Slice(36, 3);

            if (
                _witnessTag == keccak256(hex"220020") ||
                _witnessTag == keccak256(hex"160014")
            ) {
                _inputType = uint8(InputTypes.COMPATIBILITY);
            } else {
                _inputType = uint8(InputTypes.LEGACY);
            }
        } else {
            _sequence = _input.extractSequenceWitness();
            _inputType = uint8(InputTypes.WITNESS);
        }

        return (
            _sequence,
            _input.extractInputTxId(),
            _input.extractTxIndex(),
            _inputType
        );
    }

    /// @notice         Parses a tx output from raw output bytes
    /// @dev            Differentiates by output script prefix, handles legacy and witness
    /// @param _output  Raw bytes tx output
    /// @return         Tx output value, output type, payload
    function parseOutput(bytes memory _output)
        internal
        pure
        returns (
            uint64 _value,
            uint8 _outputType,
            bytes memory _payload
        )
    {
        _value = _output.extractValue();

        if (_output.keccak256Slice(9, 1) == keccak256(hex"6a")) {
            // OP_RETURN
            _outputType = uint8(OutputTypes.OP_RETURN);
            _payload = _output.extractOpReturnData();
        } else {
            bytes32 _prefixHash = _output.keccak256Slice(8, 2);
            if (_prefixHash == keccak256(hex"2200")) {
                // P2WSH
                _outputType = uint8(OutputTypes.WSH);
                _payload = _output.slice(11, 32);
            } else if (_prefixHash == keccak256(hex"1600")) {
                // P2WPKH
                _outputType = uint8(OutputTypes.WPKH);
                _payload = _output.slice(11, 20);
            } else if (_prefixHash == keccak256(hex"1976")) {
                // PKH
                _outputType = uint8(OutputTypes.PKH);
                _payload = _output.slice(12, 20);
            } else if (_prefixHash == keccak256(hex"17a9")) {
                // SH
                _outputType = uint8(OutputTypes.SH);
                _payload = _output.slice(11, 20);
            } else {
                _outputType = uint8(OutputTypes.NONSTANDARD);
            }
        }

        return (_value, _outputType, _payload);
    }

    /// @notice             Parses a block header struct from a bytestring
    /// @dev                Block headers are always 80 bytes, see Bitcoin docs
    /// @return             Header digest, version, previous block header hash, merkle root, timestamp, target, nonce
    function parseHeader(bytes memory _header)
        internal
        pure
        returns (
            bytes32 _digest,
            uint32 _version,
            bytes32 _prevHash,
            bytes32 _merkleRoot,
            uint32 _timestamp,
            uint256 _target,
            uint32 _nonce
        )
    {
        // If header has an invalid length, bubble up error
        if (_header.length != 80) {
            return (
                _digest,
                _version,
                _prevHash,
                _merkleRoot,
                _timestamp,
                _target,
                _nonce
            );
        }

        _digest = abi
            .encodePacked(_header.hash256())
            .reverseEndianness()
            .toBytes32();
        _version = uint32(
            _header.slice(0, 4).reverseEndianness().bytesToUint()
        );
        _prevHash = _header.extractPrevBlockLE().toBytes32();
        _merkleRoot = _header.extractMerkleRootLE().toBytes32();
        _timestamp = _header.extractTimestamp();
        _target = _header.extractTarget();
        _nonce = uint32(_header.slice(76, 4).reverseEndianness().bytesToUint());

        return (
            _digest,
            _version,
            _prevHash,
            _merkleRoot,
            _timestamp,
            _target,
            _nonce
        );
    }

    /// @notice             Checks validity of header chain
    /// @notice             Compares the hash of each header to the prevHash in the next header
    /// @param _headers     Raw byte array of header chain
    /// @return             The total accumulated difficulty of the header chain, or an error code
    function validateHeaderChain(bytes memory _headers)
        internal
        view
        returns (uint256 _totalDifficulty)
    {
        // Check header chain length
        if (_headers.length % 80 != 0) {
            return ERR_BAD_LENGTH;
        }

        // Initialize header start index
        bytes32 _digest;

        _totalDifficulty = 0;

        for (uint256 _start = 0; _start < _headers.length; _start += 80) {
            // ith header start index and ith header
            bytes memory _header = _headers.slice(_start, 80);

            // After the first header, check that headers are in a chain
            if (_start != 0) {
                if (!validateHeaderPrevHash(_header, _digest)) {
                    return ERR_INVALID_CHAIN;
                }
            }

            // ith header target
            uint256 _target = _header.extractTarget();

            // Require that the header has sufficient work
            _digest = _header.hash256View();
            if (uint256(_digest).reverseUint256() > _target) {
                return ERR_LOW_WORK;
            }

            // Add ith header difficulty to difficulty sum
            _totalDifficulty = _totalDifficulty.add(
                _target.calculateDifficulty()
            );
        }
    }

    /// @notice             Checks validity of header work
    /// @param _digest      Header digest
    /// @param _target      The target threshold
    /// @return             true if header work is valid, false otherwise
    function validateHeaderWork(bytes32 _digest, uint256 _target)
        internal
        pure
        returns (bool)
    {
        if (_digest == bytes32(0)) {
            return false;
        }
        return (abi.encodePacked(_digest).reverseEndianness().bytesToUint() <
            _target);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header prevHash to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if header chain is valid, false otherwise
    function validateHeaderPrevHash(
        bytes memory _header,
        bytes32 _prevHeaderDigest
    ) internal pure returns (bool) {
        // Extract prevHash of current header
        bytes32 _prevHash = _header.extractPrevBlockLE().toBytes32();

        // Compare prevHash of current header to previous header's digest
        if (_prevHash != _prevHeaderDigest) {
            return false;
        }

        return true;
    }
}
