const { ethers } = require('ethers');
const contractABI = require("./demoContractABI/contractABI.json")
require('dotenv').config();
const fs = require('fs');
const os = require('os');

const wsurl = process.env.WS_URL
const contractAddress = process.env.CONTRACT_ADDRESS;

const provider = new ethers.WebSocketProvider(wsurl);
const contract = new ethers.Contract(contractAddress, contractABI, provider);

readEventNames = "NftMinted"

/* read the log of current event */
contract.on(readEventNames, (sender, tokenId, tokenUri) => {
    currentLogData = {
        "sender" : sender,
        "tokenId" : tokenId,
        "tokenUri" : tokenUri
    }
    console.log("Current Log Data: ", currentLogData)
})


/* read all the loggs of an event and append into a file */
readPastEvents = async function (eventName) {
    const filter = contract.filters[eventName]();
    const events = await contract.queryFilter(filter);
    events.forEach(event => {
        const { sender, tokenId, tokenUri } = event.args;

        fs.appendFile(`${eventName}.txt`, `${sender}, ${tokenId}, ${tokenUri} ${os.EOL}`, function (err) {
            if (err) throw err;
            console.log('Saved!');
        });
    });
}


// WS_URL = "wss://sepolia.infura.io/ws/v3/789a100ae5ab48c9a378ab3d7e060e00"
// CONTRACT_ADDRESS = "0xf8830d31153e242E462F7E9eaA83bAD5462884a5"
// HTTP_URL = "https://sepolia.infura.io/v3/789a100ae5ab48c9a378ab3d7e060e00"

readPastEvents(readEventNames);
