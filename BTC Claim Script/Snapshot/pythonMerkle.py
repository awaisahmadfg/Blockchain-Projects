!pip install merkletools pysha3

import json
from merkletools import MerkleTools
import sha3

BATCH_SIZE = 1000  # Reduced batch size for memory efficiency

# Function to create a leaf node for the Merkle tree
def create_leaf(data):
    if not data or 'bytes20Address' not in data or not isinstance(data['bytes20Address'], str):
        print('Invalid data or missing address:', data)
        return None

    address = bytes.fromhex(data['bytes20Address'][2:])  # Remove '0x' from the address
    satoshis = bytes.fromhex(format(data['satoshis'], 'x').zfill(64))
    combined_data = address + satoshis
    return sha3.keccak_256(combined_data).hexdigest()

# Function to process each file and add leaves to the Merkle Tree
def process_file(file_name, tree):
    with open(file_name, 'r') as file:
        data_stream = json.load(file)

        for item in data_stream:
            leaf = create_leaf(item)
            if leaf:
                tree.add_leaf(leaf, False)

        print(f"Processed {len(data_stream)} leaves in {file_name}")

# Function to create the Merkle tree from multiple files
def create_merkle_tree(file_names):
    tree = MerkleTools()

    # Sequential processing of files
    for file_name in file_names:
        process_file(file_name, tree)

    tree.make_tree()
    return tree

# Main function to execute the script
def main():
    file_names = [
        # List your file paths here
        "/kaggle/input/snapshotbytes20/Snapshot1Bytes20.json",
        "/kaggle/input/snapshotbytes20/Snapshot2Bytes20.json",
        "/kaggle/input/snapshotbytes20/Snapshot3Bytes20.json",
        "/kaggle/input/snapshotbytes20/Snapshot4Bytes20.json",
        "/kaggle/input/snapshotbytes20/Snapshot5Bytes20.json",
        "/kaggle/input/snapshotbytes20/Snapshot6Bytes20.json",
        "/kaggle/input/snapshotbytes20/Snapshot7Bytes20.json",
        "/kaggle/input/snapshotbytes20/Snapshot8Bytes20.json"
    ]

    tree = create_merkle_tree(file_names)
    root = tree.get_merkle_root()

    # Create a proof for the first leaf in the first file
    with open(file_names[0], 'r') as file:
        first_file_data = json.load(file)
    first_address_data = first_file_data[0]
    leaf_to_prove = create_leaf(first_address_data)
    proof = tree.get_proof(leaf_to_prove)

    # Prepare the data to be saved
    data_to_save = {
        'root': root,
        'proof': [{'position': p['position'], 'data': p['data'].hex()} for p in proof]
    }

    # Write the data to a file
    with open('/kaggle/working/MerkleProofData.json', 'w') as file:
        json.dump(data_to_save, file, indent=2)

    print('Merkle data written to MerkleProofData.json')

if __name__ == "__main__":
    main()
