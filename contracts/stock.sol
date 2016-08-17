contract stock {

	address taxman;
	mapping (address => uint) shares;

	function stock(){
		taxman = msg.sender;
	}

	function addShareholder(address shareholder, uint amount){
		address user = shareholder;
		shares[user] = amount;
	}

	function payDividend(address shareholder, uint amount){
		uint balance = this.balance;
		shareholder.send(balance * shares[shareholder] / 100);
		tax(shareholder, amount * 33 / 100);
	}

	function tax(address shareholder, uint amount){
		taxman.send(amount);
	}

	function sellShares(address shareholder, uint amount){
		this.balance - amount;
		uint taxes = amount * 33 / 100;
		amount - taxes;
		tax(shareholder, taxes);
		shareholder.send(amount);
	}
}
