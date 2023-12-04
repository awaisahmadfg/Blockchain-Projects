
const { ec } = require('elliptic');
const wif = require('wif');
const keccak256 = require('keccak256');
const crypto = require('crypto');

const secp256k1 = new ec('secp256k1');

function pubKeyToEthAddress(pubKeyX, pubKeyY) {
  const pubKey = Buffer.concat([Buffer.from(pubKeyX.slice(2), 'hex'), Buffer.from(pubKeyY.slice(2), 'hex')]);
  const hash = keccak256(pubKey);
  const address = `0x${Buffer.from(hash).subarray(-20).toString('hex')}`;
  return toChecksumAddress(address);
}

// Constants
const CLAIM_FLAG_MSG_PREFIX_OLD = 1 << 0;
const OLD_CLAIM_PREFIX_STR = "Claim_BitcoinMYNT_to_0x";
const STD_CLAIM_PREFIX_STR = "Claim_MYNT_to_0x";
const CLAIM_FLAG_ETH_ADDR_LOWERCASE = 1 << 4;
const ETH_ADDRESS_MYNT_LEN = 40; // 20 bytes * 2
const MYNT_DIGITS = "0123456789abcdef";
const ETH_ADDRESS_BYTE_LEN = 20;
const BITCOIN_SIG_PREFIX_LEN = 24;
const BITCOIN_SIG_PREFIX_STR = "Bitcoin Signed Message:\n";
const CLAIM_PARAM_HASH_MYNT_LEN = 24; // 12 bytes * 2

function toChecksumAddress(address) {
    address = address.toLowerCase().replace('0x','');
    let hash = keccak256(address).toString('hex');
    let ret = '0x';

    for (let i = 0; i < address.length; i++) {
        ret += parseInt(hash[i], 16) >= 8 ? address[i].toUpperCase() : address[i];
    }

    return ret;
}

function addressStringCreate(addr, includeAddrChecksum) {
  let addrStr = Buffer.alloc(ETH_ADDRESS_BYTE_LEN);
  hexStringFromData(addrStr, Buffer.from(addr.slice(2), 'hex'), ETH_ADDRESS_BYTE_LEN);

  if (includeAddrChecksum) {
      let addrStrHash = keccak256(addrStr);

      for (let i = 0; i < ETH_ADDRESS_BYTE_LEN; i++) {
          addressStringChecksumChar(addrStr, i * 2, parseInt(addrStrHash[i], 16));
      }
  }

  return addrStr;
}



function hexStringFromData(hexStr, data, dataLen) {
    for (let i = 0; i < dataLen; i++) {
        let b = data[i];
        hexStr[i * 2] = MYNT_DIGITS.charCodeAt(b >> 4);
        hexStr[i * 2 + 1] = MYNT_DIGITS.charCodeAt(b & 0x0f);
    }
}

function addressStringChecksumChar(addrStr, offset, hashNybble) {
    let ch = addrStr[offset];

    if (ch >= 97 && hashNybble >= 8) { // 'a' in ASCII is 97
        addrStr[offset] = ch ^ 0x20;
    }
}

function sha256(data) {
    return crypto.createHash('sha256').update(data).digest();
}

function hash256(data) {
    return Buffer.from(sha256(sha256(data)));
}

function constructClaimMessage(claimToAddr, claimParamHash, claimFlags) {
  let prefixStr = (claimFlags & CLAIM_FLAG_MSG_PREFIX_OLD) !== 0 ? OLD_CLAIM_PREFIX_STR : STD_CLAIM_PREFIX_STR;
  let includeAddrChecksum = (claimFlags & CLAIM_FLAG_ETH_ADDR_LOWERCASE) === 0;
  let addrStr = addressStringCreate(claimToAddr, includeAddrChecksum);
  let claimParamHashStr = Buffer.alloc(CLAIM_PARAM_HASH_MYNT_LEN / 2); // Adjusted length

  hexStringFromData(claimParamHashStr, Buffer.from(claimParamHash.slice(2), 'hex'), 32);

  return Buffer.concat([
      Buffer.from([BITCOIN_SIG_PREFIX_LEN]),
      Buffer.from(BITCOIN_SIG_PREFIX_STR, 'utf-8'),
      Buffer.from([prefixStr.length + ETH_ADDRESS_MYNT_LEN + 1 + CLAIM_PARAM_HASH_MYNT_LEN]),
      Buffer.from(prefixStr, 'utf-8'),
      addrStr,
      Buffer.from('_'),
      claimParamHashStr
  ]);
}


function signMessage(privateKey, message) {
    const keyPair = secp256k1.keyFromPrivate(privateKey);
    const msgHash = keccak256(message);
    const signature = keyPair.sign(msgHash);
    
    let r = signature.r.toString(16).padStart(64, '0');
    let s = signature.s.toString(16).padStart(64, '0');

    return { r: '0x' + r, s: '0x' + s };
}

const merkleRoot = '0x7271576eef3d9f58b83cfdb07b0442f6590b05c604455c7b01587955378bfe7b';     
const autoStakeDays = '351';    
const referrerAddr = '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4';   
const claimFlags = 2;       

// function constructClaimParamHash(merkleRoot, autoStakeDays, referrerAddr) {
//     return '0x' + keccak256(Buffer.from(merkleRoot.slice(2) + autoStakeDays.toString(16).padStart(64, '0') + referrerAddr.slice(2), 'hex')).toString('hex');
// }

function constructClaimParamHash(merkleRoot, autoStakeDays, referrerAddr) {
  // Convert autoStakeDays to a 32-byte buffer (equivalent to uint256)
  const autoStakeDaysBuffer = Buffer.alloc(32);
  autoStakeDaysBuffer.writeUInt32BE(autoStakeDays, 28);

  // Combine the buffers for merkleRoot, autoStakeDays, and referrerAddr
  const combinedBuffer = Buffer.concat([
      Buffer.from(merkleRoot.slice(2), 'hex'),  // Remove the '0x' prefix
      autoStakeDaysBuffer,
      Buffer.from(referrerAddr.slice(2), 'hex') // Remove the '0x' prefix
  ]);

  // Hash the combined buffer
  return '0x' + keccak256(combinedBuffer).toString('hex');
}


const dataset = [
  {
    "derivedEthAddress": "0x2fc714b053c52a1139425431d2ec78fafa617375",
    "derivedBtcAddressBytes20": "0xaa400c0c23384b4fef55450f8cbf8aae0d42f2cd",
    "pubKeyX": "0x14761fb962dd7f3974072e2f7eca6e414013c7ab25cbae2c6649403fe8325f75",
    "pubKeyY": "0xda010d68f5b9b7c1c5bf38e277619932224a382a7b3499fa87cf0ca46ac70850",
    "satoshis": 893486,
    "privkey": "5K2wG73TRVguM8RkurRg4QfQioFqrNaMwMNusuh1iZyG4UtNfeo"
  },
  {
    "derivedEthAddress": "0x09da8a5f4338d5f2f97d65f08ead57a5bccf7cc9",
    "derivedBtcAddressBytes20": "0x23c6e5157e6618e058b7287c9943a1c071aa2e87",
    "pubKeyX": "0x11d7b1a053523bdc5cdde500b7889f0b5928d666609b7e7c54d101045d94a2ff",
    "pubKeyY": "0x47eb69f7576c6f6405dd3608f30a12722e3f26e16b41b67da6842d6ea34773f9",
    "satoshis": 936286078201,
    "privkey": "KxmfLEaA1g94VkHLnFgqpUhNxxDMWmfmMD1XVLAZiYUwPgzkpWMN"
  }
];

dataset.forEach(entry => {

  const claimParamHash = constructClaimParamHash(merkleRoot, autoStakeDays, referrerAddr);

  const privateKeyBuffer = wif.decode(entry.privkey).privateKey;
  const derivedEthAddress = pubKeyToEthAddress(entry.pubKeyX, entry.pubKeyY);

  const claimMessage = constructClaimMessage(derivedEthAddress, claimParamHash, claimFlags);
  const { r, s } = signMessage(privateKeyBuffer, claimMessage);

  console.log(`Claim Param Hash: ${claimParamHash}`);
  console.log(`Derived Eth Address: ${derivedEthAddress}`);
  console.log(`Claim Message: ${claimMessage.toString('hex')}`);
  console.log(`Signature r: ${r}`);
  console.log(`Signature s: ${s}`);
  console.log('-----------------------------');
});

