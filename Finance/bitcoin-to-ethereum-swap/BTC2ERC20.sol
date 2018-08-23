import "./btcrelayInterface" as btcrelayInterface;
import "./BtcParser" as BtcParser;
import "./ERC20" as ERC20;

pragma solidity ^0.4.0;
contract BTC2ERC20 is BtcParser, btcrelayInterface, ERC20
{
    address _btcrelayAddress;
    bytes32[] claimedTxs;
    address admin;
    uint token2BitcoinRate;
    bytes32 bitcoinAddress;
    btcrelayInterface btcrelay;
    BtcParser btcParser = new BtcParser();
    mapping (address => uint) balances;
    uint feeToRelayer;
    uint feeToAdmin;

    constructor(bytes32 btcAddress, address btcrelayAddress, uint relayFee, uint adminFee) public
    {
        admin = msg.sender;
        bitcoinAddress = btcAddress;
        _btcrelayAddress = btcrelayAddress;
        if(_btcrelayAddress == address(0))
        {
            //default mainnet
            _btcrelayAddress = 0x41f274c0023f83391DE4e0733C609DF5a124c3d4;
        }
        btcrelay = btcrelayInterface(_btcrelayAddress);
        feeToRelayer = relayFee;
        feeToAdmin = adminFee;
    }

    function setToken2BitcoinPrice(uint rate) public
    {
        require(msg.sender == admin);
        token2BitcoinRate = rate;
    }

    function getCurrentRate() public view returns(uint)
    {
        return token2BitcoinRate;
    }

    // rawTransaction - raw bytes of the transaction
    // transactionIndex - transaction's index within the block, as int256
    // merkleSibling - array of the sibling hashes comprising the Merkle proof, as int256[]
    // blockHash - hash of the block that contains the transaction, as int256
    //uses the public key of the bitcoin address to generate the address
    //of the corresponding ether address
    //the same private key can claim the ether as was used to send the bitcoin
    function bitcoin2TokenSwap(
        bytes rawTransaction,
        uint256 transactionIndex,
        bytes32[] merkleSibling,
        uint256 blockHash
    ) public
    {
        //verify transaction, if valid add it to the list
        //derive the corresponding ethereum address by getting the public key
        //of the bitcoin sender and casting it to the address
        //pay out the amount of eth to the address applied by the daily rate
        bytes32 hashedRawTx = keccak256(rawTransaction);

        checkClaims(claimedTxs, hashedRawTx);

        uint256 response = btcrelay.verifyTx(
            rawTransaction,
            transactionIndex,
            merkleSibling,
            blockHash
        );

        require(response > 0); //returns 0 if nothing found
        bytes32 senderPubKey = getSenderPub(rawTransaction, blockHash);
        address sender = address(keccak256(abi.encodePacked(senderPubKey)));
        var (amt1, address1, amt2, address2) = btcParser.getFirstTwoOutputs(rawTransaction);
        uint amountToTransfer = amt1 * token2BitcoinRate;
        makeTransfers(amountToTransfer, sender, rawTransaction, blockHash);
    }

    //need to split up functions else the stack will run out
    function makeTransfers(
        uint amountToTransfer,
        address sender,
        bytes rawTransaction,
        uint256 blockHash) internal
    {
        require(msg.sender == address(this));
        uint deduction = feeToRelayer + feeToAdmin;
        sender.transfer(amountToTransfer - deduction);
        claimedTxs.push(keccak256(rawTransaction));
        address relayerOfBlock = btcrelay.getFeeRecipient(blockHash);
        //added incentive for block relayers
        balances[relayOfBlock] += feeToRelayer;
        //admin gets fee for providing service and liquidity
        balances[admin] += feeToAdmin;
        balances[sender] += amountToTransfer - deduction;
    }

    function checkClaims(bytes32[] claimTxs, bytes32 hashedRawTx) internal
    {
        for(uint i = 0; i < claimedTxs.length; i++)
        {
            require(claimedTxs[i] != hashedRawTx);
        }
    }

    function getSenderPub(bytes rawTransaction, uint256 blockHash) returns(bytes32)
    {
        var (amt1, address1, amt2, address2) = btcParser.getFirstTwoOutputs(rawTransaction);
        require(address1 == bitcoinAddress || address2 == bitcoinAddress);
        bytes32 senderPubKey = btcParser.parseOutputScript(
            rawTransaction,
            0,
            rawTransaction.length
        );
        return senderPubKey;
    }


  mapping (address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal _burn function.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
  }

}
