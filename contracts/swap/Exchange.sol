// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IExchange.sol";
import "./interfaces/IFactory.sol";

contract Exchange is ERC20 {
    //이더구매 이벤트
    //토큰 구매 이벤트
    //유동성 공급 이벤트
    //유동성 제거 이벤트
    event EthPurchase(
        address indexed buyer,
        uint256 indexed eth_sold,
        uint256 indexed tokens_bought
    );
    event TokenPurchase(
        address indexed buyer,
        uint256 indexed tokens_sold,
        uint256 indexed eth_bought
    );
    event AddLiquidity(
        address indexed provider,
        uint256 indexed eth_amount,
        uint256 indexed token_amount
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256 indexed eth_amount,
        uint256 indexed token_amount
    );

    IERC20 token;
    IFactory factory;

    //초기화
    constructor(address _token) ERC20("choi", "CH") {
        token = IERC20(_token);
        factory = IFactory(msg.sender);
    }

    //유동성 공급 함수
    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256) {
        require(
            deadline >= block.timestamp && min_liquidity > 0 && max_tokens > 0
        );
        require(msg.value > 0);
        uint256 total_liquidity = totalSupply();
        if (total_liquidity > 0) {
            require(msg.value >= min_liquidity);
            uint256 eth_reserve = address(this).balance - msg.value;
            uint256 token_reserve = token.balanceOf(address(this));
            uint256 token_amount = (msg.value * token_reserve) / eth_reserve;
            uint256 liquidity_minted = (msg.value * total_liquidity) /
                eth_reserve;
            _mint(msg.sender, liquidity_minted);
            emit AddLiquidity(msg.sender, msg.value, token_amount);
            emit Transfer(address(0), msg.sender, liquidity_minted);
            return liquidity_minted;
        } else {
            require(
                address(token) != address(0) &&
                    address(factory) != address(0) &&
                    msg.value >= min_liquidity
            );
            uint256 token_amount = max_tokens;
            uint256 initial_liquidity = address(this).balance;
            _mint(msg.sender, initial_liquidity);

            emit Transfer(address(0), msg.sender, initial_liquidity);
            emit AddLiquidity(msg.sender, initial_liquidity, token_amount);
            return initial_liquidity;
        }
    }

    //유동성 제거 함수
    function removeLiquidity(
        uint256 lpToken,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256) {
        require(
            deadline >= block.timestamp &&
                lpToken > 0 &&
                min_eth > 0 &&
                min_tokens > 0
        );
        uint256 total_liquidity = totalSupply();
        require(total_liquidity > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_amount = (lpToken * address(this).balance) /
            total_liquidity;
        uint256 token_amount = (lpToken * token_reserve) / total_liquidity;
        require(eth_amount >= min_eth && token_amount >= min_tokens);
        _burn(msg.sender, lpToken);
        payable(msg.sender).transfer(eth_amount);
        token.transfer(msg.sender, token_amount);
        emit RemoveLiquidity(msg.sender, eth_amount, token_amount);
        emit Transfer(msg.sender, address(0), lpToken);
        return (eth_amount, token_amount);
    }

    //이더를 토큰과 스왑하는 함수
    function ethToTokenSwap(
        uint256 min_tokens,
        uint256 fee
    ) external payable returns (uint256) {
        return ethToTokenTransfer(min_tokens, msg.sender, fee);
    }

    function ethToTokenTransfer(
        uint256 min_tokens,
        address recipient,
        uint256 fee
    ) public payable returns (uint256) {
        require(msg.value > 0 && min_tokens > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = getOutputPrice(
            msg.value,
            address(this).balance - msg.value,
            token_reserve,
            fee
        );
        require(tokens_bought >= min_tokens && tokens_bought <= token_reserve);
        require(token.transfer(recipient, tokens_bought));
        emit TokenPurchase(msg.sender, msg.value, tokens_bought);
        return tokens_bought;
    }

    //토큰을 이더와 스왑하는 함수
    function tokenToEthSwap(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 fee
    ) external returns (uint256) {
        return tokenToEthTransfer(tokens_sold, min_eth, msg.sender, fee);
    }

    function tokenToEthTransfer(
        uint256 tokens_sold,
        uint256 min_eth,
        address recipient,
        uint256 fee
    ) public returns (uint256) {
        require(tokens_sold > 0 && min_eth > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_bought = getOutputPrice(
            tokens_sold,
            token_reserve,
            address(this).balance,
            fee
        );
        require(eth_bought >= min_eth && eth_bought <= address(this).balance);
        require(token.transferFrom(msg.sender, address(this), tokens_sold));
        payable(recipient).transfer(eth_bought);
        emit EthPurchase(msg.sender, tokens_sold, eth_bought);
        return eth_bought;
    }

    //토큰을 토큰과 스왑하는 함수
    function tokenToTokenSwap(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        address recipient,
        address token_addr,
        uint256 fee
    ) public {
        tokenToTokenTransfer(
            tokens_sold,
            min_tokens_bought,
            min_eth_bought,
            recipient,
            token_addr,
            fee
        );
    }

    function tokenToTokenTransfer(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        address recipient,
        address token_addr,
        uint256 fee
    ) public {
        require(tokens_sold > 0 && min_tokens_bought > 0 && min_eth_bought > 0);
        require(token_addr != address(token) && token_addr != address(this));
        require(factory.getExchange(token_addr) != address(0));
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_bought = getOutputPrice(
            tokens_sold,
            token_reserve,
            address(this).balance,
            fee
        );
        require(eth_bought >= min_eth_bought);
        require(
            token.transferFrom(msg.sender, address(this), tokens_sold),
            "failed to transfer tokens into exchange"
        );
        address toTokenExchangeAddress = factory.getExchange(token_addr);
        IExchange(toTokenExchangeAddress).ethToTokenTransfer{value: eth_bought}(
            min_eth_bought,
            recipient,
            fee
        );
    }

    //수수료를 포함해서 인출하는 토큰의 양을 계산하는 함수
    function getOutputPrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve,
        uint256 fee
    ) public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0);
        uint256 input_amount_with_fee = input_amount * fee;
        uint256 numerator = input_amount_with_fee * output_reserve;
        uint256 denominator = (input_reserve * 10000) + input_amount_with_fee;
        return numerator / denominator;
    }

    //수수료 없이 인출하는 토큰의 양을 계산하는 함수
    function getOutputPriceNoFee(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0);
        uint256 numerator = input_amount * output_reserve;
        uint256 denominator = input_reserve;
        return numerator / denominator;
    }
}
