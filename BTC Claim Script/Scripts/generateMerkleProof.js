const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs');
const btcData = require("../results/ConvertedData.json");

// Create leaves from BTC bytes20 addresses and satoshis
const leaves = btcData.map(data => keccak256(Buffer.concat([
    Buffer.from(data.bytes20Address.slice(2), 'hex'), 
    Buffer.from(data.satoshis.toString(16).padStart(64, '0'), 'hex')
])));

// Create the Merkle tree
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

// Get the Merkle root
const root = tree.getRoot().toString('hex');

// Create a proof for a specific dummy address and satoshis
const specificData = btcData[0];
const leaf = keccak256(Buffer.concat([
    Buffer.from(specificData.bytes20Address.slice(2), 'hex'), 
    Buffer.from(specificData.satoshis.toString(16).padStart(64, '0'), 'hex')
]));
const proof = tree.getProof(leaf).map(x => '0x' + x.data.toString('hex'));

// Prepare the data to be saved
const dataToSave = {
  root: '0x' + root,
  proof: proof
};

// Write the data to a file
fs.writeFileSync('../results/MerkleProofData.json', JSON.stringify(dataToSave, null, 2));

console.log('Merkle data written to MerkleProofData.json');
