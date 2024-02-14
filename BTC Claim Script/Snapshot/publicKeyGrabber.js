const fs = require('fs');
const axios = require('axios');

const mylist = [];

// Read Bitcoin addresses from addresses.csv
const fileContents = fs.readFileSync('addresses.csv', { encoding: 'utf-8' });
const lines = fileContents.split('\n');
lines.forEach(line => {
    mylist.push(line.trim());
});

const outputFile = fs.createWriteStream('results.txt');

console.log("\n\n########################################################\nPlease be aware there is a 10 second timeout per request \nto blockchain.info to prevent API being blocked.\n########################################################\n\n");

async function fetchPublicKeys() {
    for (let i = 0; i < mylist.length; i++) {
        const address = mylist[i];
        const link = `https://blockchain.info/q/pubkeyaddr/${address}`;
        try {
            const response = await axios.get(link);
            const publicKey = response.data;
            if (publicKey !== '') {
                outputFile.write(`${publicKey}\n`);
                console.log(publicKey);
            }
        } catch (error) {
            console.error("Error occurred:", error);
        }
        await new Promise(resolve => setTimeout(resolve, 10000)); // 10 second timeout
    }
    outputFile.end();
}

fetchPublicKeys();
