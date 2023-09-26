// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TokenMint {
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
    event Minted(address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event ContractLocked(bool isLocked);

    constructor() {
        owner = msg.sender;
        isMintLocked = false;
    }

    modifier onlyOwner() {
        require(exAddress == owner, "Not the contract owner");
        _;
    }

    modifier notLocked() {
        require(!isMintLocked, "Contract is locked");
        _;
    }

    function mint(
        string memory _name,
        string memory _symbol,
        address mintContract,
        address transferContract
    ) public notLocked onlyOwner {
        require(transferContract != address(0), "Invalid address");

        name = _name;
        symbol = _symbol;
        decimals = 18; // You can adjust this value as needed
        totalSupply = 1000000000 * 10 ** uint256(decimals);
        owner = msg.sender;
        balanceOf[mintContract] = totalSupply;

        approve(transferContract, mintContract, totalSupply);
        transfer(transferContract, mintContract, totalSupply);

        emit Minted(transferContract, totalSupply);
    }

    function transfer(
        address to,
        address _owner,
        uint256 value
    ) internal notLocked returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[_owner] >= value, "Insufficient balance");
        require(allowance[_owner][to] >= value, "Allowance exceeded");

        balanceOf[_owner] -= value;
        balanceOf[to] += value;
        allowance[_owner][to] -= value;

        emit Transfer(_owner, to, value);
        return true;
    }

    function approve(
        address to,
        address _owner,
        uint256 value
    ) internal notLocked returns (bool) {
        require(to != address(0), "Invalid address");

        allowance[_owner][to] = value;
        emit Approval(_owner, to, value);
        return true;
    }

    function lockContract() external onlyOwner {
        isMintLocked = true;
        emit ContractLocked(true);
    }

    function unlockContract() external onlyOwner {
        isMintLocked = false;
        emit ContractLocked(false);
    }
}
