// Factory "morphs" into a Pudding class.
// The reasoning is that calling load in each context
// is cumbersome.

(function() {

  var contract_data = {
    abi: [{"constant":false,"inputs":[{"name":"shareholder","type":"address"},{"name":"amount","type":"uint256"}],"name":"payDividend","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"shareholder","type":"address"},{"name":"amount","type":"uint256"}],"name":"addShareholder","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"shareholder","type":"address"},{"name":"amount","type":"uint256"}],"name":"sellShares","outputs":[],"type":"function"},{"constant":false,"inputs":[{"name":"shareholder","type":"address"},{"name":"amount","type":"uint256"}],"name":"tax","outputs":[],"type":"function"}],
    binary: "606060405260018054600160a060020a03191661aabb179055610127806100266000396000f3606060405260e060020a600035046361175f41811461003c578063757249901461008d578063b51d0534146100b1578063d9b57789146100cb575b005b61003a600435602435600160a060020a038281166000818152602081905260408051908220543090941631936064908502049082818181858883f19350505050506100fd83606484602102046100d5565b600160a060020a03600435166000908152602081905260409020602435905561003a565b61003a6004356024356064602182020461010283826100d5565b61003a6004356024355b600154604051600160a060020a0390911690600090839082818181858883f150505050505050565b505050565b604051600160a060020a03841690600090849082818181858883f1505050505050505056",
    unlinked_binary: "606060405260018054600160a060020a03191661aabb179055610127806100266000396000f3606060405260e060020a600035046361175f41811461003c578063757249901461008d578063b51d0534146100b1578063d9b57789146100cb575b005b61003a600435602435600160a060020a038281166000818152602081905260408051908220543090941631936064908502049082818181858883f19350505050506100fd83606484602102046100d5565b600160a060020a03600435166000908152602081905260409020602435905561003a565b61003a6004356024356064602182020461010283826100d5565b61003a6004356024355b600154604051600160a060020a0390911690600090839082818181858883f150505050505050565b505050565b604051600160a060020a03841690600090849082818181858883f1505050505050505056",
    address: "",
    generated_with: "2.0.9",
    contract_name: "stock"
  };

  function Contract() {
    if (Contract.Pudding == null) {
      throw new Error("stock error: Please call load() first before creating new instance of this contract.");
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
      throw new Error("stock error: Please call load() first before calling new().");
    }

    return Contract.Pudding.new.apply(Contract, arguments);
  };

  Contract.at = function() {
    if (Contract.Pudding == null) {
      throw new Error("stock error: Please call load() first before calling at().");
    }

    return Contract.Pudding.at.apply(Contract, arguments);
  };

  Contract.deployed = function() {
    if (Contract.Pudding == null) {
      throw new Error("stock error: Please call load() first before calling deployed().");
    }

    return Contract.Pudding.deployed.apply(Contract, arguments);
  };

  if (typeof module != "undefined" && typeof module.exports != "undefined") {
    module.exports = Contract;
  } else {
    // There will only be one version of Pudding in the browser,
    // and we can use that.
    window.stock = Contract;
  }

})();
