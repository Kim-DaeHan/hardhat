// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ERC725 컨트랙트를 import
import "@erc725/smart-contracts/contracts/ERC725.sol";

contract MyContract is ERC725 {
    constructor(address initialOwner) ERC725(initialOwner) {}

    // 데이터를 저장하는 함수
    function setDIDDocument(
        bytes32 key,
        string memory value
    ) public payable virtual onlyOwner {
        // string 형태의 DID 문서를 bytes로 변환
        bytes memory didBytes = bytes(value);

        // 데이터를 저장하기 위해 ERC725 컨트랙트의 _setData 함수를 호출
        _setData(key, didBytes);

        // 데이터 변경 이벤트를 발생시킴
        emit DataChanged(key, didBytes);
    }

    // 데이터를 조회하는 함수
    function getDIDDocument(
        bytes32 key
    ) public view virtual returns (string memory) {
        bytes memory didBytes = _getData(key);

        // bytes 형태의 데이터를 string으로 변환
        string memory didDocument = string(didBytes);

        return didDocument;
    }
}
