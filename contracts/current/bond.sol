contract bond
{
    modifier landlordOnly() { if(msg.sender!= landlord) throw; _; }
    modifier tenantOnly()
    {
      for(uint i = 0; i < tenants.length; i++)
      {
        if(msg.sender == tenants[i]){
          _;
          return;
        }
      }
      throw;
    }

    address landlord;
    address[] tenants;

    mapping(address => uint) balances;

    function(){ throw; }

    function bond() { landlord = msg.sender;  }

    function setTenant(address tenant) landlordOnly
    {
        tenants.push(tenant);
        balances[tenant] = 0;
    }

    function payBond() tenantOnly
    {
        balances[msg.sender] = msg.value;
    }

    function giveRefundToTenant(address tenant) landlordOnly
    {
      if(tenant.send(balances[tenant])){ balances[tenant] = 0; }
    }

    function giveBondToLandlord() tenantOnly
    {
        //if tenant agrees to give bond to landlord
        if(landlord.send(balances[msg.sender])){
          balances[msg.sender] = 0;
        }

    }
}
