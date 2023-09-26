// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract NftTransfer {
    address public owner;
    address public exAddress;
    bool public isMintLocked;
    bool public isTransferLocked;
    bool public isBurnLocked;
    bool public isTimeLockLocked;

    mapping(bytes32 => TimelockItem) public timelockQueue;
    mapping(address => bool) public whitelisted;
    mapping(uint256 => TokenData) public tokenData;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // 타임락 된 작업
    struct TimelockItem {
        address target; // 대상 스마트 계약 주소
        uint256 value; // 이더량 또는 값
        bytes data; // 호출 데이터
        uint256 eta; // 실행 가능한 시간 (Unix 타임스탬프)
        bool executed; // 작업이 이미 실행되었는지 여부
    }

    struct TokenData {
        string name;
        string symbol;
        uint256 decimals;
        string description;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Minted(address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event ContractLocked(bool isLocked);

    constructor() {
        owner = msg.sender;
        isTransferLocked = false;
    }

    modifier onlyOwner() {
        require(exAddress == owner, "Only owner can call this function");
        _;
    }

    modifier notLocked() {
        require(!isTransferLocked, "Contract is locked");
        _;
    }

    function transfer(
        address to,
        address _owner,
        uint256 tokenId
    ) public notLocked returns (bool) {
        address ownerAddress = ownerOf[tokenId];
        require(ownerAddress != address(0), "Token does not exist");
        require(ownerAddress == _owner, "Not authorized");
        require(to != address(0), "Invalid address");

        ownerOf[tokenId] = to;
        balanceOf[ownerAddress]--;
        balanceOf[to]++;

        emit Transfer(ownerAddress, to, tokenId);
        return true;
    }

    function transferFrom(
        address to,
        address from,
        uint256 tokenId
    ) public notLocked returns (bool) {
        address ownerAddress = ownerOf[tokenId];
        require(ownerAddress != address(0), "Token does not exist");
        require(
            ownerAddress == from || allowance[ownerAddress][from] >= tokenId,
            "Not authorized"
        );
        require(to != address(0), "Invalid address");

        ownerOf[tokenId] = to;
        balanceOf[ownerAddress]--;
        balanceOf[to]++;

        emit Transfer(ownerAddress, to, tokenId);
        return true;
    }

    function approve(
        address to,
        address _owner,
        uint256 tokenId
    ) public notLocked returns (bool) {
        address ownerAddress = ownerOf[tokenId];
        require(ownerAddress != address(0), "Token does not exist");
        require(_owner == ownerAddress, "Not authorized");

        allowance[ownerAddress][to] = tokenId;

        emit Approval(ownerAddress, to, tokenId);
        return true;
    }

    function lockContract() external onlyOwner {
        isTransferLocked = true;
        emit ContractLocked(true);
    }

    function unlockContract() external onlyOwner {
        isTransferLocked = false;
        emit ContractLocked(false);
    }
}
