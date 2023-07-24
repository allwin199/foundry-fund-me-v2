// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";

contract DeployFundMe is Script {
    FundMe fundMe;

    function run() external returns (FundMe) {
        vm.startBroadcast();
        fundMe = new FundMe(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        vm.stopBroadcast();

        return fundMe;
    }
}
