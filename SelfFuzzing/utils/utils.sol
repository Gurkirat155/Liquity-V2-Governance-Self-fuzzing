// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IHevm {
    function  prank(address) external;
    function warp(uint256 newTimestamp) external;
}
