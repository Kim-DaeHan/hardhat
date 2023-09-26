// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Swap is Ownable {
    IERC721 public tokenA;
    IERC721 public tokenB;

    constructor(address _tokenAAddress, address _tokenBAddress) {
        tokenA = IERC721(_tokenAAddress);
        tokenB = IERC721(_tokenBAddress);
    }

    // ERC-721 토큰 A를 토큰 B와 교환하는 함수
    function swap(uint256 _tokenIdA, uint256 _tokenIdB) external {
        require(
            tokenA.ownerOf(_tokenIdA) == msg.sender,
            "You do not own token A"
        );
        require(
            tokenB.ownerOf(_tokenIdB) == msg.sender,
            "You do not own token B"
        );

        // ERC-721 토큰 A를 소유자에서 컨트랙트로 이전
        tokenA.safeTransferFrom(msg.sender, address(this), _tokenIdA);

        // ERC-721 토큰 B를 컨트랙트에서 소유자로 이전
        tokenB.safeTransferFrom(address(this), msg.sender, _tokenIdB);

        // 교환 결과 이벤트를 발생시킵니다.
        emit Swap(msg.sender, _tokenIdA, _tokenIdB);
    }

    // 스왑 결과 이벤트
    event Swap(address indexed user, uint256 tokenIdA, uint256 tokenIdB);
}
