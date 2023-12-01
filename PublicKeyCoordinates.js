// const EC = require('elliptic').ec;
// const ec = new EC('secp256k1');
// const keccak256 = require('js-sha3').keccak256;
// const fs = require('fs');

// // Load the data
// const btcData = require("../results/ConvertedData.json"); 

// // Function to derive public key coordinates and Ethereum address from a private key
// function deriveAddressesFromPrivKey(privKey) {
//     // Public Key Coordinates calculated via Elliptic Curve Multiplication
//     const pubKeyCoordinates = ec.g.mul(privKey); // g = generator point

//     const x = pubKeyCoordinates.getX().toString('hex');
//     const y = pubKeyCoordinates.getY().toString('hex');

//     // Ethereum address derivation
//     const publicKey = x + y;
//     const hashOfPublicKey = keccak256(Buffer.from(publicKey, 'hex'));
//     const ethAddress = `0x${hashOfPublicKey.slice(-40)}`;

//     return { x, y, ethAddress };
// }

// // Convert each private key in your dataset to public key coordinates and Ethereum address
// const derivedData = btcData.map(item => {
//     try {
//         const { x, y, ethAddress } = deriveAddressesFromPrivKey(item.privkey);
//         return {
//             originalAddress: item.address,
//             derivedEthAddress: ethAddress,
//             pubKeyX: x,
//             pubKeyY: y,
//             satoshis: item.satoshis
//         };
//     } catch (error) {
//         console.error(`Error processing privkey: ${error.message}`);
//         return null;
//     }
// }).filter(item => item !== null); // Remove any null entries due to conversion errors

// // Write the derived data to a file
// fs.writeFileSync('../results/derivedData.json', JSON.stringify(derivedData, null, 2));

// console.log('Derived data written to derivedData.json');





const EC = require('elliptic').ec;
const crypto = require('crypto');
const keccak256 = require('js-sha3').keccak256;
const fs = require('fs');

// Initialize elliptic curve
const ec = new EC('secp256k1');

// Load the data
const btcData = require("../results/ConvertedData.json"); 

// Function to perform SHA256 hashing
function sha256(data) {
    return crypto.createHash('sha256').update(data).digest();
}

// Function to perform RIPEMD-160 hashing
function ripemd160(data) {
    return crypto.createHash('ripemd160').update(data).digest();
}

// Function to derive public key coordinates and Ethereum address from a private key
function deriveEthAddressesFromPrivKey(privKey) {
    const keyPair = ec.keyFromPrivate(privKey, 'hex');
    const pubKey = keyPair.getPublic();

    const x = pubKey.getX().toString(16, 64); // 64 hex characters
    const y = pubKey.getY().toString(16, 64); // 64 hex characters

    // Ethereum address derivation
    const ethAddress = '0x' + keccak256(Buffer.from(x + y, 'hex')).slice(-40);

    return { x, y, ethAddress };
}

// Function to derive a Bitcoin address (bytes20 format) from public key coordinates
function deriveBtcAddressBytes20FromPubKey(x, y, compressed = true) {
    let pubKey;
    if (compressed) {
        const prefix = (parseInt(y.slice(-1), 16) % 2 === 0) ? '02' : '03';
        pubKey = Buffer.from(prefix + x, 'hex');
    } else {
        pubKey = Buffer.from('04' + x + y, 'hex');
    }

    const pubKeyHash = ripemd160(sha256(pubKey));
    return pubKeyHash.toString('hex');
}

// Convert each private key in your dataset to public key coordinates, Ethereum address, and Bitcoin address (bytes20 format)
const derivedData = btcData.map(item => {
    try {
        const { x, y, ethAddress } = deriveEthAddressesFromPrivKey(item.privkey);
        const btcAddressBytes20 = deriveBtcAddressBytes20FromPubKey(x, y, true); // Assuming compressed public keys
        return {
            originalAddress: item.address,
            derivedEthAddress: ethAddress,
            derivedBtcAddressBytes20: btcAddressBytes20,
            pubKeyX: x,
            pubKeyY: y,
            satoshis: item.satoshis
        };
    } catch (error) {
        console.error(`Error processing privkey: ${error.message}`);
        return null;
    }
}).filter(item => item !== null);

// Write the derived data to a file
fs.writeFileSync('../results/derivedData.json', JSON.stringify(derivedData, null, 2));

console.log('Derived data written to derivedData.json');