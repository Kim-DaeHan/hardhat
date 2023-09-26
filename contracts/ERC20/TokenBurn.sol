// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TokenBurn {
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
    event Burned(address indexed from, uint256 value);
    event ContractLocked(bool isLocked);

    constructor() {
        owner = msg.sender;
        isTransferLocked = false;
    }

    modifier onlyOwner() {
        require(exAddress == owner, "Not the contract owner");
        _;
    }

    modifier notLocked() {
        require(!isBurnLocked, "Contract is locked");
        _;
    }

    function burn(address _owner, uint256 amount) public onlyOwner notLocked {
        require(balanceOf[_owner] >= amount, "Insufficient balance");

        totalSupply -= amount;
        balanceOf[_owner] -= amount;

        emit Transfer(_owner, address(0), amount);
        emit Burned(_owner, amount);
    }

    function lockContract() external onlyOwner {
        isBurnLocked = true;
        emit ContractLocked(true);
    }

    function unlockContract() external onlyOwner {
        isBurnLocked = false;
        emit ContractLocked(false);
    }
}
