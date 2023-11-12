// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./StakeableToken.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract UTXOClaimValidation is StakeableToken {

    /**
     * @dev PUBLIC FACING: Derive an Ethereum address from an ECDSA public key
     * @param pubKeyX First  half of uncompressed ECDSA public key
     * @param pubKeyY Second half of uncompressed ECDSA public key
     * @return Derived Eth address
     */
    function pubKeyToEthAddress(bytes32 pubKeyX, bytes32 pubKeyY) public pure returns (address)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(pubKeyX, pubKeyY)))));
    }

    function _addressStringChecksumChar(bytes memory addrStr, uint256 offset, uint8 hashNybble) private pure
    {
        bytes1 ch = addrStr[offset];

        if (ch >= "a" && hashNybble >= 8) {
            addrStr[offset] = ch ^ 0x20;
        }
    }

    /**
     * @dev sha256(sha256(data))
     * @param data Data to be hashed
     * @return 32-byte hash
     */
    function _hash256(bytes memory data) private pure returns (bytes32)
    {
        return sha256(abi.encodePacked(sha256(data)));
    }

    /**
     * @dev ripemd160(sha256(data))
     * @param data Data to be hashed
     * @return 20-byte hash
     */
    function _hash160(bytes memory data) private pure returns (bytes20)
    {
        return ripemd160(abi.encodePacked(sha256(data)));
    }
}