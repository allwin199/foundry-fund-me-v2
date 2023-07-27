// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    DeployFundMe deployer;
    FundMe fundMe;

    uint256 private constant MINIMUM_USD = 5e18;
    address private FUNDER = makeAddr("funder");
    uint256 private constant STARTING_USER_BALANCE = 10 ether;
    uint256 private constant FUNDING_AMOUNT = 1 ether;

    function setUp() external {
        deployer = new DeployFundMe();
        fundMe = deployer.run();
        vm.deal(FUNDER, STARTING_USER_BALANCE);
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
        vm.expectRevert(FundMe.FundMe__NOT_ENOUGH_ETH.selector);
        fundMe.fund();
    }

    modifier funder() {
        vm.prank(FUNDER);
        fundMe.fund{value: FUNDING_AMOUNT}();
        _;
    }

    function test_FundUpdatesArrayDSIfFundedCorrectly() public funder {
        address response = fundMe.getFunder(0);
        assertEq(response, FUNDER);
    }

    function test_FundUpdatesMappingDSIfFundedCorrectly() public funder {
        uint256 response = fundMe.getAddressToAmountFunded(FUNDER);
        assertEq(response, FUNDING_AMOUNT);
    }
}

// To run all the test in local env
// forge test

// To simulate a Test net env
// forge test --fork-url $SEPOLIA_RPC_URL
