const { ethers } = require('ethers');

const provider = new ethers.providers.JsonRpcProvider('https://sepolia.infura.io/v3/789a100ae5ab48c9a378ab3d7e060e00'); // Replace with your provider URL

const address = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56'; // Replace with the address you want to check

async function getBalance() {
  try {
    const balance = await provider.getBalance(address);
    const balanceInEther = ethers.utils.formatEther(balance);
    console.log(`Balance of ${address}: ${balanceInEther} ETH`);
  } catch (error) {
    console.error('Error fetching balance:', error);
  }
}

getBalance();
