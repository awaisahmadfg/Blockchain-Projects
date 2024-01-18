// Encoding and decoding and File system-related library
const bs58 = require('bs58');
const fs = require('fs');

// Load the BTC data
const btcData = require('../scripts/dataset/data.json');

// Function to convert BTC address to bytes20
function btcAddressToBytes20(btcAddress) {
    try {
        const decoded = bs58.decode(btcAddress);
        if (decoded.length !== 25) {
            throw new Error('Unexpected decoded address length');
        }
        // Taking only the first 20 bytes of the hash part (excluding version and extra bytes)
        const addressHash = decoded.slice(1, 21);
        // Convert each byte to a two-character hex string
        return '0x' + Array.from(addressHash).map(byte => byte.toString(16).padStart(2, '0')).join('');
    } catch (error) {
        console.error(`Error converting BTC address: ${btcAddress}, Error: ${error.message}`);
        return null;
    }
}

// Convert each BTC address to bytes20 and store in a new array
const convertedData = btcData.map(item => {
    const bytes20Address = btcAddressToBytes20(item.address);
    // If the conversion is successful, it creates a new object with properties 
    if (bytes20Address) {
        return { 
            bytes20Address: bytes20Address,
            satoshis: item.satoshis,
            privkey: item.privkey
        };
    }
    return null;
}).filter(item => item !== null); // Remove any null entries due to conversion errors

// Write the converted data to a new file
fs.writeFileSync('../scripts/results/ConvertedData.json', JSON.stringify(convertedData, null, 2));

console.log('Conversion complete. Data written to ConvertedData.json');
