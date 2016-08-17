// Factory "morphs" into a Pudding class.
// The reasoning is that calling load in each context
// is cumbersome.

(function() {

  var contract_data = {
    abi: [{"constant":false,"inputs":[],"name":"payDividend","outputs":[],"type":"function"},{"constant":false,"inputs":[],"name":"payTax","outputs":[],"type":"function"}],
    binary: "606060405260008054600160a060020a03199081167321aadccb23591608f06f37fd5cb9aa264ae9fa3c1782556001805482167389ed07588c0f0ea1156b337273b9326b1c8ac9ab17905560028054821673dc85a8429998bd4eef79307e556f70bb70d8caf1179055600380549091167329a02cd0f340efb6492c535a951fb33270ad1ef717905560da90819061009590396000f3606060405260e060020a60003504630b6826ca811460245780632912ba5f1460ab575b005b602260008054604051600160a060020a03918216929160033090911631049082818181858883f15050600154604051600160a060020a0391821694506003309092163191909104915082818181858883f15050600254604051600160a060020a0391821694506003309092163191909104915082818181858883f193505050505060d860ae565b60225b600354604051600160a060020a039182169160009130909116319082818181858883f15050505050565b56",
    unlinked_binary: "606060405260008054600160a060020a03199081167321aadccb23591608f06f37fd5cb9aa264ae9fa3c1782556001805482167389ed07588c0f0ea1156b337273b9326b1c8ac9ab17905560028054821673dc85a8429998bd4eef79307e556f70bb70d8caf1179055600380549091167329a02cd0f340efb6492c535a951fb33270ad1ef717905560da90819061009590396000f3606060405260e060020a60003504630b6826ca811460245780632912ba5f1460ab575b005b602260008054604051600160a060020a03918216929160033090911631049082818181858883f15050600154604051600160a060020a0391821694506003309092163191909104915082818181858883f15050600254604051600160a060020a0391821694506003309092163191909104915082818181858883f193505050505060d860ae565b60225b600354604051600160a060020a039182169160009130909116319082818181858883f15050505050565b56",
    address: "",
    generated_with: "2.0.9",
    contract_name: "dividend"
  };

  function Contract() {
    if (Contract.Pudding == null) {
      throw new Error("dividend error: Please call load() first before creating new instance of this contract.");
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
      throw new Error("dividend error: Please call load() first before calling new().");
    }

    return Contract.Pudding.new.apply(Contract, arguments);
  };

  Contract.at = function() {
    if (Contract.Pudding == null) {
      throw new Error("dividend error: Please call load() first before calling at().");
    }

    return Contract.Pudding.at.apply(Contract, arguments);
  };

  Contract.deployed = function() {
    if (Contract.Pudding == null) {
      throw new Error("dividend error: Please call load() first before calling deployed().");
    }

    return Contract.Pudding.deployed.apply(Contract, arguments);
  };

  if (typeof module != "undefined" && typeof module.exports != "undefined") {
    module.exports = Contract;
  } else {
    // There will only be one version of Pudding in the browser,
    // and we can use that.
    window.dividend = Contract;
  }

})();
