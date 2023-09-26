// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TokenTransfer {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    address public exAddress;
    bool public isMintLocked;
    bool public isTransferLocked;
    bool public isBurnLocked;
    bool public isTimeLockLocked;

    mapping(bytes32 => TimelockItem) public timelockQueue;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    // 타임락 된 작업
    struct TimelockItem {
        address target; // 대상 스마트 계약 주소
        uint256 value; // 이더량 또는 값
        bytes data; // 호출 데이터
        uint256 eta; // 실행 가능한 시간 (Unix 타임스탬프)
        bool executed; // 작업이 이미 실행되었는지 여부
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
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
        uint256 value
    ) public notLocked returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[_owner] >= value, "Insufficient balance");

        balanceOf[_owner] -= value;
        balanceOf[to] += value;
        allowance[to][to] = value;

        emit Transfer(_owner, to, value);
        return true;
    }

    function transferFrom(
        address to,
        address from,
        address _owner,
        uint256 value
    ) public notLocked returns (bool) {
        require(from != address(0) && to != address(0), "Invalid addresses");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][_owner] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][_owner] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(
        address to,
        address from,
        uint256 value
    ) public notLocked returns (bool) {
        require(to != address(0), "Invalid address");

        allowance[from][to] = value;
        emit Approval(from, to, value);
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
