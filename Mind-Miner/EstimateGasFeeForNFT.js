export const estimateGasForNft = async (tokenURI: string, isConfirmed: boolean) => {
  try {
    const gasEstimate = await nftContract.estimateGas.mintNFT(tokenURI);

    const gasEstimateGwei = ethers.utils.formatUnits(gasEstimate, 'gwei');

    console.log(`Estimated gas in Gwei: ${gasEstimateGwei}`);

    const gasPrice = await provider.getGasPrice();
    
    const gasFee = gasEstimate.mul(gasPrice);
    const gasFeeEther = ethers.utils.formatUnits(gasFee, 'ether');

    console.log(`Estimated gas fee for the above tx in Ether: ${gasFeeEther} ether`);

    return {gasFeeEther: `${gasFeeEther} ether`, isConfirmed};
  } catch (error) {
    console.error('Error estimating gas:', error);
    throw error;
  }
};
