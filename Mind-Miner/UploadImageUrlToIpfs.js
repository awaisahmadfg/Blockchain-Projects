const axios = require('axios');


  async uploadImageUrlToIpfs(imageUrl) {
    try {
      const response = await axios.get(imageUrl, { responseType: 'stream' });
      const urlParts = imageUrl.split('/');
      const defaultFileName = urlParts[urlParts.length - 1] || 'image_from_url';

      const options = {
        pinataMetadata: {
          name: defaultFileName,
        },
        pinataOptions: {
          cidVersion: 0,
        },
      };

      const ipfs = await this.pinata.pinFileToIPFS(response.data, options);

      return [`${PINATA_URL}/ipfs/${ipfs.IpfsHash}`];
    } catch (error) {
      const message = error.message || error.details;
      throw new Error(`Image upload error: ${message}`);
    }
  }
