// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IExchange {
    function ethToTokenSwap(uint256 min_tokens, uint256 fee) external payable;

    function ethToTokenTransfer(
        uint256 min_tokens,
        address recipient,
        uint256 fee
    ) external payable;

    function tokenToEthSwap(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 fee
    ) external;

    function tokenToEthTransfer(
        uint256 tokens_sold,
        uint256 min_eth,
        address recipient,
        uint256 fee
    ) external;

    function tokenToTokenSwap(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        address recipient,
        address token_addr,
        uint256 fee
    ) external;

    function tokenToTokenTransfer(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        address recipient,
        address token_addr,
        uint256 fee
    ) external;

    function getOutputPrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve,
        uint256 fee
    ) external view returns (uint256);

    function getOutputPriceNoFee(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);

    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);

    function removeLiquidity(
        uint256 lpToken,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256);
}
