contract accounting {

  mapping(address => uint) transactions;
  mapping(address => uint) amounts;
  mapping(address => uint) balances;
  address taxAddr = 0x252d6c4b15dbc5b624c3d3785ed44d9ffbb13d04;
  uint256 taxesOwed;

  event Inflows();
  event Outflows(uint amount);
  event CalcTax(uint256 amountDue);
  event PayTax(uint256 amount);

  function inflows() returns (uint256) {
    transactions[msg.sender] += 1;
    amounts[msg.sender] += msg.value;
    balances[msg.sender] += msg.value;
    Inflows();
    return this.balance;
  }

  function outflows(uint amount) returns (uint256) {
    if(balances[msg.sender] > amount && msg.sender.send(amount)){
      transactions[msg.sender] += 1;
      amounts[msg.sender] -= amount;
    }
    Outflows(amount);
    return this.balance;
  }

  function calcTax(uint256 amountDue) returns (uint256){
      taxesOwed += amountDue;
      CalcTax(amountDue);
      return taxesOwed;
  }

  function payTax(uint256 amount) returns (uint256){
    if(taxAddr.send(amount)) taxesOwed -= amount;
    PayTax(amount);
    return taxesOwed;
  }

}
