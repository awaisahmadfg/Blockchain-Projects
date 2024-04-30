// const { ethers } = require('ethers');
// const contractABI = require("./mintingContractABI.json");
// const fs = require('fs');
// const pinataSDK = require('@pinata/sdk');

// require('dotenv').config();

// const { PINATA_API_KEY, PINATA_API_SECRET, WS_URL, CONTRACT_ADDRESS } = process.env;

// const pinata = new pinataSDK(PINATA_API_KEY, PINATA_API_SECRET);
// const provider = new ethers.WebSocketProvider(WS_URL);
// const contract = new ethers.Contract(CONTRACT_ADDRESS, contractABI, provider);

// const readEventNames = "NftMinted";

// /* read the log of current event */
// contract.on(readEventNames, (sender, tokenId, tokenUri) => {
//     const currentLogData = {
//         "sender": sender,
//         "tokenId": tokenId,
//         "tokenUri": tokenUri
//     };
//     console.log("Current Log Data: ", currentLogData);
// });



// /* Function to pin JSON data to IPFS using Pinata */
// function pinJSONToIPFS(jsonData, tokenId) {
//     const options = {
//         pinataMetadata: {
//             name: `NFT Token/${tokenId}.json`, // Set the name to the token ID
//             keyvalues: {
//                 key_1: 'value_1',
//                 key_2: 'value_2'
//             }
//         },
//         pinataOptions: {
//             cidVersion: 0 // Example, you can change it as needed
//         }
//     };

//     pinata.pinJSONToIPFS(JSON.parse(jsonData), options)
//         .then((result) => {
//             console.log('JSON pinned to IPFS successfully!');
//             console.log('IPFS Hash:', result.IpfsHash);
//         })
//         .catch((error) => {
//             console.error('Error pinning JSON to IPFS:', error);
//         });
// }

// /* read all the logs of an event and append into a file */
// async function readPastEvents(eventName) {
//     const filter = contract.filters[eventName]();
//     const events = await contract.queryFilter(filter);
//     events.forEach(async event => {
//         const { sender, tokenId, tokenUri } = event.args;

//         const eventData = {
//             sender: sender,
//             tokenId: tokenId.toString(), 
//             tokenUri: tokenUri
//         };

//         // Convert event data to JSON with BigInts handled
//         const jsonData = JSON.stringify(eventData, (key, value) =>
//             typeof value === 'bigint' ? value.toString() : value
//         );

//         // Pin the JSON data directly to IPFS
//         pinJSONToIPFS(jsonData, tokenId);
//     });
// }

// readPastEvents(readEventNames);



const { ethers } = require('ethers');
const contractABI = require("./mintingContractABI.json");
const pinataSDK = require('@pinata/sdk');

require('dotenv').config();

const { PINATA_API_KEY, PINATA_API_SECRET, WS_URL, CONTRACT_ADDRESS } = process.env;

const pinata = new pinataSDK(PINATA_API_KEY, PINATA_API_SECRET);
const provider = new ethers.WebSocketProvider(WS_URL);
const contract = new ethers.Contract(CONTRACT_ADDRESS, contractABI, provider);

const readEventNames = "NftMinted";

/* Function to extract event data and handle BigInts */
function extractEventData(event) {
    const { sender, tokenId, tokenUri } = event.args;
    return {
        sender,
        tokenId: tokenId.toString(),
        tokenUri
    };
}

/* Function to convert event data to JSON with BigInts handled */
function eventDataToJson(eventData) {
    return JSON.stringify(eventData, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value
    );
}

/* Function to pin JSON data to IPFS using Pinata */
async function pinJSONToIPFS(jsonData, tokenId) {
    const options = {
        pinataMetadata: {
            name: `NFT Token/${tokenId}.json`, 
        },
        pinataOptions: {
            cidVersion: 0 
        }
    };

    try {
        const result = await pinata.pinJSONToIPFS(JSON.parse(jsonData), options);
        console.log('JSON pinned to IPFS successfully!');
        console.log('IPFS Hash:', result.IpfsHash);
    } catch (error) {
        console.error('Error pinning JSON to IPFS:', error);
    }
}

/* Read all the logs of by eventName */
async function readPastEvents(eventName) {
    const filter = contract.filters[eventName]();
    const events = await contract.queryFilter(filter);
 
    events.forEach(async event => {
        const eventData = extractEventData(event);

        // Convert event data to JSON with BigInts handled
        const jsonData = eventDataToJson(eventData);

        // Pin the JSON data directly to IPFS
        await pinJSONToIPFS(jsonData, eventData.tokenId);
    });
}

readPastEvents(readEventNames);
