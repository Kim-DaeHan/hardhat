// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract LoadBalancer {
    address[] public proxyAddresses;
    address public owner;
    bool public isLocked;

    event AddressAdded(address indexed addr);
    event AddressRemoved(address indexed addr);
    event ContractLocked(bool isLocked);

    constructor() {
        owner = msg.sender;
        isLocked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier notLocked() {
        require(!isLocked, "Contract is locked");
        _;
    }

    function lockContract() external onlyOwner {
        isLocked = true;
        emit ContractLocked(true);
    }

    function unlockContract() external onlyOwner {
        isLocked = false;
        emit ContractLocked(false);
    }

    function addAddress(address addr) external onlyOwner notLocked {
        require(addr != address(0), "Invalid address");
        require(!isAddressStored(addr), "Address is already stored");
        proxyAddresses.push(addr);
        emit AddressAdded(addr);
    }

    function removeAddress(address addr) external onlyOwner notLocked {
        require(addr != address(0), "Invalid address");
        require(isAddressStored(addr), "Address is not stored");
        for (uint256 i = 0; i < proxyAddresses.length; i++) {
            if (proxyAddresses[i] == addr) {
                proxyAddresses[i] = proxyAddresses[proxyAddresses.length - 1];
                proxyAddresses.pop();
                emit AddressRemoved(addr);
                break;
            }
        }
    }

    function isAddressStored(
        address addr
    ) public view onlyOwner notLocked returns (bool) {
        for (uint256 i = 0; i < proxyAddresses.length; i++) {
            if (proxyAddresses[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function getStoredAddresses()
        external
        view
        onlyOwner
        notLocked
        returns (address[] memory)
    {
        return proxyAddresses;
    }
}
