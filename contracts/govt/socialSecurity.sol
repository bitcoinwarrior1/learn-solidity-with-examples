contract socialSecurity {

   address uncleSam;
   uint256 blockTimePerYear = 1855059;
   //uncle sam or someone else must top up the fund to above 10% of all deposits
   mapping(address => uint) balances;
   mapping(address => uint) blockTime;

   modifier uncleSamOnly() { if(msg.sender != uncleSam) throw; _}

   function socialSecurity(){
     uncleSam = msg.sender;
   }

   function addRecipient(uint age, address user) uncleSamOnly{
     balances[user] = 0;
     blockTime[user] = now + ((65 - age) * blockTimePerYear);
     //how many blocks they need to wait to get payment
   }

   function addContribution(){
     balances[msg.sender] += msg.value;
   }

   function withdrawPension(){
     if(now >= blockTime[msg.sender]){
       balances[msg.sender] = balances[msg.sender] * 110 / 100; //pays out 10% of total contributions
       if(msg.sender.send(balances[msg.sender])) balances[msg.sender] = 0;
     }
     else throw;
   }

   function getBalanceOfFund() returns (uint) {
       return this.balance;
   }

   function abortSocialSecurity(){
     if(msg.sender == uncleSam) selfdestruct(uncleSam);
   }
}
