// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// similar to wallets, contracts can hold funds as well
// To receive fund, we have to make the function as payable

// cutom errors
error FundMe__NOT_OWNER();
error FundMe__WITHDRAW_FAILED();
error FundMe__NOT_ENOUGH_ETH();

contract FundMe {
    address internal immutable i_owner;

    using PriceConverter for uint256;
    // we are attaching PriceConverter library to all uin256
    // now all uint256 will have access to PriceConverter library

    uint256 public constant MINIMUM_USD = 5 * 1e18;
    // since priceInUsd will have 18 deciamls, we also need minimum usd to have 18 decimals;

    address[] public s_funders;
    mapping(address funder => uint256 amountFunded)
        public s_addresToAmountFunded;

    AggregatorV3Interface private s_priceFeed;

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        uint256 ethPriceInUsd = (msg.value).getConversionRate(s_priceFeed);
        if (ethPriceInUsd < MINIMUM_USD) revert FundMe__NOT_ENOUGH_ETH();
        s_funders.push(msg.sender);
        s_addresToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        address[] memory existingFunders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < existingFunders.length;
            funderIndex++
        ) {
            address funder = existingFunders[funderIndex];
            s_addresToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        if (!sent) revert FundMe__WITHDRAW_FAILED();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NOT_OWNER();
        _;
    }

    /**
     * View / Pure functions(Getters)
     */
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getAddressToAmountFunded(
        address _fundingAddress
    ) external view returns (uint256) {
        return s_addresToAmountFunded[_fundingAddress];
    }

    function getFunder(uint256 _index) external view returns (address) {
        return s_funders[_index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getMinimumUsd() external pure returns (uint256) {
        return MINIMUM_USD;
    }

    function getPriceFeedAddress() external view returns (address) {
        return address(s_priceFeed);
    }
}
