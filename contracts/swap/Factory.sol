// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Exchange.sol";

contract Factory {
    //교환 이벤트(토큰 주소, 스왑 주소)
    event NewExchange(address indexed token, address indexed exchange);

    mapping(address => address) internal tokenToExchange;
    mapping(address => address) internal exchangeToToken;

    function createExchange(address token) external returns (address) {
        require(token != address(0), "Invalid token address");
        require(
            tokenToExchange[token] == address(0),
            "Exchange already exists"
        );

        Exchange exchange = new Exchange(token);
        tokenToExchange[token] = address(exchange);
        exchangeToToken[address(exchange)] = token;

        emit NewExchange(token, address(exchange));
        return address(exchange);
    }

    function getExchange(address token) external view returns (address) {
        return tokenToExchange[token];
    }

    function getToken(address exchange) external view returns (address) {
        return exchangeToToken[exchange];
    }
}
