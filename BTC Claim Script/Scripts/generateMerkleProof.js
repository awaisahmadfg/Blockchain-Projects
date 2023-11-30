const fs = require('fs');
const keccak256 = require("keccak256");
const { MerkleTree } = require("merkletreejs");
const btcData = require('../dataset/data.json');

// Function to convert data to a hex string
function toHexString(byteArray) {
    return Array.from(byteArray, function(byte) {
        return ('0' + (byte & 0xFF).toString(16)).slice(-2);
    }).join('');
}

// Create leaves of the Merkle tree and the elements array
const leaves = [];
const elements = [];

btcData.forEach(item => {
    const data = item.address + item.satoshis;
    const leaf = keccak256(data);
    leaves.push(leaf);
    elements.push(toHexString(leaf));
});

// Create the Merkle tree
const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });

// Prepare the data to be saved
const treeData = {
    root: merkleTree.getHexRoot(),
    elements: elements
};

// Write the data to a file
fs.writeFileSync('../results/merkleTreeAndProofData.json', JSON.stringify(treeData, null, 4));

console.log("Merkle Tree data written to merkleTreeAndProofData.json");
