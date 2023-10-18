// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFactory {
    event NewExchange(address indexed token, address indexed exchange);

    function createExchange(address token) external returns (address);

    function getExchange(address token) external view returns (address);

    function getToken(address exchange) external view returns (address);
}
