// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MerkleAirdrop is EIP712 {
    ///////////
    // Types //
    ///////////
    using SafeERC20 for IERC20;

    ///////////////////
    //   Errors      //
    ///////////////////
    error MerkleAirdrop__VerifyFailed();
    error MerkleAirdrop__AlreadyClaimed();

    ////////////////////////////
    //   State variables      //
    ////////////////////////////

    // list of addresses that can receive tokens
    // allow someone in the list to claim some tokens
    address[] claimers;
    mapping(address => bool) claimed;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    ///////////////////
    //   Events      //
    ///////////////////

    event Claim(address indexed account, uint256 indexed amount);

    ///////////////////
    //   Functions   //
    ///////////////////

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("Merkle Airdrop", "1.0.0") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    ///////////////////////////////////
    //   External / Public Functions  //
    ///////////////////////////////////

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) public {
        if (claimed[msg.sender] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__VerifyFailed();
        }
        claimed[msg.sender] = true;
        i_airdropToken.safeTransfer(account, amount);
        emit Claim(account, amount);
    }

    //////////////////////////////////////////
    //   Internal / Private View Functions  //
    //////////////////////////////////////////

    /////////////////////////////////////////
    //   External / Public View Functions  //
    /////////////////////////////////////////

    function getAirdropToken() public view returns (IERC20) {
        return i_airdropToken;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return i_merkleRoot;
    }
}
