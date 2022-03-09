pragma solidity ^0.5.10;

/** @title ViewSPV */
/** @author Summa (https://summa.one) */

import {TypedMemView} from "./TypedMemView.sol";
import {ViewBTC} from "./ViewBTC.sol";
import {SafeMath} from "./SafeMath.sol";

library ViewSPV {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using ViewBTC for bytes29;
    using SafeMath for uint256;

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

    /// @notice             requires `memView` to be of a specified type
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
    /// @return             passes if it is the correct type, errors if not
    modifier typeAssert(bytes29 memView, ViewBTC.BTCTypes t) {
        memView.assertType(uint40(t));
        _;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root (as in the block header)
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove(
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes29 _intermediateNodes,
        uint256 _index
    )
        internal
        view
        typeAssert(_intermediateNodes, ViewBTC.BTCTypes.MerkleArray)
        returns (bool)
    {
        // Shortcut the empty-block case
        if (
            _txid == _merkleRoot && _index == 0 && _intermediateNodes.len() == 0
        ) {
            return true;
        }

        return
            ViewBTC.checkMerkle(_txid, _intermediateNodes, _merkleRoot, _index);
    }

    /// @notice             Hashes transaction to get txid
    /// @dev                Supports Legacy and Witness
    /// @param _version     4-bytes version
    /// @param _vin         Raw bytes length-prefixed input vector
    /// @param _vout        Raw bytes length-prefixed output vector
    /// @param _locktime    4-byte tx locktime
    /// @return             32-byte transaction id, little endian
    function calculateTxId(
        bytes4 _version,
        bytes29 _vin,
        bytes29 _vout,
        bytes4 _locktime
    )
        internal
        view
        typeAssert(_vin, ViewBTC.BTCTypes.Vin)
        typeAssert(_vout, ViewBTC.BTCTypes.Vout)
        returns (bytes32)
    {
        // TODO: write in assembly
        return
            abi
                .encodePacked(_version, _vin.clone(), _vout.clone(), _locktime)
                .ref(0)
                .hash256();
    }

    // TODO: add test for checkWork
    /// @notice             Checks validity of header work
    /// @param _header      Header view
    /// @param _target      The target threshold
    /// @return             true if header work is valid, false otherwise
    function checkWork(bytes29 _header, uint256 _target)
        internal
        view
        typeAssert(_header, ViewBTC.BTCTypes.Header)
        returns (bool)
    {
        return _header.work() < _target;
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header parent to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function checkParent(bytes29 _header, bytes32 _prevHeaderDigest)
        internal
        pure
        typeAssert(_header, ViewBTC.BTCTypes.Header)
        returns (bool)
    {
        return _header.parent() == _prevHeaderDigest;
    }

    /// @notice             Checks validity of header chain
    /// @notice             Compares the hash of each header to the prevHash in the next header
    /// @param _headers     Raw byte array of header chain
    /// @return             The total accumulated difficulty of the header chain, or an error code
    function checkChain(bytes29 _headers)
        internal
        view
        typeAssert(_headers, ViewBTC.BTCTypes.HeaderArray)
        returns (uint256 _totalDifficulty)
    {
        bytes32 _digest;
        uint256 _headerCount = _headers.len() / 80;
        for (uint256 i = 0; i < _headerCount; i += 1) {
            bytes29 _header = _headers.indexHeaderArray(i);
            if (i != 0) {
                if (!checkParent(_header, _digest)) {
                    return ERR_INVALID_CHAIN;
                }
            }
            _digest = _header.workHash();
            uint256 _work = TypedMemView.reverseUint256(uint256(_digest));
            uint256 _target = _header.target();

            if (_work > _target) {
                return ERR_LOW_WORK;
            }

            _totalDifficulty += ViewBTC.toDiff(_target);
        }
    }
}
