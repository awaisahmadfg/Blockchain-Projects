const crypto = require('crypto');
const secp256k1 = require('secp256k1');
const ethUtil = require('ethereumjs-util');
const bitcoin = require('bitcoinjs-lib');
const {ECPairFactory} = require('ecpair');
const tinysecp = require('tiny-secp256k1');
const ECPair = ECPairFactory(tinysecp);
const bs58 = require('bs58');

function extractPublicKeyAndParams(message, address, signature) {
  // Step 1: Extract r, s, and v from the signature
  const signatureBuffer = Buffer.from(signature, 'base64');
  console.log("signatureBuffer: ", signatureBuffer);
  const r = signatureBuffer.slice(0, 32);
  const s = signatureBuffer.slice(32, 64);
  let v = (signatureBuffer[64] & 3)+27; // Add 27 for Ethereum compatibility
  console.log("R: ", r.toString('hex'))
  console.log("S: ", s.toString('hex'))
  console.log("V: ", v)
  // Step 2: Derive the public key from the message and signature
  // const messageHash = crypto.createHash('sha256').update(message).digest();
  let messageHash = bitcoin.crypto.sha256(message);
  messageHash = bitcoin.crypto.sha256(messageHash);
  console.log("Message hash: ",messageHash.toString('hex'))
  const recoveredPublicKey = ethUtil.ecrecover(messageHash, 27, r, s);
  console.log("Public to address: ", ethUtil.Address.fromPublicKey(recoveredPublicKey).toString());
  const derBuffer = Buffer.concat([
    Buffer.from([0x04]), // Type byte for compressed public keys
    Buffer.from(recoveredPublicKey, 'hex')
]);
const btcKeyPair = ECPair.fromPublicKey(derBuffer);
// const btcAddress = bitcoin.payments.p2sh({
//   redeem: bitcoin.payments.p2wpkh({
//     pubkey: btcKeyPair.publicKey,
//     network: bitcoin.networks.bitcoin
//   }),
//   network: bitcoin.networks.bitcoin
// }).address;
const btcAddress = bitcoin.payments.p2pkh({ pubkey: btcKeyPair.publicKey });

  console.log("Public to address bitcoin: ", btcAddress.address);
  const decoded = bs58.decode(btcAddress.address);
  let addressHash = decoded.slice(1, 21);
  addressHash = Buffer.from(addressHash, 'utf-8')
  console.log("Public to address bitcoin addressHash: ", addressHash.toString('hex'));

  console.log("Recovered public key: ", recoveredPublicKey.toString('hex'))
//   const publicKeyBuffer = publicKeyConvert(recoveredPublicKey, false);
const publicKeyBuffer = recoveredPublicKey.toString('hex');
  // Step 3: Split the public key into pubKeyX and pubKeyY components
  console.log("Length: ", publicKeyBuffer.length)
  const pubKeyX = publicKeyBuffer.slice(0, 64);
  const pubKeyY = publicKeyBuffer.slice(64, 128);


  return {
    v: v,
    pubKeyX: pubKeyX.toString('hex'),
    pubKeyY: pubKeyY.toString('hex'),
  };
}

// Example usage:
const messageToSign = "Claim_MYNT_to_0xE8404FBD9154E8Cb3812D57f6ab01F428DC28fb2";//"Claim_MYNT_to_0x";
const address = "bc1q753pt8dgur98fsdhz3rmrf4zpqd09gs8lhkv8p";
const signature = "HzmSoIr2Km23UXwJ1l7snDL9XKd5soZ158FokTC9JyARNGP9pzBuLDPIWbWAnc+XsKhfw0sTSLGSPiPgs76ePYI=";//"Hy5IdOVrbxQYgQoN5j4KPNh3we52s1NuVAIUGLS2G+4AW/CASE+B9OPiJzcBZlEIxCFrj4BYEWZ0gh92W/JJBI=";

const { v, pubKeyX, pubKeyY } = extractPublicKeyAndParams(messageToSign, address, signature);

console.log("v:", v);
console.log("pubKeyX:", pubKeyX);
console.log("pubKeyY:", pubKeyY);
