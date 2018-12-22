//slightly less efficient than selfdestructing a contract but more flexible
//as it allows you to destroy a custom amount of storage by bulk 
//rather than all or nothing with selfdestruct and a single tx for each
//deletion (this allows bulk deletion for each tx)
//mainnet: 0x3EFEB5D4e04eB7BB9c8007038cD5D9042bd9bC3E
contract GasSpeculator
{
    mapping(address => bytes32[]) storageBalance;

    function addStorage(uint rounds, address owner) public 
    {
        if(owner == address(0)) owner = msg.sender;
        for(uint i = 0; i < rounds; i++)
        {
            storageBalance[owner].push(0xff);
        }
    }

    function addStorageAsArray(bytes32[] arrayOfData, address owner) public
    {
        if(owner == address(0)) owner = msg.sender;
        for(uint i = 0; i < arrayOfData.length; i++)
        {
            storageBalance[owner].push(arrayOfData[i]);
        }
    }

    //this deletes the storage and activates the refund mechanism
    function freeUpStorage(uint rounds) public
    {
        for(uint i = 0; i < rounds; i++)
        {
            delete storageBalance[msg.sender][i];
        }
    }
    
    function freeUpIndicesOfStorage(uint[] indices) public 
    {
        for(uint i = 0; i < indices.length; i++) 
        {
            delete storageBalance[msg.sender][indices[i]];    
        }
    }
}


