// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UniswapLikeExchange is ReentrancyGuard {
  // 토큰 A와 토큰 B의 ERC-20 인터페이스
  IERC20 public tokenA;
  IERC20 public tokenB;

  // 유동성 풀에 저장된 토큰 A와 토큰 B의 총량
  uint256 public totalA;
  uint256 public totalB;

  // 커브 상수 k
  uint256 public k;

  // 유동성 풀을 추가하는 이벤트
  event AddLiquidity(
    address indexed provider,
    uint256 amountA,
    uint256 amountB
  );

  // 유동성 풀을 철수하는 이벤트
  event RemoveLiquidity(
    address indexed provider,
    uint256 amountA,
    uint256 amountB
  );

  // 토큰을 교환하는 이벤트
  event Swap(address indexed trader, uint256 amountIn, uint256 amountOut);

  // 생성자: 토큰 A와 토큰 B의 주소를 받아오고 초기화
  constructor(address _tokenA, address _tokenB) {
    tokenA = IERC20(_tokenA);
    tokenB = IERC20(_tokenB);
  }

  // 유동성 풀 추가하는 함수
  function addLiquidity(
    uint256 amountA,
    uint256 amountB
  ) external nonReentrant {
    // 유효한 토큰 양인지 확인
    require(amountA > 0 && amountB > 0, "Invalid amounts");

    // 사용자로부터 토큰을 전송 받음
    tokenA.transferFrom(msg.sender, address(this), amountA);
    tokenB.transferFrom(msg.sender, address(this), amountB);

    // 유동성 풀의 총량 업데이트
    totalA += amountA;
    totalB += amountB;

    // 커브 상수 k를 업데이트
    k = totalA * totalB;

    // 유동성 풀 추가 이벤트 발생
    emit AddLiquidity(msg.sender, amountA, amountB);
  }

  // 유동성 풀을 철수하는 함수
  function removeLiquidity(uint256 liquidity) external nonReentrant {
    // 유효한 유동성 값인지 확인
    require(liquidity > 0, "Invalid liquidity");

    // 유동성 풀에서 토큰 A와 토큰 B의 양 계산
    uint256 amountA = (liquidity * totalA) / (totalA + totalB);
    uint256 amountB = (liquidity * totalB) / (totalA + totalB);

    // 유동성 풀의 총량 업데이트
    totalA -= amountA;
    totalB -= amountB;

    // 사용자에게 토큰을 전송
    tokenA.transfer(msg.sender, amountA);
    tokenB.transfer(msg.sender, amountB);

    // 유동성 풀 철수 이벤트 발생
    emit RemoveLiquidity(msg.sender, amountA, amountB);
  }

  //  x * y = k 형태의 커브를 따르는 CPMM 로직
  function calculateSwapAmount(
    uint256 amountA
  ) internal view returns (uint256) {
    // 현재 풀의 잔액 (x와 y)
    uint256 x = totalA;
    uint256 y = totalB;

    // 새로 들어올 양에 대한 y' 계산
    uint256 new_x = x + amountA;
    uint256 new_y = k / new_x;

    // 트레이드 후 제거될 y의 양 계산
    uint256 amountB = y - new_y;

    return amountB;
  }

  // 토큰을 교환하는 함수
  function swapA(uint256 amountA) external nonReentrant {
    // 유효한 토큰 양인지 확인
    require(amountA > 0, "Invalid amount");
    require(tokenA.balanceOf(msg.sender) >= amountA, "Insufficient balance");

    // 교환에 사용할 토큰 B의 양 계산
    uint256 amountB = calculateSwapAmount(amountA);

    // Reentrancy 방어를 위해 교환 전에 토큰을 먼저 전송합니다.
    tokenA.transferFrom(msg.sender, address(this), amountA);
    tokenB.transfer(msg.sender, amountB);

    // 유동성 풀의 총량 업데이트
    totalA += amountA;
    totalB -= amountB;

    // 커브 상수 k를 업데이트
    k = totalA * totalB;

    // 교환 이벤트 발생
    emit Swap(msg.sender, amountA, amountB);
  }
}
