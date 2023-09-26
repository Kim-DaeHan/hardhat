// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ERC20Proxy {
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

    event ReceivedEther(address indexed sender, uint256 amount);
    event Whitelisted(address indexed account, bool status);
    event ExAddress(address indexed account, bool status);

    constructor() {
        owner = msg.sender;
        whitelisted[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Address is not whitelisted");
        _;
    }

    function addToWhitelist(address account) public onlyOwner {
        whitelisted[account] = true;
        emit Whitelisted(account, true);
    }

    function removeFromWhitelist(address account) public onlyOwner {
        whitelisted[account] = false;
        emit Whitelisted(account, false);
    }

    function setExAddress(address _exAddress) public {
        require(_exAddress != address(0), "Invalid address");
        exAddress = _exAddress;
        emit ExAddress(exAddress, true);
    }

    function removeExAddress() public {
        exAddress = address(0);
        emit ExAddress(exAddress, false);
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    function mint(
        string memory _name,
        string memory _symbol,
        address mintContract,
        address transferContract
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = mintContract.delegatecall(
            abi.encodeWithSignature(
                "mint(string,string,address,address)",
                _name,
                _symbol,
                mintContract,
                transferContract
            )
        );
        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false
        require(success, "Transfer failed");

        return true;
    }

    function approve(
        address transferContract,
        address to,
        uint256 value
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = transferContract.delegatecall(
            abi.encodeWithSignature(
                "approve(address,address,uint256)",
                to,
                msg.sender,
                value
            )
        );

        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false입니다.
        require(success, "Transfer failed");

        return true;
    }

    function transfer(
        address to,
        address transferContract,
        uint256 value
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = transferContract.delegatecall(
            abi.encodeWithSignature(
                "transfer(address,address,uint256)",
                to,
                transferContract,
                value
            )
        );

        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false입니다.
        require(success, "Transfer failed");

        return true;
    }

    function transferFrom(
        address transferContract,
        address to,
        address from,
        uint256 value
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = transferContract.delegatecall(
            abi.encodeWithSignature(
                "transferFrom(address,address,address,uint256)",
                to,
                from,
                msg.sender,
                value
            )
        );

        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false입니다.
        require(success, "Transfer failed");

        return true;
    }

    function burn(
        address burnContract,
        uint256 amount
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = burnContract.delegatecall(
            abi.encodeWithSignature("burn(address,uint256)", msg.sender, amount)
        );
        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false
        require(success, "Transfer failed");

        return true;
    }

    function queueTransaction(
        address timeLockContract,
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = timeLockContract.delegatecall(
            abi.encodeWithSignature(
                "queueTransaction(address,uint256,bytes,uint256)",
                target,
                value,
                data,
                eta
            )
        );
        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false
        require(success, "Transfer failed");

        return true;
    }

    function executeTransaction(
        address timeLockContract,
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = timeLockContract.delegatecall(
            abi.encodeWithSignature(
                "executeTransaction(address,uint256,bytes,uint256)",
                target,
                value,
                data,
                eta
            )
        );
        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false
        require(success, "Transfer failed");

        return true;
    }

    function cancelTransaction(
        address timeLockContract,
        address target,
        uint256 value,
        bytes memory data,
        uint256 eta
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = timeLockContract.delegatecall(
            abi.encodeWithSignature(
                "cancelTransaction(address,uint256,bytes,uint256)",
                target,
                value,
                data,
                eta
            )
        );
        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false
        require(success, "Transfer failed");

        return true;
    }

    function lockContract(
        address contractAddress
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = contractAddress.delegatecall(
            abi.encodeWithSignature("lockContract()")
        );
        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false
        require(success, "Transfer failed");

        return true;
    }

    function unlockContract(
        address contractAddress
    ) external onlyWhitelisted returns (bool) {
        (bool success, ) = contractAddress.delegatecall(
            abi.encodeWithSignature("unlockContract()")
        );
        // 호출이 성공하면 success가 true이고, 그렇지 않으면 false
        require(success, "Transfer failed");

        return true;
    }
}
