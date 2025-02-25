// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

contract P2PTrade {
  address public owner;
  uint256 public feePercent; // Fee percentage (e.g., 1 for 1%)

  struct Trade {
    address maker;
    address baseToken;
    uint256 baseTokenAmount;
    address quoteToken;
    uint256 quoteTokenAmount;
    bool isActive;
  }

  mapping(bytes32 => Trade) public trades;

  event TradeCreated(
    bytes32 tradeId,
    address indexed maker,
    address baseToken,
    uint256 baseTokenAmount,
    address quoteToken,
    uint256 quoteTokenAmount
  );
  event TradeCompleted(
    bytes32 tradeId,
    address indexed taker,
    address baseToken,
    uint256 baseTokenAmount,
    address quoteToken,
    uint256 quoteTokenAmount
  );
  event TradeCancelled(bytes32 tradeId, address indexed maker);
  event FeeTransferred(address indexed feeRecipient, uint256 feeAmount);
  event TokensWithdrawn(
    address indexed token,
    address indexed to,
    uint256 amount
  );

  constructor(uint256 _feePercent) {
    owner = msg.sender;
    feePercent = _feePercent;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can perform this action");
    _;
  }

  // Trade 생성 함수
  function createTrade(
    address baseToken,
    uint256 baseTokenAmount,
    address quoteToken,
    uint256 quoteTokenAmount
  ) external {
    require(baseTokenAmount > 0, "Base token amount must be greater than zero");
    require(
      quoteTokenAmount > 0,
      "Quote token amount must be greater than zero"
    );

    // baseToken을 컨트랙트 실행 address가 컨트랙트로 전송
    // Transfer Base Token from the maker to the contract
    IERC20 baseTokenContract = IERC20(baseToken);
    require(
      baseTokenContract.transferFrom(
        msg.sender,
        address(this),
        baseTokenAmount
      ),
      "Base token transfer to contract failed"
    );

    // param값 기반으로 tradeId 값 생성
    bytes32 tradeId = keccak256(
      abi.encodePacked(
        msg.sender,
        baseToken,
        baseTokenAmount,
        quoteToken,
        quoteTokenAmount,
        block.timestamp
      )
    );

    // Trade 생성
    trades[tradeId] = Trade({
      maker: msg.sender,
      baseToken: baseToken,
      baseTokenAmount: baseTokenAmount,
      quoteToken: quoteToken,
      quoteTokenAmount: quoteTokenAmount,
      isActive: true
    });

    emit TradeCreated(
      tradeId,
      msg.sender,
      baseToken,
      baseTokenAmount,
      quoteToken,
      quoteTokenAmount
    );
  }

  // Trade 완료 함수
  function completeTrade(bytes32 tradeId, uint256 quoteTokenAmount) external {
    // Trade가 취소안됐는지 확인
    Trade storage trade = trades[tradeId];
    require(trade.isActive, "Trade is not active");
    require(
      quoteTokenAmount >= trade.quoteTokenAmount,
      "Insufficient payment amount"
    );

    // feePercent를 통한 fee 계산
    uint256 feeAmount = (trade.quoteTokenAmount * feePercent) / 100;
    // fee를 제외한 실제 전송량 계산
    uint256 netQuoteTokenAmount = trade.quoteTokenAmount - feeAmount;

    // Trade를 완료시키는 사용자가 거래 생성자에게 토큰 전송
    // Transfer Quote Token from taker to maker and owner
    IERC20 quoteTokenContract = IERC20(trade.quoteToken);
    require(
      quoteTokenContract.transferFrom(
        msg.sender,
        trade.maker,
        netQuoteTokenAmount
      ),
      "Quote token transfer to maker failed"
    );

    // 컨트랙트 소유자에게 수수료 전송
    require(
      quoteTokenContract.transferFrom(msg.sender, owner, feeAmount),
      "Quote token transfer of fee failed"
    );

    // 컨트랙트에 존재하는 base token을 컨트랙트 실행자에게 전송
    // Transfer Base Token from contract to taker
    IERC20 baseTokenContract = IERC20(trade.baseToken);
    require(
      baseTokenContract.transfer(msg.sender, trade.baseTokenAmount),
      "Base token transfer to taker failed"
    );

    // Trade 비활성화
    trade.isActive = false;

    emit TradeCompleted(
      tradeId,
      msg.sender,
      trade.baseToken,
      trade.baseTokenAmount,
      trade.quoteToken,
      trade.quoteTokenAmount
    );
    emit FeeTransferred(owner, feeAmount);
  }

  // Trade 비활성화
  function cancelTrade(bytes32 tradeId) external {
    Trade storage trade = trades[tradeId];
    // Trade 활성상태 체크
    require(trade.isActive, "Trade is not active");
    // Trade 생성자랑 컨트랙트 실행자 같은지 체크
    require(msg.sender == trade.maker, "Only the maker can cancel the trade");

    // Trade 생성자에게 토큰 환불
    // Transfer Base Token back to maker
    IERC20 baseTokenContract = IERC20(trade.baseToken);
    require(
      baseTokenContract.transfer(trade.maker, trade.baseTokenAmount),
      "Base token refund to maker failed"
    );

    // Trade 비활성화
    trade.isActive = false;

    emit TradeCancelled(tradeId, trade.maker);
  }

  // 수수료 비율 set 함수
  function setFeePercent(uint256 _feePercent) external onlyOwner {
    feePercent = _feePercent;
  }

  // 토큰 인출 함수
  function withdrawTokens(
    address tokenAddress,
    uint256 amount,
    address to
  ) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    // 요청된 양의 토큰을 인출
    require(token.transfer(to, amount), "Token withdrawal failed.");
    emit TokensWithdrawn(tokenAddress, to, amount);
  }
}
