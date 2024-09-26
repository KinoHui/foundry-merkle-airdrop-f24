// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    BagelToken token;
    MerkleAirdrop merkleAirdrop;
    bytes32 ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32 PROOF_ONE = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] USER_PROOF = [PROOF_ONE, PROOF_TWO];
    uint256 AMOUNT_TO_CLAIM = 25 ether;
    uint256 AMOUNT_TO_MINT = AMOUNT_TO_CLAIM * 4;
    address user;
    address gasPayer;
    uint256 userPraivateKey;
    bytes private SIGNATURE =
        hex"04608c1ff2caa30822e2928da3a169298044176ddd633834d714f8b067702f6b5e815d1261abcd37e793b27980ccd7a9899d24ab96ff781da09b2464d2ed1de21b";

    function setUp() external {
        if (!isZkSyncChain()) {
            //chain verification
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new BagelToken();
            merkleAirdrop = new MerkleAirdrop(ROOT, token);
            token.mint(token.owner(), AMOUNT_TO_MINT);
            token.transfer(address(merkleAirdrop), AMOUNT_TO_MINT);
        }
        (user, userPraivateKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function testCanClaim() public {
        uint256 startingBalence = token.balanceOf(user);
        console.log("SIGNATURE's length: ", SIGNATURE.length);

        // vm.sign() 不需要vm.prank()
        bytes32 messageHash = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPraivateKey, messageHash);

        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, USER_PROOF, v, r, s);

        uint256 endindBalance = token.balanceOf(user);

        console.log("Ending user balance: ", endindBalance);
        assertEq(endindBalance - startingBalence, AMOUNT_TO_CLAIM);
    }
}
