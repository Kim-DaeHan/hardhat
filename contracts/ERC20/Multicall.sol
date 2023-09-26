// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Multicall {
    function aggregate(
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success, "Multicall: Call failed");
            results[i] = result;
        }
    }
}
