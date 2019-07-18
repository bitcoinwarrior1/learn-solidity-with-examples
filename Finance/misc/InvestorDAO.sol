/*
    Preamble: 
    CDPs and compound provide valuable data about the potential pricing of assets like DAI, cDAI and ether. 
    When CDP collateral is high, faith in the value of ether is low and the amount of DAI issued is constricted,
    thereby making the returns on compound for lending higher. 
    Likewise, when the collateral rate is low on CDPs, faith in the ether price is high and the amount of DAI issued
    is expanded. This makes compound returns low and thus a higher incentive to hold ether.
    
    While these numbers are never totally accurate, they are a lot more solid than predictions on the price because 
    there is skin in the game. This means it acts like a prediction market whereby the users are voting with their own 
    money rather than talking a big game. 
    
    With this information, it might be possible to create a fund manager contract whereby users can delegate authority
    over their wrapped ether and DAI, choose what collateral rates they wish to choose (or use the managers) and then 
    swap their DAI/cDAI for ether and vice versa based on the collateral supply and the return in compound. 
    
    This contract would not hold any of the money and would simply delegate transactions on behalf of the users.
    
    There are therefore 3 personas:
    
    Alice: Investor who wraps her ether and delegates it to the smart contract to move her funds, based on her
    own rates or rates provided by an approved oracle.
    
    Bob: a manager who thinks he knows the best ratios and therefore submits a struct with the appropriate figures 
    (can update them as he pleases)
    
    Charlie: Somebody who wants to make a small fee by triggering the smart contract when a price event occurs
    Charlie has no influence on the price coming from the source. 
    
    Note: all price events are sourced from compound and the CDP, this is better as it means it is hard for someone 
    to attack the contract by fudging the numbers. (CDP can provide ETH/USD rate & collateral percentages, While
    compound can provide its return rate).

*/
//Contract uses this to delegate with DAI, cDAI and WETH
//@requires approve from the user
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//to invest in compound
contract cDAI {
    function mint(uint amount) public; 
}

pragma experimental ABIEncoderV2; 
contract DAOFund {
    
    //If the user doesn't know what allocations to provide here, they can simply give it to a manager
    //who will decide for them for a fee. 
    struct Account {
        uint sellDaiForWETHCollateralPercentage; 
        uint buyDaiWithWethCollateralPercentage; 
    }
    
    mapping (address => Account) public investors; 
    mapping (address => Account) public managers; //managers allocations, simply choose one (potential regulator risk)
    mapping (address => uint) public ROI;
    
    //must approve use of funds in WETH and DAI
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant dai = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359; 
    ERC20Interface wethContract = ERC20Interface(weth);
    ERC20Interface daiContract = ERC20Interface(dai);
    
    function createOrUpdateAccount(Account memory account) public {
        //Alice sets her own ratios or uses a managers 
    }
    
    function triggerActionOnBehalfOfInvestor(address investor) public {
        //check collateral from CDP and match to investor account
        //If ratios are correct, move funds on behalf of investor for a small fee 
        //(calling convertWETHToDAI or investDAIIntoCompound)
        //This is Charlie's job but an investor could do it for themselves to save the fee
    }
    
    function convertWETHToDAI(address investor, uint amount) internal {
        //can only be called by contract from a triggerActionOnBehalfOfInvestor
        //Converts WETH to DAI and invests it into compound for cDAI
    }
    
    function investDAIIntoCompound(address investor, uint amount) internal {
        //invests the DAI from the investor into compound 
    }
    
    function sellDAIForWETH(address investor, uint amount) internal {
        //if it is more attractive to hold WETH (according to investor preference), 
        //convert the cDAI into DAI then WETH (or simply cDAI straight to WETH)
    }
    
}
