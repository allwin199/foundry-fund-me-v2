// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    DeployFundMe deployer;
    FundMe fundMe;

    uint256 private constant MINIMUM_USD = 5e18;

    function setUp() external {
        deployer = new DeployFundMe();
        fundMe = deployer.run();
    }

    function test_MinimimUsdIsFive() public {
        uint256 fundMeMinUsd = fundMe.getMinimumUsd();
        assertEq(fundMeMinUsd, MINIMUM_USD);
    }

    function test_OwnerIsMsgSender() public {
        address owner = fundMe.getOwner();
        assertEq(owner, msg.sender);
    }

    function test_PriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        uint256 versionNum;
        if (block.chainid == 31337) {
            versionNum = 0;
        } else {
            versionNum = 4;
        }
        assertEq(version, versionNum);
    }

    /////////////////////////////////
    //////        Fund()      //////
    ////////////////////////////////
    function test_FundMeRevertsIfNotEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }
}

// To run all the test in local env
// forge test

// To simulate a Test net env
// forge test --fork-url $SEPOLIA_RPC_URL
