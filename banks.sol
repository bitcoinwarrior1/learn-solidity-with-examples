contract Bank {

    address owner;

    mapping (address => uint) balances;

    // Constructor
    function Bank(){
        owner = msg.sender;
    }

    // This will take the value of the transaction and add to the senders account.
    function deposit(address customer) returns (bool res) {
        // If the amount they send is 0, return false.
        if (msg.value == 0){
            return false;
        }
        balances[customer] += msg.value;
        return true;
    }

    // Attempt to withdraw the given 'amount' of Ether from the account.
    function withdraw(address customer, uint amount) returns (bool res) {
        // Skip if someone tries to withdraw 0 or if they don't have
        // enough Ether to make the withdrawal.
        if (balances[customer] < amount || amount == 0)
            return false;
        balances[customer] -= amount;
        msg.sender.send(amount);
        return true;
    }

    function remove() {
        if (msg.sender == owner){
            suicide(owner);
        }
    }
}

contract FundManager {

    address owner;
    // This holds a reference to the current bank contract.
    address bank;

    // Constructor
    function FundManager(){
        owner = msg.sender;
        // We still start with the normal bank.
        bank = new Bank();
    }

    // NEW
    // *************************************************************************

    // Add a new bank address to the contract.
    function setBank(address newBank) constant returns (bool res) {
        if (msg.sender != owner){
            return false;
        }
        bank = newBank;
        return true;
    }

    // *************************************************************************

    // Attempt to withdraw the given 'amount' of Ether from the account.
    function deposit() returns (bool res) {
        if (msg.value == 0){
            return false;
        }
        if ( bank == 0x0 ) {
            // If the user sent money, we should return it if we can't deposit.
            msg.sender.send(msg.value);
            return false;
        }

        // Use the interface to call on the bank contract. We pass msg.value along as well.
        bool success = Bank(bank).deposit.value(msg.value)(msg.sender);

        // If the transaction failed, return the Ether to the caller.
        if (!success) {
            msg.sender.send(msg.value);
        }
        return success;
    }

    // Attempt to withdraw the given 'amount' of Ether from the account.
    function withdraw(uint amount) returns (bool res) {
        if ( bank == 0x0 ) {
            return false;
        }
        // Use the interface to call on the bank contract.
        bool success = Bank(bank).withdraw(msg.sender, amount);

        // If the transaction succeeded, pass the Ether on to the caller.
        if (success) {
            msg.sender.send(amount);
        }
        return success;
    }

}
