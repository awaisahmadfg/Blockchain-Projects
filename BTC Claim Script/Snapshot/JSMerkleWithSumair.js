
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs');
const { parser } = require('stream-json');
const { streamArray } = require('stream-json/streamers/StreamArray');
const BATCH_SIZE = 500000; // Increased batch size for efficiency

// Function to create a leaf node for the Merkle tree
function createLeaf(data) {
    if (!data || !data.bytes20Address || typeof data.bytes20Address !== 'string') {
        console.error('Invalid data or missing address:', data);
        return null;
    }

    return keccak256(Buffer.concat([
        Buffer.from(data.bytes20Address.slice(2), 'hex'),
        Buffer.from(data.satoshis.toString(16).padStart(64, '0'), 'hex')
    ]));
}

let leaves,leafCount, pipeline, leaf
// Function to process each file and add leaves to the Merkle Tree
async function processFile(fileName, tree) {
    return new Promise((resolve, reject) => {
        leaves = [];
        leafCount = 0;
        pipeline = fs.createReadStream(fileName)
            .pipe(parser())
            .pipe(streamArray());

        pipeline.on('data', data => {
            leaf = createLeaf(data.value);
            if (leaf) {
                leaves.push(leaf);
                if (leaves.length >= BATCH_SIZE) {
                    tree.addLeaves(leaves, false);
                    leaves.length = 0; // Clear the array
                    leafCount += BATCH_SIZE;
                    console.log(`Processed ${leafCount} leaves in ${fileName}`);
                    global.gc(); // Trigger garbage collection every 1000 leaves
                }
            }
        });

        pipeline.on('end', () => {
            if (leaves.length > 0) {
                tree.addLeaves(leaves, false);
                leafCount += leaves.length;
            }
            console.log(`Processing complete for file: ${fileName}`);
            resolve();
        });

        pipeline.on('error', error => {
            console.error(`Error processing file ${fileName}:`, error);
            reject(error);
        });
    });
}

// Function to create the Merkle tree from multiple files
async function createMerkleTree(fileNames) {
    const tree = new MerkleTree([], keccak256, { sortPairs: true });

    // Sequential processing of files
    for (const fileName of fileNames) {
        await processFile(fileName, tree);
    }

    tree.makeTree();
    return tree;
}

// Main function to execute the script
async function main() {
    const fileNames = [
        // List your file paths here
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot1Bytes20.json",
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot2Bytes20.json",
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot3Bytes20.json",
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot4Bytes20.json",
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot5Bytes20.json",
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot6Bytes20.json",
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot7Bytes20.json",
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot8Bytes20.json"
    ];

    const tree = await createMerkleTree(fileNames);
    const root = tree.getRoot().toString('hex');

    // Create a proof for the first leaf in the first file
    const firstFileData = JSON.parse(fs.readFileSync(fileNames[0]));
    const firstAddressData = firstFileData[0];
    const leafToProve = createLeaf(firstAddressData);
    const proof = tree.getProof(leafToProve).map(x => '0x' + x.data.toString('hex'));

    // Prepare the data to be saved
    const dataToSave = {
        root: '0x' + root,
        proof: proof
    };

    // Write the data to a file
    fs.writeFileSync('/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/results/MerkleProofData.json', JSON.stringify(dataToSave, null, 2));

    console.log('Merkle data written to MerkleProofData.json');
}

main().catch(error => console.error('An error occurred:', error));
