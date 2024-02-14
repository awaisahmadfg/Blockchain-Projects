

const bitcoin = require('bitcoinjs-lib');

async function getPublicKeyFromWitness(txId) {
  // Dynamic import for node-fetch
  const fetch = (await import('node-fetch')).default;

  // Construct the URL for fetching the transaction data in hex format
  const url = `https://blockchain.info/rawtx/${txId}?format=hex`;

  try {
    // Fetch the transaction data
    const response = await fetch(url);
    const txHex = await response.text();

    // Parse the transaction hex into a Transaction object
    const tx = bitcoin.Transaction.fromHex(txHex);

    // Loop through the inputs to find the witness data
    for (const input of tx.ins) {
      if (input.witness.length > 0) {
        // Assuming the last element of the witness array is the public key
        const publicKeyHex = input.witness[input.witness.length - 1].toString('hex');

        // Return the public key in hex format
        return publicKeyHex;
      }
    }
  } catch (error) {
    console.error('Error fetching public key from witness:', error);
  }

  return null; // Return null if no public key found
}

// Replace 'transactionId' with the actual transaction ID
const transactionId = '026d5ea536d43c79820483739886db88641a8e43c521fea6cdf23d815de7cb7b';

getPublicKeyFromWitness(transactionId).then(publicKey => {
  if (publicKey) {
    console.log('Public Key from Witness:', publicKey);
  } else {
    console.log('Public key not found in the witness data for the given transaction ID');
  }
});
