const { ethers } = require('ethers');
const contractABI = require("./mintingContractABI.json");
const fs = require('fs');
const os = require('os');
require('dotenv').config();

const pinataSDK = require('@pinata/sdk');
const { PINATA_API_KEY, PINATA_API_SECRET } = process.env;
const pinata = new pinataSDK(PINATA_API_KEY, PINATA_API_SECRET);

const wsurl = process.env.WS_URL;
const contractAddress = process.env.CONTRACT_ADDRESS;

const provider = new ethers.WebSocketProvider(wsurl);
const contract = new ethers.Contract(contractAddress, contractABI, provider);

const readEventNames = "NftMinted";

/* read the log of current event */
contract.on(readEventNames, (sender, tokenId, tokenUri) => {
    const currentLogData = {
        "sender": sender,
        "tokenId": tokenId,
        "tokenUri": tokenUri
    };
    console.log("Current Log Data: ", currentLogData);
});

/* read all the logs of an event and append into a file */
async function readPastEvents(eventName) {
    const filter = contract.filters[eventName]();
    const events = await contract.queryFilter(filter);
    events.forEach(event => {
        const { sender, tokenId, tokenUri } = event.args;

        fs.appendFile(`${eventName}.txt`, `${sender}, ${tokenId}, ${tokenUri} ${os.EOL}`, function (err) {
            if (err) throw err;
            console.log('Saved!');
        });

        // Pin the file to IPFS
        pinFileToIPFS(`${eventName}.txt`);
    });
}

/* Function to pin a file to IPFS using Pinata */
function pinFileToIPFS(filePath) {
    const readableStreamForFile = fs.createReadStream(filePath);
    const options = {
        pinataMetadata: {
            name: "Oracle API",
            keyvalues: {
                key_1: 'value_1',
                key_2: 'value_2'
            }
        },
        pinataOptions: {
            cidVersion: 0 // Example, you can change it as needed
        }
    };

    pinata.pinFileToIPFS(readableStreamForFile, options)
        .then((result) => {
            console.log('File pinned to IPFS successfully!');
            console.log('IPFS Hash:', result.IpfsHash);
        })
        .catch((error) => {
            console.error('Error pinning file to IPFS:', error);
        });
}

readPastEvents(readEventNames);
