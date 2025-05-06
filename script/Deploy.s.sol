// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Staking} from "../src/Staking.sol";
import {Script, console} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CustomERC721} from "../src/CustomERC721.sol";
import {CustomERC20} from "../src/CustomERC20.sol";
import {Staking} from "../src/Staking.sol";
import {Exchange} from "../src/Exchange.sol";

contract Deploy is Script {
    function run() external {
        uint256 fees = 0.01 ether;
        uint256 rewardRate = 1;
        uint256 tokenCap = 4;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        CustomERC20 token = new CustomERC20();
        CustomERC721 lnft = new CustomERC721(
            "NFT",
            "NFT",
            tokenCap,
            "ipfs://nfthash/"
        );
        Staking staking = new Staking(address(lnft), rewardRate, fees);
        Exchange exchange = new Exchange(
            address(staking),
            address(token),
            2 * fees
        );
        vm.stopBroadcast();

        console.log("---------------------");
        console.logAddress(address(token));
        console.logAddress(address(lnft));
        console.logAddress(address(staking));
        console.logAddress(address(exchange));
        console.log("---------------------");
    }
}
