// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 AMOUNT_TO_CLAIM = 25 ether;
    uint256 AMOUNT_TO_MINT = AMOUNT_TO_CLAIM * 4;

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        BagelToken bagelToken = new BagelToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(ROOT, IERC20(bagelToken));
        bagelToken.mint(bagelToken.owner(), AMOUNT_TO_MINT); // amount for four claimers
        IERC20(bagelToken).transfer(address(airdrop), AMOUNT_TO_MINT); // transfer tokens to the airdrop contract
        vm.stopBroadcast();
        return (airdrop, bagelToken);
    }

    function run() external {
        deployMerkleAirdrop();
    }
}
