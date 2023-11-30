// const bs58 = require('bs58');
// const fs = require('fs');

// const btcData = require('../dataset/data.json');

// // Function to convert BTC address to bytes20
// function btcAddressToBytes20(btcAddress) {
//     const decoded = bs58.decode(btcAddress);
//     const addressHash = decoded.slice(1, 21); // Skipping the version byte
//     return '0x' + addressHash.toString('hex');
// }

// // Convert each BTC address to bytes20 and store in a new array
// const bytes20Addresses = btcData.map(item => {
//     return {
//         ...item,
//         bytes20Address: btcAddressToBytes20(item.address)
//     };
// });

// // Optionally, write the converted data to a new file
// fs.writeFileSync('../results/ConvertedData.json', JSON.stringify(bytes20Addresses, null, 2));

// console.log('Conversion complete. Data written to convertedData.json');





const bs58 = require('bs58');
const fs = require('fs');

// Load your BTC data
const btcData = require('../dataset/data.json');

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
    return bytes20Address ? { ...item, bytes20Address } : null;
}).filter(item => item !== null); // Remove any null entries due to conversion errors

// Write the converted data to a new file
fs.writeFileSync('../results/ConvertedData.json', JSON.stringify(convertedData, null, 2));

console.log('Conversion complete. Data written to ConvertedData.json');
