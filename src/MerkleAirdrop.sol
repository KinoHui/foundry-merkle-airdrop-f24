// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
    error MerkleAirdrop__InvailidSignature();

    ////////////////////////////
    //   State variables      //
    ////////////////////////////

    // list of addresses that can receive tokens
    // allow someone in the list to claim some tokens
    address[] claimers;
    mapping(address => bool) claimed;
    bytes32 private immutable i_merkleRoot;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");
    IERC20 private immutable i_airdropToken;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

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

    ////////////////////////////////////
    //   External / Public Functions  //
    ////////////////////////////////////

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        public
    {
        // check whether have claimed
        if (claimed[msg.sender] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // check signature is vailid
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvailidSignature();
        }

        // check whether this account is in merkletree
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__VerifyFailed();
        }

        claimed[msg.sender] = true;
        i_airdropToken.safeTransfer(account, amount);
        emit Claim(account, amount);
    }

    //////////////////////////////////////////
    //   Internal / Private View Functions  //
    //////////////////////////////////////////
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return (actualSigner == account);
    }

    /////////////////////////////////////////
    //   External / Public View Functions  //
    /////////////////////////////////////////

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function getAirdropToken() public view returns (IERC20) {
        return i_airdropToken;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return i_merkleRoot;
    }
}
