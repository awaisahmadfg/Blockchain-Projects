const crypto = require('crypto');
const secp256k1 = require('secp256k1');
const ethUtil = require('ethereumjs-util');

function extractPublicKeyAndParams(message, address, signature) {

    // Step 1: Extract r, s, and v from the signature
  const signatureBuffer = Buffer.from(signature, 'base64');
  console.log("signatureBuffer: ", signatureBuffer);
  const r = signatureBuffer.slice(0, 32);
  const s = signatureBuffer.slice(32, 64);
  let v = (signatureBuffer[64] & 3)+27; // Add 27 for Ethereum compatibility
 
  console.log("R: ", "0x" + r.toString('hex'))
  console.log("S: ", "0x" + s.toString('hex'))
  console.log("V: ", v)
 
  // Step 2: Derive the public key from the message and signature
  const messageHash = crypto.createHash('sha256').update(message).digest();
  console.log("Message hash: ", "0x" + messageHash.toString('hex'))
  const recoveredPublicKey = ethUtil.ecrecover(messageHash, 27, r, s);
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


    const recoveredAddr = '0x' + ethUtil.pubToAddress(recoveredPublicKey).toString('hex');


// Example usage:
const messageToSign = "Second message";
const address = "1FM3KoBUqPpiRLP1A4E4uykkxMjxb2vT8f";
const signature = "H7vA4zvAHXwPP63PcDkXaOX/MHmZYS3OPBsUcXt50732QR72lDAS0T1UFioj4sg7HBY4+NybNGu+pY8oGIXsVQc=";
const { v, pubKeyX, pubKeyY } = extractPublicKeyAndParams(messageToSign, address, signature);
console.log("v:", v);
console.log("pubKeyX:", "0x" + pubKeyX);
console.log("pubKeyY:", "0x" + pubKeyY);
console.log("Recovered Address: ", recoveredAddr);


