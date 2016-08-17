// var bankPlus = require("../contracts/bankPlus");

contract("bankPlus", (accounts) => {
  it("Should allow me to deposit some ether into a customer account", () => {
    var bank = bankPlus.deployed();
    var customer = accounts[1];

    bank.deposit.call(customer, {from:customer,amount:10000000000})
    .then( (data) => {
      console.log(data);
      return bank.call.getBalanceOf(customer);
    })
  });
  // it("show allow me to pay the bank tax contract", () => {
  //
  // });
});
