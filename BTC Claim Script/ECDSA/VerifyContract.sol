import "hardhat/console.sol";
pragma solidity ^0.8.0;

contract MSignatureVerifier {
    function verify(
        bytes32 hash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        require(v >= 27 && v <= 30, "MYNT: v invalid");

        address pubKeyEthAddr = pubKeyToEthAddress(pubKeyX, pubKeyY);
        
        console.log ("ecrecover(hash, v, r, s): ", ecrecover(hash, v, r, s));
        return ecrecover(hash, v, r, s) == pubKeyEthAddr;
    }


    function pubKeyToEthAddress(bytes32 pubKeyX, bytes32 pubKeyY) public pure returns (address)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(pubKeyX, pubKeyY)))));
    }

}
