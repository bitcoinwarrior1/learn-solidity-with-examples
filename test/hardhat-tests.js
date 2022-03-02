const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ETH2BTC.sol", function () {
  let contract;
  let owner, user1;

  beforeEach(async () => {
    [owner, user1] = await ethers.getSigners();
    const ETH2BTC = await ethers.getContractFactory("ETH2BTC");
    contract = await ETH2BTC.deploy(
      "0xbe086099e0ff00fc0cfbc77a8dd09375ae889fbd",
      owner.address,
      30,
      100
    );
    await contract.deployed();
  });

  it("Should be able to set a rate as admin", async function () {
    await contract.setEtherToBitcoinRate(10);
    const rate = await contract.etherToBitcoinRate();
    expect(rate).to.equal(10, "rate should be set to 10");
  });
});
