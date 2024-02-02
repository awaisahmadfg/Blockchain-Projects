const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs');
const { parser } = require('stream-json');
const { streamArray } = require('stream-json/streamers/StreamArray');
const JSONStream = require('JSONStream')
const BATCH_SIZE = 500000; // Increased batch size for efficiency


// Function to create a leaf node for the Merkle tree
// function createLeaf(data) {
//     if (!data || !data.bytes20Address || typeof data.bytes20Address !== 'string') {
//         console.error('Invalid data or missing address:', data);
//         return null;
//     }

//     return keccak256(Buffer.concat([
//         Buffer.from(data.bytes20Address.slice(2), 'hex'),
//         Buffer.from(data.satoshis.toString(16).padStart(64, '0'), 'hex')
//     ]));
// }
function createLeaf(data) {
    if (!data || !data.bytes20Address || typeof data.bytes20Address !== 'string') {
        console.error('Invalid data or missing address:', data);
        return null;
    }

    // Convert btcAddr and rawSatoshis to Buffer
    const btcAddrBuffer = Buffer.from(data.bytes20Address.slice(2), 'hex');
    const rawSatoshisBuffer = Buffer.from(data.satoshis.toString(16).padStart(64, '0'), 'hex');

    // Ensure both buffers are 32 bytes long
    const btcAddrBuffer32 = Buffer.concat([btcAddrBuffer, Buffer.alloc(32 - btcAddrBuffer.length)]);
    const rawSatoshisBuffer32 = Buffer.concat([rawSatoshisBuffer, Buffer.alloc(32 - rawSatoshisBuffer.length)]);

    // Perform bitwise OR operation
    const merkleLeafBuffer = Buffer.alloc(32);
    for (let i = 0; i < merkleLeafBuffer.length; i++) {
        merkleLeafBuffer[i] = btcAddrBuffer32[i] | rawSatoshisBuffer32[i];
    }

    return merkleLeafBuffer;
}


// let leaves,leafCount, pipeline, leaf
// Function to process each file and add leaves to the Merkle Tree
const filePath = "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/results/dummyDataMerkleProofLeavesOfFile1.json";
// let leaves = [];
async function processFile(fileName/*, tree*/) {
    return new Promise((resolve, reject) => {
        // const leaves = [];
        let leafCount = 0;
        const pipeline = fs.createReadStream(fileName)
            .pipe(parser())
            .pipe(streamArray());

        pipeline.on('data', data => {
            const leaf = createLeaf(data.value);
            if (leaf) {
                // leaves.push(leaf);
                // if (leaves.length >= BATCH_SIZE) {
                    // tree.addLeaves(leaf, false);
                    const leafData = { leaf: leaf.toString('hex') };
                    const leafJson = JSON.stringify(leafData) + '\n';
                    fs.appendFileSync(filePath, leafJson);
                    // leaves.length = 0; // Clear the array
                    // leafCount += BATCH_SIZE;
                    // console.log(`Processed ${leafCount} leaves in ${fileName}`);
                    // global.gc(); // Trigger garbage collectiochunksn every 1000 leaves
                // }
            }
        });

        pipeline.on('end', () => {
            // if (leaves.length > 0) {
            //     tree.addLeaves(leaves, false);
            //     leafCount += leaves.length;
            // }
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

    // const tree = new MerkleTree([], keccak256, { sortPairs: true});

    // Sequential processing of files
    for (const fileName of fileNames) {
        await processFile(fileName, /*tree*/);
    }
    const fileStream = fs.createReadStream(filePath, {encoding: 'utf-8'});
    const jsonStream = JSONStream.parse('*');
    let chunks = [];
    let i = 0; 
    return new Promise((resolve, reject) => {
        fileStream.pipe(jsonStream);
        jsonStream.on('data', (jsonObject)=>{
            chunks.push(jsonObject);
            // console.log("Leaf : ", jsonObject)
            // tree.addLeaves(jsonObject, false);
            console.log("i: ",i++);
        });
        jsonStream.on('end',()=>{
            console.log("Chunks: ", chunks);
            console.log("Array type : ", typeof(chunks));
            console.log("Instance type : ", typeof(chunks[0]));
            console.log("First instance type : ", chunks[0]);
            console.log("Array length : ", chunks.length);
            // const tree = new MerkleTree(chunks, keccak256, { sortPairs: true, size: chunks.length });
            console.log("Adding Leave to the tree....");
            // tree.addLeaves(chunks, false);
            const tree = new MerkleTree(chunks, keccak256, { sortPairs: true});

            console.log("Tree root: ", tree.getRoot());
            // console.log("Leaf proof: ", tree.getProof(chunks[0]));
            resolve(tree);
        })
    })
  
   
    // tree.makeTree();
    // console.log("Tree Root: ", tree.getRoot());
    // console.log("Tree Root: ", tree.getRoot().toString());
    // return tree;
}

// Main function to execute the script
async function main() {
    const fileNames = [
        // List your file paths here
        "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/dummyData.json",
        // "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot2Bytes20.json",
        // "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot3Bytes20.json",
        // "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot4Bytes20.json",
        // "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot5Bytes20.json",
        // "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot6Bytes20.json",
        // "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot7Bytes20.json",
        // "/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/dataset/Snapshot8Bytes20.json"
    ];

    const tree = await createMerkleTree(fileNames);
    const root = tree.getRoot().toString('hex');

    // Create a proof for the first leaf in the first file
    const firstFileData = JSON.parse(fs.readFileSync(fileNames[0]));
    const firstAddressData = firstFileData[0];
    const leafToProve = createLeaf(firstAddressData);
    const proof = tree.getProof(leafToProve).map(x => '0x' + x.data.toString('hex'));
    console.log("First index proof: ", proof);
    // Prepare the data to be saved
    const dataToSave = {
        root: '0x' + root,
        proof: proof
    };

    // Write the data to a file

    fs.writeFileSync('/home/ubuntu/Documents/Myntist/mynt-token/mynt-token/scripts/Snapshot/results/dummyDataProofRoot.json', JSON.stringify(dataToSave, null, 2));
    console.log('Merkle data written to dummyDataProofRoot.json');
}

main().catch(error => console.error('An error occurred:', error));
