contract dividend {
  address Weiwu = 0x21aadccb23591608f06f37fd5cb9aa264ae9fa3c;
  address James = 0x89ed07588c0f0ea1156b337273b9326b1c8ac9ab;
  address Sangalli = 0xdc85a8429998bd4eef79307e556f70bb70d8caf1;
  address tax = 0x29a02cd0f340efb6492c535a951fb33270ad1ef7;

  function payDividend(){
    Weiwu.send(this.balance / 3);
    James.send(this.balance / 3);
    Sangalli.send(this.balance / 3);
    payTax();
  }

  function payTax(){ tax.send(this.balance); } //send of remaining funds
}
