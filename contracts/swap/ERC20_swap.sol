// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Swap is Ownable {
    IERC20 public token;

    // ERC-20 스왑 이벤트
    event Swap(
        address indexed user,
        address indexed recipient,
        uint256 amount,
        address indexed otherTokenAddress
    );

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // ERC-20 스왑 로직: ERC-20 토큰을 다른 ERC-20 토큰과 스왑
    function swap(
        uint256 _amount,
        address _recipient,
        address _otherTokenAddress
    ) external {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        IERC20 otherToken = IERC20(_otherTokenAddress);
        require(otherToken.transfer(_recipient, _amount), "Transfer failed");

        // 스왑 결과 이벤트를 발생시킵니다.
        emit Swap(msg.sender, _recipient, _amount, _otherTokenAddress);
    }
}
