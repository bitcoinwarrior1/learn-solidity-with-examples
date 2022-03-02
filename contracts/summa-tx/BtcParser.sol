// Bitcoin transaction parsing library

// Copyright 2016 rain <https://keybase.io/rain>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// https://en.bitcoin.it/wiki/Protocol_documentation#tx
//
// Raw Bitcoin transaction structure:
//
// field     | size | type     | description
// version   | 4    | int32    | transaction version number
// n_tx_in   | 1-9  | var_int  | number of transaction inputs
// tx_in     | 41+  | tx_in[]  | list of transaction inputs
// n_tx_out  | 1-9  | var_int  | number of transaction outputs
// tx_out    | 9+   | tx_out[] | list of transaction outputs
// lock_time | 4    | uint32   | block number / timestamp at which tx locked
//
// Transaction input (tx_in) structure:
//
// field      | size | type     | description
// previous   | 36   | outpoint | Previous output transaction reference
// script_len | 1-9  | var_int  | Length of the signature script
// sig_script | ?    | uchar[]  | Script for confirming transaction authorization
// sequence   | 4    | uint32   | Sender transaction version
//
// OutPoint structure:
//
// field      | size | type     | description
// hash       | 32   | char[32] | The hash of the referenced transaction
// index      | 4    | uint32   | The index of this output in the referenced transaction
//
// Transaction output (tx_out) structure:
//
// field         | size | type     | description
// value         | 8    | int64    | Transaction value (Satoshis)
// pk_script_len | 1-9  | var_int  | Length of the public key script
// pk_script     | ?    | uchar[]  | Public key as a Bitcoin script.
//
// Variable integers (var_int) can be encoded differently depending
// on the represented value, to save space. Variable integers always
// precede an array of a variable length data type (e.g. tx_in).
//
// Variable integer encodings as a function of represented value:
//
// value           | bytes  | format
// <0xFD (253)     | 1      | uint8
// <=0xFFFF (65535)| 3      | 0xFD followed by length as uint16
// <=0xFFFF FFFF   | 5      | 0xFE followed by length as uint32
// -               | 9      | 0xFF followed by length as uint64
//
// Public key scripts `pk_script` are set on the output and can
// take a number of forms. The regular transaction script is
// called 'pay-to-pubkey-hash' (P2PKH):
//
// OP_DUP OP_HASH160 <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
//
// OP_x are Bitcoin script opcodes. The bytes representation (including
// the 0x14 20-byte stack push) is:
//
// 0x76 0xA9 0x14 <pubKeyHash> 0x88 0xAC
//
// The <pubKeyHash> is the ripemd160 hash of the sha256 hash of
// the public key, preceded by a network version byte. (21 bytes total)
//
// Network version bytes: 0x00 (mainnet); 0x6f (testnet); 0x34 (namecoin)
//
// The Bitcoin address is derived from the pubKeyHash. The binary form is the
// pubKeyHash, plus a checksum at the end.  The checksum is the first 4 bytes
// of the (32 byte) double sha256 of the pubKeyHash. (25 bytes total)
// This is converted to base58 to form the publicly used Bitcoin address.
// Mainnet P2PKH transaction scripts are to addresses beginning with '1'.
//
// P2SH ('pay to script hash') scripts only supply a script hash. The spender
// must then provide the script that would allow them to redeem this output.
// This allows for arbitrarily complex scripts to be funded using only a
// hash of the script, and moves the onus on providing the script from
// the spender to the redeemer.
//
// The P2SH script format is simple:
//
// OP_HASH160 <scriptHash> OP_EQUAL
//
// 0xA9 0x14 <scriptHash> 0x87
//
// The <scriptHash> is the ripemd160 hash of the sha256 hash of the
// redeem script. The P2SH address is derived from the scriptHash.
// Addresses are the scriptHash with a version prefix of 5, encoded as
// Base58check. These addresses begin with a '3'.
pragma solidity ^0.5.10;

// parse a raw bitcoin transaction byte array
library BtcParser {
    // Convert a variable integer into something useful and return it and
    // the index to after it.
    function parseVarInt(bytes memory txBytes, uint256 pos)
        public
        returns (uint256, uint256)
    {
        // the first byte tells us how big the integer is
        uint8 ibit = uint8(txBytes[pos]);
        pos += 1; // skip ibit

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
    function getBytesLE(
        bytes memory data,
        uint256 pos,
        uint256 bits
    ) public returns (uint256) {
        if (bits == 8) {
            return uint8(data[pos]);
        } else if (bits == 16) {
            return
                uint16(uint8(data[pos])) + uint16(uint8(data[pos + 1])) * 2**8;
        } else if (bits == 32) {
            return
                uint32(uint8(data[pos])) +
                uint32(uint8(data[pos + 1])) *
                2**8 +
                uint32(uint8(data[pos + 2])) *
                2**16 +
                uint32(uint8(data[pos + 3])) *
                2**24;
        } else if (bits == 64) {
            return
                uint64(uint8(data[pos])) +
                uint64(uint8(data[pos + 1])) *
                2**8 +
                uint64(uint8(data[pos + 2])) *
                2**16 +
                uint64(uint8(data[pos + 3])) *
                2**24 +
                uint64(uint8(data[pos + 4])) *
                2**32 +
                uint64(uint8(data[pos + 5])) *
                2**40 +
                uint64(uint8(data[pos + 6])) *
                2**48 +
                uint64(uint8(data[pos + 7])) *
                2**56;
        }
    }

    // scan the full transaction bytes and return the first two output
    // values (in satoshis) and addresses (in binary)
    function getFirstTwoOutputs(bytes memory txBytes)
        public
        returns (
            uint256,
            bytes20,
            uint256,
            bytes20
        )
    {
        uint256 pos;
        uint256[] memory input_script_lens = new uint256[](2);
        uint256[] memory output_script_lens = new uint256[](2);
        uint256[] memory script_starts = new uint256[](2);
        uint256[] memory output_values = new uint256[](2);
        bytes20[] memory output_addresses = new bytes20[](2);

        pos = 4; // skip version

        (input_script_lens, pos) = scanInputs(txBytes, pos, 0);

        (output_values, script_starts, output_script_lens, pos) = scanOutputs(
            txBytes,
            pos,
            2
        );

        for (uint256 i = 0; i < 2; i++) {
            bytes20 pkhash = parseOutputScript(
                txBytes,
                script_starts[i],
                output_script_lens[i]
            );
            output_addresses[i] = pkhash;
        }

        return (
            output_values[0],
            output_addresses[0],
            output_values[1],
            output_addresses[1]
        );
    }

    // Check whether `btcAddress` is in the transaction outputs *and*
    // whether *at least* `value` has been sent to it.
    function checkValueSent(
        bytes memory txBytes,
        bytes20 btcAddress,
        uint256 value
    ) public returns (bool) {
        uint256 pos = 4; // skip version
        (, pos) = scanInputs(txBytes, pos, 0); // find end of inputs

        // scan *all* the outputs and find where they are
        (
            uint256[] memory output_values,
            uint256[] memory script_starts,
            uint256[] memory output_script_lens,

        ) = scanOutputs(txBytes, pos, 0);

        // look at each output and check whether it at least value to btcAddress
        for (uint256 i = 0; i < output_values.length; i++) {
            bytes20 pkhash = parseOutputScript(
                txBytes,
                script_starts[i],
                output_script_lens[i]
            );
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
    function scanInputs(
        bytes memory txBytes,
        uint256 pos,
        uint256 stop
    ) public returns (uint256[] memory, uint256) {
        uint256 n_inputs;
        uint256 halt;
        uint256 script_len;

        (n_inputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_inputs) {
            halt = n_inputs;
        } else {
            halt = stop;
        }

        uint256[] memory script_lens = new uint256[](halt);

        for (uint8 i = 0; i < halt; i++) {
            pos += 36; // skip outpoint
            (script_len, pos) = parseVarInt(txBytes, pos);
            script_lens[i] = script_len;
            pos += script_len + 4; // skip sig_script, seq
        }

        return (script_lens, pos);
    }

    // scan the outputs and find the values and script lengths.
    // return array of values, array of script lengths and the
    // end position of the outputs.
    // takes a 'stop' argument which sets the maximum number of
    // outputs to scan through. stop=0 => scan all.
    function scanOutputs(
        bytes memory txBytes,
        uint256 pos,
        uint256 stop
    )
        public
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        uint256 n_outputs;
        uint256 halt;
        uint256 script_len;

        (n_outputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_outputs) {
            halt = n_outputs;
        } else {
            halt = stop;
        }

        uint256[] memory script_starts = new uint256[](halt);
        uint256[] memory script_lens = new uint256[](halt);
        uint256[] memory output_values = new uint256[](halt);

        for (uint256 i = 0; i < halt; i++) {
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
    function sliceBytes20(bytes memory data, uint256 start)
        public
        returns (bytes20)
    {
        uint160 slice = 0;
        for (uint160 i = 0; i < 20; i++) {
            slice += uint160(uint8(data[i + start])) << (8 * (19 - i));
        }
        return bytes20(slice);
    }

    // returns true if the bytes located in txBytes by pos and
    // script_len represent a P2PKH script
    function isP2PKH(
        bytes memory txBytes,
        uint256 pos,
        uint256 script_len
    ) public returns (bool) {
        return
            (script_len == 25) && // 20 byte pubkeyhash + 5 bytes of script
            (txBytes[pos] == 0x76) && // OP_DUP
            (txBytes[pos + 1] == 0xa9) && // OP_HASH160
            (txBytes[pos + 2] == 0x14) && // bytes to push
            (txBytes[pos + 23] == 0x88) && // OP_EQUALVERIFY
            (txBytes[pos + 24] == 0xac); // OP_CHECKSIG
    }

    // returns true if the bytes located in txBytes by pos and
    // script_len represent a P2SH script
    function isP2SH(
        bytes memory txBytes,
        uint256 pos,
        uint256 script_len
    ) public returns (bool) {
        return
            (script_len == 23) && // 20 byte scripthash + 3 bytes of script
            (txBytes[pos + 0] == 0xa9) && // OP_HASH160
            (txBytes[pos + 1] == 0x14) && // bytes to push
            (txBytes[pos + 22] == 0x87); // OP_EQUAL
    }

    // Get the pubkeyhash / scripthash from an output script. Assumes
    // pay-to-pubkey-hash (P2PKH) or pay-to-script-hash (P2SH) outputs.
    // Returns the pubkeyhash/ scripthash, or zero if unknown output.
    function parseOutputScript(
        bytes memory txBytes,
        uint256 pos,
        uint256 script_len
    ) public returns (bytes20) {
        if (isP2PKH(txBytes, pos, script_len)) {
            return sliceBytes20(txBytes, pos + 3);
        } else if (isP2SH(txBytes, pos, script_len)) {
            return sliceBytes20(txBytes, pos + 2);
        } else {
            return bytes20(0);
        }
    }

    //NOTE: Only supports segwit txs
    //https://bitcoin.stackexchange.com/questions/79723/where-is-the-pubkey-for-segwit-inputs
    //if multisig, it will just grab the first pubkey
    function getPubKeyFromTx(bytes memory txBytes)
        public
        returns (bytes memory)
    {
        uint256 pos = 0;
        bytes memory pubkey;
        for (uint256 i = 0; i < txBytes.length; i++) {
            //byte with value 0x21 is used to show the start of the pubkey in the raw tx
            if (txBytes[i] == 0x21) {
                pos = i + 1;
                break;
            }
        }
        uint256 index = 0;
        for (uint256 i = pos; i < pos + 33; i++) {
            pubkey[index] = txBytes[i];
            index++;
        }
        return pubkey;
    }

    function getSegtwitSignature(bytes memory txBytes)
        public
        returns (bytes memory)
    {
        uint256 pos = 0;
        bytes memory signature;
        for (uint256 i = 0; i < txBytes.length; i++) {
            //byte with value 0x47 is used to show the start of the signature in the raw tx
            if (txBytes[i] == 0x47) {
                pos = i + 1;
                break;
            }
        }
        uint256 index = 0;
        for (uint256 i = pos; i < pos + 71; i++) {
            signature[index] = txBytes[i];
            index++;
        }
        return signature;
    }
}
