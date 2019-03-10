//A simple example of a library that simply converts an amount by a rate
library ConvertLib
{
	function convert(uint amount, uint conversionRate) returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}
