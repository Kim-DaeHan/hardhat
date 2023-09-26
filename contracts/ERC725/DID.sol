// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DID {
    struct Key {
        uint256 purpose;
        uint256 keyType;
        bytes32 key;
    }

    struct Service {
        string serviceEndpoint;
        string serviceType;
    }

    struct AuthenticationMethod {
        string authenticationType;
        bytes32 key;
    }

    mapping(bytes32 => Key) public keys;
    mapping(uint256 => Service) public services;
    mapping(uint256 => AuthenticationMethod) public authMethods;

    // DID 문서의 필드들
    string public did; // DID 식별자
    string public publicKey; // 공개 키
    uint256 public created; // 생성일자
    uint256 public updated; // 업데이트 일자

    constructor(string memory _did) {
        did = _did;
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public {
        keys[_key] = Key(_purpose, _keyType, _key);
    }

    function addService(
        uint256 _index,
        string memory _serviceEndpoint,
        string memory _type
    ) public {
        services[_index] = Service(_serviceEndpoint, _type);
    }

    function addAuthMethod(
        uint256 _index,
        string memory _authenticationType,
        bytes32 _key
    ) public {
        authMethods[_index] = AuthenticationMethod(_authenticationType, _key);
    }

    function updatePublicKey(string memory _publicKey) public {
        publicKey = _publicKey;
    }

    function updateTimestamps(uint256 _created, uint256 _updated) public {
        created = _created;
        updated = _updated;
    }
}
