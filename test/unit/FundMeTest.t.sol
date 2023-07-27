// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    DeployFundMe deployer;
    FundMe fundMe;
    address priceFeedAddress;

    uint256 private constant MINIMUM_USD = 5e18;
    address private FUNDER = makeAddr("funder");
    uint256 private constant STARTING_USER_BALANCE = 10 ether;
    uint256 private constant FUNDING_AMOUNT = 1 ether;

    function setUp() external {
        deployer = new DeployFundMe();
        (fundMe, priceFeedAddress) = deployer.run();
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

    function test__PriceFeedAddressIsCorrect() public {
        address response = fundMe.getPriceFeedAddress();
        assertEq(response, priceFeedAddress);
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

    modifier funded() {
        vm.prank(FUNDER);
        fundMe.fund{value: FUNDING_AMOUNT}();
        _;
    }

    function test_FundUpdatesArrayDSIfFundedCorrectly() public funded {
        address funderAddress = fundMe.getFunder(0);
        assertEq(funderAddress, FUNDER);
    }

    function test_FundUpdatesMappingDSIfFundedCorrectly() public funded {
        uint256 response = fundMe.getAddressToAmountFunded(FUNDER);
        assertEq(response, FUNDING_AMOUNT);
    }

    /////////////////////////////////////
    //////        Withdraw()      ///////
    /////////////////////////////////////
    function test_RevertsIfWithdrawNotCalledByOwner() public funded {
        vm.expectRevert(FundMe.FundMe__NOT_OWNER.selector);
        vm.prank(FUNDER);
        fundMe.withdraw();
    }

    function test_OwnerCanWithdrawIfFundedBySingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingFundMeBalance + startingOwnerBalance
        );
    }

    function test_OwnerCanWithdrawIfFundedByMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // address should be uint160
        uint160 startingFunderIndex = 1; // 0 is funded modifier
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //////////////
            // address user = makeAddr(address(i));
            // vm.deal(user, STARTING_USER_BALANCE);
            // vm.prank(user);
            //////////////

            // Instead of the above lines, hoax can be used
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: FUNDING_AMOUNT}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingFundMeBalance + startingOwnerBalance
        );
    }
}

// To run all the test in local env
// forge test

// To simulate a Test net env
// forge test --fork-url $SEPOLIA_RPC_URL
