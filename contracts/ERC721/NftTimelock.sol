// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Timelock {
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

    // 타임락 이벤트
    event NewOwner(address indexed newOwner);
    event NewTimelock(
        bytes32 indexed id,
        address indexed target,
        uint256 value,
        bytes data,
        uint256 eta
    );
    event ContractLocked(bool isLocked);

    modifier onlyOwner() {
        require(exAddress == owner, "Not the contract owner");
        _;
    }

    modifier notLocked() {
        require(!isTimeLockLocked, "Contract is locked");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function setOwner(address newOwner) public onlyOwner notLocked {
        owner = newOwner;
        emit NewOwner(newOwner);
    }

    function queueTransaction(
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) public onlyOwner notLocked returns (bytes32) {
        require(eta > block.timestamp, "Timelock eta must be in the future");
        bytes32 id = keccak256(abi.encode(target, value, data, eta));
        timelockQueue[id] = TimelockItem(target, value, data, eta, false);
        emit NewTimelock(id, target, value, data, eta);
        return id;
    }

    function executeTransaction(
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) public onlyOwner notLocked {
        bytes32 id = keccak256(abi.encode(target, value, data, eta));
        require(
            timelockQueue[id].eta <= block.timestamp,
            "Timelock eta not reached"
        );
        require(
            !timelockQueue[id].executed,
            "Timelock transaction already executed"
        );
        timelockQueue[id].executed = true;
        (bool success, ) = target.call{value: value}(data);
        require(success, "Timelock transaction execution failed");
    }

    function cancelTransaction(
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) public onlyOwner notLocked {
        bytes32 id = keccak256(abi.encode(target, value, data, eta));
        require(!timelockQueue[id].executed, "Cannot cancel executed timelock");
        timelockQueue[id].executed = true;
    }

    function lockContract() external onlyOwner {
        isTimeLockLocked = true;
        emit ContractLocked(true);
    }

    function unlockContract() external onlyOwner {
        isTimeLockLocked = false;
        emit ContractLocked(false);
    }
}
