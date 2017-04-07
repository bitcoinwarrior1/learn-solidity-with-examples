contract cointoss
{
    uint hashOfPlayer1 = 0;
    uint hashOfPlayer2 = 0;
    address player1;
    address player2;
    uint p1Guess = 0;
    uint p2Guess = 0;
    uint expiryTimeStamp;

    modifier playerOnly()
    {
        if(msg.sender != player1 || msg.sender != player2){
            throw;
        }
        else _;
    }

    modifier hashesHaveBeenSubmitted()
    {
        if(hashOfPlayer1 == 0 || hashOfPlayer2 == 0){
            throw;
        }
        else _;
    }

    modifier numbersHaveBeenSubmitted()
    {
        if(p1Guess != 0 && p2Guess != 0)
        {
            _;
        }
        else throw;
    }

    function cointoss(address p1, address p2)
    {
        player1 = p1;
        player2 = p2;
        expiryTimeStamp = block.timestamp + 600000; //10 minutes
    }

    function submitHash(uint hash) playerOnly
    {
        if(msg.sender == player1)
            hashOfPlayer1 = hash;
        else
            hashOfPlayer2 = hash;
    }

    function checkHashAgainstNumber(uint n, int playerNum) hashesHaveBeenSubmitted returns (bool)
    {
        if(playerNum == 1 && uint(sha3(n)) == hashOfPlayer1)
        {
            p1Guess = n;
            return true;
        }
        else if(uint(sha3(n)) == hashOfPlayer2)
        {
            p2Guess = n;
            return true;
        }
        return false;
    }

    function payWinner() numbersHaveBeenSubmitted
    {
        if( p1Guess % 2 == 0)
            player1.send(this.balance);
        else
            player2.send(this.balance);
    }

    function timePayout()
    {
        if(expiryTimeStamp < block.timestamp)
        {
            if(p1Guess == 0)
            {
                player2.send(this.balance);
            }
            else if(p2Guess == 0)
            {
                player1.send(this.balance);
            }
        }
    }

}
