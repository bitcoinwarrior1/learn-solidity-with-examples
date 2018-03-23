pragma solidity ^0.4.21;

contract spreadfunds 
{
    function distributeFunds(address[] addresses, uint amt) public payable
    {
        uint num = msg.value / amt;
        require(num == addresses.length);
        for(uint i = 0; i < addresses.length; i++)
        {
            addresses[i].transfer(amt);    
        }
    }
}
