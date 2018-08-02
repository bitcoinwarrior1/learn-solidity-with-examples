## BTC to ETH secure cross chain swap

### Purpose 

Allow anyone to seamlessely swap their Bitcoin for Ethereum in a trustless and secure way. 

In this short description, Alice will be the buyer/sender, Bob the market maker and Carol, Bob's assistant. 

### Introduction

BtcRelay is a service invented by Joseph Chow with the intention to allow Bitcoin SPV verification to be done inside an ethereum smart contract. 

The potential of such a service is massive as it can allow for cross chain services to happen, like the one mentioned below.

Note: with this technology it is also possible to relay on other ethereum networks as well as clones of Bitcoin that use SPV. 

### Implementation 

Let's say that Bob has a large stash of Ether and would like to create a service whereby he can sell his ether safely for a profit in exchange for bitcoin without worrying about fraud or potential for accidental loss. 

With the smart contract here: https://github.com/James-Sangalli/Solidity-Contract-Examples/blob/master/Finance/bitcoin-to-ethereum-swap/BTC2ETH.sol Bob can create the contract, set a fresh Bitcoin address controlled by himself to receive coins and set himself as the admin of the contract, allowing him to set the rate of Bitcoin to Ethereum.

Note: Since Bitcoin and Ethereum use the same private key algorithm, it is possible for Alice to recieve ether on the same key that holds her bitcoins (by getting the public key from the bitcoin transaction and hashing it into an ethereum address).

### Steps for Bob to become the market maker:

- Bob creates the smart contract and sends 1000 eth to store as liquidity in the contract
- Bob sets his bitcoin address that receives the funds to be swapped using the smart contract (this should be a fresh address as old transactions that are irrelevant could be claimed otherwise) 
- Bob sets the daily rate for ether to bitcoin inside the smart contract 
- Optional: Bob sets the fee for the transaction that he would like e.g. 2%
- Optional: Bob adds a small fee back to the relayer of the block that the transaction is in 

### Steps for Alice to get her Ether for Bitcoin

- Alice checks that Bob’s contract has enough ether for her trade
- She checks what Bitcoin address to send the Bitcoin to
- She checks to see if she is happy with the rate (in this example it is 10:1)
- She sends 1 bitcoin to Bob’s bitcoin address, expecting back 10 ether minus fees after 6 confirmations on the Bitcoin network

### Steps for Carol to complete the transaction (note, Carol is probably Bob’s assistant or Bob himself)

- Carol runs a Bitcoin node and notices a new transaction in the address set by Bob
- Carol gets the transaction info and submits it to the smart contract to validate. In this case it is the raw transaction, transaction hash, merkle sybling and the block hash. 

### Steps for the smart contract

- BtcRelay validates that the transaction has occured in the Bitcoin blockchain
- If it has happened then the smart contract derives the corresponding ethereum address by taking the public key from the transaction and hashing it into an ethereum address. 
- The smart contract sends the ether to Alice and adds the transaction hash to an array to ensure that the transaction is not resubmitted 

### Note on BtcRelay relayers

One of the biggest issues with BTCRelay is providing incentives for ethereum nodes to relay Bitcoin headers, this can be mitigated by Bob if he decides to allocate a portion of the transaction as a fee back to the relayer. 

### Security Considerations

- If Bob is close with miners, he can conspire to delay Alice's transaction and take all the liquidity away from the contract
- Bob risks his ether in the smart contract (contract must be airtight)
- Relayers might go silent and stop relaying (can be mitigated by anyone willing to run nodes and relay)


