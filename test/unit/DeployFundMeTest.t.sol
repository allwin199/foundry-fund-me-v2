// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract DeployFundMeTest is Test {
    DeployFundMe deployer;
    FundMe fundMe;
    address priceFeedAddress;

    modifier DeployContract() {
        deployer = new DeployFundMe();
        (fundMe, priceFeedAddress) = deployer.run();
        _;
    }

    function test_FundMeIsDeployed() public DeployContract {
        assert(address(fundMe) != address(0));
    }
}
