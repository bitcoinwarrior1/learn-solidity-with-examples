// Factory "morphs" into a Pudding class.
// The reasoning is that calling load in each context
// is cumbersome.

(function() {

  var contract_data = {
    abi: [{"constant":false,"inputs":[],"name":"withdrawPension","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"age","type":"uint256"},{"name":"user","type":"address"}],"name":"addRecipient","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"addContribution","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"abortSocialSecurity","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"getBalanceOfFund","outputs":[{"name":"","type":"uint256"}],"type":"function"}],
    binary: "606060405260008054600160a060020a03191673dc85a8429998bd4eef79307e556f70bb70d8caf1178155621c4e5360015561017090819061004090396000f3606060405260e060020a6000350463173f23d881146100475780638ab03929146100ce57806393cd40b41461010b5780639e9681f81461012e578063f367ebeb14610156575b005b61004533600160a060020a0316600090815260036020526040902054421061016b5760026020526040600090812080546064606e909102049081905533600160a060020a03169190606082818181858883f19350505050156100cc5760006002600050600033600160a060020a03168152602001908152602001600020600050819055505b565b602435600160a060020a03166000908152600260209081526040808320839055600154600390925290912060043560410390910242019055610045565b61004533600160a060020a03166000908152600260205260409020805434019055565b61004560005433600160a060020a03908116911614156100cc57600054600160a060020a0316ff5b30600160a060020a0316316060908152602090f35b61000256",
    unlinked_binary: "606060405260008054600160a060020a03191673dc85a8429998bd4eef79307e556f70bb70d8caf1178155621c4e5360015561017090819061004090396000f3606060405260e060020a6000350463173f23d881146100475780638ab03929146100ce57806393cd40b41461010b5780639e9681f81461012e578063f367ebeb14610156575b005b61004533600160a060020a0316600090815260036020526040902054421061016b5760026020526040600090812080546064606e909102049081905533600160a060020a03169190606082818181858883f19350505050156100cc5760006002600050600033600160a060020a03168152602001908152602001600020600050819055505b565b602435600160a060020a03166000908152600260209081526040808320839055600154600390925290912060043560410390910242019055610045565b61004533600160a060020a03166000908152600260205260409020805434019055565b61004560005433600160a060020a03908116911614156100cc57600054600160a060020a0316ff5b30600160a060020a0316316060908152602090f35b61000256",
    address: "",
    generated_with: "2.0.9",
    contract_name: "socialSecurity"
  };

  function Contract() {
    if (Contract.Pudding == null) {
      throw new Error("socialSecurity error: Please call load() first before creating new instance of this contract.");
    }

    Contract.Pudding.apply(this, arguments);
  };

  Contract.load = function(Pudding) {
    Contract.Pudding = Pudding;

    Pudding.whisk(contract_data, Contract);

    // Return itself for backwards compatibility.
    return Contract;
  }

  Contract.new = function() {
    if (Contract.Pudding == null) {
      throw new Error("socialSecurity error: Please call load() first before calling new().");
    }

    return Contract.Pudding.new.apply(Contract, arguments);
  };

  Contract.at = function() {
    if (Contract.Pudding == null) {
      throw new Error("socialSecurity error: Please call load() first before calling at().");
    }

    return Contract.Pudding.at.apply(Contract, arguments);
  };

  Contract.deployed = function() {
    if (Contract.Pudding == null) {
      throw new Error("socialSecurity error: Please call load() first before calling deployed().");
    }

    return Contract.Pudding.deployed.apply(Contract, arguments);
  };

  if (typeof module != "undefined" && typeof module.exports != "undefined") {
    module.exports = Contract;
  } else {
    // There will only be one version of Pudding in the browser,
    // and we can use that.
    window.socialSecurity = Contract;
  }

})();
