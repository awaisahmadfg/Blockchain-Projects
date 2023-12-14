const { Web3 } = require('web3');
const bitcoin = require('bitcoinjs-lib');
const EC = require('elliptic').ec;
const keccak256 = require('js-sha3').keccak256;

async function main() {
  try {
    // Initialize Web3
    const web3 = new Web3(new Web3.providers.HttpProvider('https://sepolia.infura.io/v3/49341042453a4cec93d53ac5d55d811e'));

    // Convert WIF private key to an Ethereum-compatible format
    const wifKey = '5K2wG73TRVguM8RkurRg4QfQioFqrNaMwMNusuh1iZyG4UtNfeo';
    const keyPair = bitcoin.ECPair.fromWIF(wifKey);
    const privateKeyBuffer = keyPair.privateKey;
    const privateKey = privateKeyBuffer.toString('hex');

    // Generate public key
    const ec = new EC('secp256k1');
    const key = ec.keyFromPrivate(privateKeyBuffer);
    const publicKey = key.getPublic();
    const publicKeyX = publicKey.getX().toString('hex');
    const publicKeyY = publicKey.getY().toString('hex');
    console.log("publicKeyX: ", "0x" + publicKeyX);
    console.log("publicKeyY: ", "0x" + publicKeyY);
    const address = '0x' + keccak256(Buffer.from(publicKeyX + publicKeyY, 'hex')).slice(64 - 40);

    // Sign a message
    const message = web3.utils.sha3('Some data to sign');
    const signature = web3.eth.accounts.sign(message, `0x${privateKey}`);

    console.log(`Public Key: ${publicKeyX}${publicKeyY}`);
    console.log(`Private Key: ${privateKey}`);
    console.log(`Address: ${address}`);
    console.log(`Message: ${message}`);
    console.log(`Signature: ${JSON.stringify(signature)}`);
  } catch (err) {
    console.error('Error:', err);
  }
}

main();
