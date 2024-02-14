const bitcoin = require('bitcoinjs-lib');

const originalAddress = '1Ay8vMC7R1UbyCCZRVULMV7iQpHSAbguJP';
const originalPublicKey = '03e4b3960362b8ea8cd141a3c47b1d1403c1f2636bcafdb565586412c71634f34f';

// Derive address from public key
const publicKeyBuffer = Buffer.from(originalPublicKey, 'hex');
const { address } = bitcoin.payments.p2pkh({ pubkey: publicKeyBuffer });

// Compare derived address with original address
if (address === originalAddress) {
    console.log('Public key matches the original Bitcoin address.');
} else {
    console.log('Public key does not match the original Bitcoin address.');
}
