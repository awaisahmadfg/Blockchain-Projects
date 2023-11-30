const keccak256 = require("keccak256");
const { MerkleTree } = require("merkletreejs");
const fs = require('fs');

const btcData = require('../dataset/data.json');

// Create leaves of the Merkle tree and keep track of the elements
const leaves = [];
const elements = [];

// Run for each element in the json file
btcData.forEach(item => {
    const leaf = keccak256(item.address + item.satoshis);
    leaves.push(leaf);
    elements.push(item.address + item.satoshis);
});

// Create the Merkle tree
const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });

// Prepare the data to be saved
const treeData = {
    root: merkleTree.getHexRoot(),
    elements: elements
};

// Write the data to a file
fs.writeFileSync("../results/MerkleTreeInfo.json", JSON.stringify(treeData, null, 4));

console.log(`Merkle Tree data written to MerkleTreeInfo.json`);