contract escrow{

  mapping (address => uint) balances;

  address public seller;
  address public buyer;
  address escrow = msg.sender;
  bool sellerApprove;
  bool buyerApprove;

  function setup(address seller, address buyer){
    if(msg.sender == escrow){
        seller = seller;
        buyer = buyer;
    }
  }

  function approve(){
    if(msg.sender == buyer) buyerApprove = true;
    else if(msg.sender == seller) sellerApprove = true;
    if(sellerApprove && buyerApprove) fee();
  }

  function abort(){
      if(msg.sender == buyer) buyerApprove = false;
      else if (msg.sender == seller) sellerApprove = false;
      if(!sellerApprove && !buyerApprove) refund();
  }

  function payOut(){
    if(seller.send(this.balance)) balances[buyer] = 0;
  }

  function deposit(){
      if(msg.sender == buyer) balances[buyer] += msg.value;
      else throw;
  }

  function killContract() internal {
      selfdestruct(escrow);
      //kills contract and returns funds to buyer
  }

  function refund(){
    if(buyerApprove == false && sellerApprove == false) selfdestruct(buyer);
    //send money back to recipient if both parties agree contract is void
  }

  function fee(){
      escrow.send(this.balance / 100); //1% fee
      payOut();
  }

}
