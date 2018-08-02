## BTC to ETH secure cross chain swap

### Purpose: To allow anyone to send bitcoin to our address and receive the corresponding amount of ether (ether, classic or tokens) as set by the market maker. The sender will be called Alice, the receiver and market maker, Bob. 

### Introduction

BtcRelay is a service first devised by Joseph Chow of Consensys with the intention of allowing cross chain transactions to occur in a decentralised manner. 

BtcRelay allows you to build an spv proof inside an ethereum smart contract and thus validate a transaction occurring in bitcoin inside ethereum.

The potential implications of this are big, as this can allow for a lot of cross chain services to happen, such as the one we will present here.

Bitcoin (and clones of Bitcoin) swaps with Ethereum (or any forks of ethereum)

With BTCRelay Bob should be able to swap Bitcoin for Ethereum in a trust less and secure way, Alice can send 1 Btc to Bobs Bitcoin address, Bob (or anyone else) can then take the transaction details and broadcast it to the smart contract, as Bob sets the price at 10 Eth to 1 BTC inside the smart contract, the smart contract can send back the amount required directly to Alice by retrieving her public key in the transaction, keccak256 it (to get the ethereum address) and send back 10 Eth to her. 

Below are some example steps of the implementation here: https://github.com/James-Sangalli/Solidity-Contract-Examples/blob/master/Finance/bitcoin-to-ethereum-swap/BTC2ETH.sol

### Steps for Bob to become the market maker:

- Bob creates the smart contract and sends 1000 eth to store as liquidity in the contract
- Bob sets his bitcoin address that receives the funds to be swapped inside the smart contract
- Bob sets the daily rate for ether to bitcoin inside the smart contract
- Bob sets the fee for the transaction that he would like e.g. 2%
- Optional: Bob adds a small fee back to the relayer of the block that the transaction is in 

### Steps for Alice to get her Ether for Bitcoin

- Alice checks that Bob’s contract has enough ether for her trade
- She checks what Bitcoin address to send the Bitcoin to
- She checks to see if she is happy with the rate
- She sends 1 bitcoin to Bob’s bitcoin address, expecting back 10 ether

### Steps for Carol to complete the transaction (note, Carol is probably Bob’s assistant or Bob himself)

- Carol runs a Bitcoin node and notices a new transaction in the address set by Bob
- Carol gets the transaction info and submits it to the smart contract to validate 

### Steps for the smart contract
- The smart contract is able to get Alice’s public key from the transaction and hash it with Keccak256 to produce an ethereum address that is controlled by the same private key (this is possible because both Bitcoin and Ethereum use the same private key algorithm) 
- The smart contract validates the transaction against BTCRelay and see’s that it is valid and that it has at least 6 confirmations
- The smart contract gets the amount of Bitcoin from the transaction, and calculates the amount based on the daily rate (e.g. 1btc = 1 * 10 Eth) set by Bob. 
- The smart contract sends back the amount of ether to Alice’s ethereum address which is derived from the public key of her bitcoin address, meaning that she receives the ether on the private key she already owns and requires no validation to make sure it is her key.

### Incentives for spv relayers:

One of the biggest issues with BTCRelay is providing incentives for ethereum nodes to relay Bitcoin headers.

This can be mitigated by allowing Bob to set a small fee for each transaction that can go to the relayer of the block, this would provide an added bonus to incentivise Relayers. 

