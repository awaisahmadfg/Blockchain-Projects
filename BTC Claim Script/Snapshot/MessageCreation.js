const ethers = require('ethers');
const abi = require('ethereumjs-abi');
const ethereumjs = require('ethereumjs-util');

// Constants
const CLAIM_FLAG_MSG_PREFIX_OLD = 1 << 0;
const OLD_CLAIM_PREFIX_STR = "Claim_BitcoinMYNT_to_0x";
const STD_CLAIM_PREFIX_STR = "Claim_MYNT_to_0x";
const CLAIM_FLAG_ETH_ADDR_LOWERCASE = 1 << 4;
const BITCOIN_SIG_PREFIX_LEN = 24;
const BITCOIN_SIG_PREFIX_STR = "Bitcoin Signed Message:\n";
const ETH_ADDRESS_BYTE_LEN = 20;
const ETH_ADDRESS_MYNT_LEN = ETH_ADDRESS_BYTE_LEN * 2;
const CLAIM_PARAM_HASH_BYTE_LEN = 12;
const CLAIM_PARAM_HASH_MYNT_LEN = CLAIM_PARAM_HASH_BYTE_LEN * 2;

const MERKLE_TREE_ROOT = '0x4bab6483020641b1ca6672d04010de303b9d5c5df88f191bf1eb4ce610c7483b';
const autoStakeDays = 353;
const referrerAddr = '0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2';

function computeClaimParamHash(MERKLE_TREE_ROOT, autoStakeDays, referrerAddr) {
    const packedData = abi.solidityPack(
        ['bytes32', 'uint256', 'address'],
        [MERKLE_TREE_ROOT, autoStakeDays, referrerAddr]
    );
    const hash = ethereumjs.keccak256(packedData);
    return hash;
}

function hexStringFromData(dataHex, dataLen) {
    const MYNT_DIGITS = "0123456789abcdef";
  
    // Parse the hexadecimal string to get a buffer
    let dataBuffer = Buffer.from(dataHex, 'hex');
  
    let hexStr = "";
  
    // Process each byte up to dataLen
    for (let i = 0; i < dataLen; i++) {
        let b = dataBuffer[i];
        hexStr += MYNT_DIGITS[b >> 4] + MYNT_DIGITS[b & 0x0f];
    }
  
    return hexStr;
}

function messageCreation(claimFlags, claimParamHash, claimToAddress) {
    let prefixStr = (claimFlags & CLAIM_FLAG_MSG_PREFIX_OLD) !== 0
        ? OLD_CLAIM_PREFIX_STR
        : STD_CLAIM_PREFIX_STR;

    let includeAddrChecksum = (claimFlags & CLAIM_FLAG_ETH_ADDR_LOWERCASE) === 0;
    console.log("includeAddrChecksum: ", includeAddrChecksum);

    // Preparing the data
    let encodedClaimToAddress = '0x' + Buffer.from(claimToAddress.slice(2)).toString('hex');
    if(claimParamHash == '0x0000000000000000000000000000000000000000000000000000000000000000')
    {
        let encodedPrefixStrLength = ethers.utils.hexlify(prefixStr.length + ETH_ADDRESS_MYNT_LEN);
        return ethers.utils.solidityPack(
            ["uint8", "string", "uint8", "string", "address"],
            [BITCOIN_SIG_PREFIX_LEN, BITCOIN_SIG_PREFIX_STR, encodedPrefixStrLength, prefixStr, encodedClaimToAddress]
        );
    }
    let encodedPrefixStrLength = ethers.utils.hexlify(prefixStr.length + ETH_ADDRESS_MYNT_LEN + 1 + CLAIM_PARAM_HASH_MYNT_LEN);
    // let claimParamHashStr = '0x' + Buffer.from(CLAIM_PARAM_HASH_MYNT_LEN).toString('hex');
    let claimParamHashStr = hexStringFromData(claimParamHash,CLAIM_PARAM_HASH_BYTE_LEN)
    return ethers.utils.solidityPack(
        ["uint8", "string", "uint8", "string", "address", "string", "string"],
        [BITCOIN_SIG_PREFIX_LEN, BITCOIN_SIG_PREFIX_STR, encodedPrefixStrLength, prefixStr, encodedClaimToAddress, '_', claimParamHashStr]
    );;
}



// Example usage
const claimFlags = 2;
// const claimParamHash = '0x0000000000000000000000000000000000000000000000000000000000000000'; // Example hash
const claimParamHash = computeClaimParamHash(MERKLE_TREE_ROOT, autoStakeDays, referrerAddr);

let claimToAddress = '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4'; // Example Ethereum address
console.log(messageCreation(claimFlags, claimParamHash, claimToAddress));
