contract accounting
{
  mapping(address => uint) transactions;
  mapping(address => uint) amounts;
  mapping(address => uint) balances;
  address taxAddr = 0x252d6c4b15dbc5b624c3d3785ed44d9ffbb13d04;
  uint256 taxesOwed;

  event Inflows(uint amount);
  event Outflows(uint amount);
  event CalcTax(uint256 amountDue);
  event PayTax(uint256 amount);

  //track incoming revenues coming into the business
  //makes accounting simpler and publicly verifiable
  function inflows() returns (uint256)
  {
    transactions[msg.sender] += 1;
    amounts[msg.sender] += msg.value;
    balances[msg.sender] += msg.value;
    Inflows(msg.value);
    return this.balance;
  }

  //tracks expenses of business by paying outflows via this function
  //and holding company money in the contract
  //Note: probably best to do this on the fly rather than keeping ether in the contract
  function outflows(uint amount) returns (uint256)
  {
    if(balances[msg.sender] > amount && msg.sender.send(amount))
    {
      transactions[msg.sender] += 1;
      amounts[msg.sender] -= amount;
    }
    Outflows(amount);
    return this.balance;
  }

  function calcTax(uint256 amountDue) returns (uint256)
  {
      taxesOwed += amountDue;
      CalcTax(amountDue);
      return taxesOwed;
  }

  function payTax(uint256 amount) returns (uint256)
  {
    if(taxAddr.send(amount)) taxesOwed -= amount;
    PayTax(amount);
    return taxesOwed;
  }

}
