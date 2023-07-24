// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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
    mapping(address funder => uint256 amountFunded) public addresToAmountFunded;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        uint256 ethPriceInUsd = (msg.value).getConversionRate();
        if (ethPriceInUsd < MINIMUM_USD) revert FundMe__NOT_ENOUGH_ETH();
        s_funders.push(msg.sender);
        addresToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            addresToAmountFunded[funder] = 0;
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
}
