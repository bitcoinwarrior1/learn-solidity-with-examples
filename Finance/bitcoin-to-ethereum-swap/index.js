$(() => {
    let Web3 = require("web3");
    let web3 = new Web3(new Web3.providers.HttpProvider('https://mainnet.infura.io/llyrtzQ3YhkdESt2Fzrk'));
    let abi = "";
    let contractAddress = "";
    let contract = web3.eth.contract(abi).at(contractAddress);
    contract.getCurrentRate.call().then((err, data) => {
        $("#currentRate").val(data);
    });

});