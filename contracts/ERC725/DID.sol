// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DID {
    struct DIDDocument {
        string id;
        string publicKey;
        Authentication authentication;
        Services services;
    }

    struct Authentication {
        string signature;
        string dateOfBirth;
        string passportNumber;
    }

    struct Services {
        string website;
        string email;
        string phone;
    }

    mapping(bytes32 => DIDDocument) private didDocuments;

    // DID 문서 데이터를 저장하는 함수
    function setDIDDocument(
        string memory id,
        string memory publicKey,
        string memory signature,
        string memory dateOfBirth,
        string memory passportNumber,
        string memory website,
        string memory email,
        string memory phone
    ) public {
        bytes32 key = keccak256(abi.encodePacked(id));

        // 이미 해당 DID에 대한 문서가 존재하는지 확인
        if (bytes(didDocuments[key].id).length == 0) {
            DIDDocument memory didDocument;
            didDocument.id = id;
            didDocument.publicKey = publicKey;
            didDocument.authentication.signature = signature;
            didDocument.authentication.dateOfBirth = dateOfBirth;
            didDocument.authentication.passportNumber = passportNumber;
            didDocument.services.website = website;
            didDocument.services.email = email;
            didDocument.services.phone = phone;

            didDocuments[key] = didDocument;
        } else {
            // 이미 해당 DID에 대한 문서가 존재하므로 덮어쓰기를 방지하려면 여기에 대한 처리를 추가하세요.
            // 예를 들어, 예외를 발생시켜서 덮어쓰기를 막을 수 있습니다.
            revert("DID already exists.");
        }
    }

    // DID 문서 데이터를 조회하는 함수
    function getDIDDocument(
        string memory id
    ) public view returns (DIDDocument memory) {
        bytes32 key = keccak256(abi.encodePacked(id));
        return didDocuments[key];
    }

    // DID 문서 데이터를 조회하는 함수 - id 필드
    function getDIDDocumentId(
        string memory id
    ) public view returns (string memory) {
        bytes32 key = keccak256(abi.encodePacked(id));
        return didDocuments[key].id;
    }

    // DID 문서 데이터를 조회하는 함수 - publicKey 필드
    function getDIDDocumentPublicKey(
        string memory id
    ) public view returns (string memory) {
        bytes32 key = keccak256(abi.encodePacked(id));
        return didDocuments[key].publicKey;
    }

    // DID 문서 데이터를 조회하는 함수 - authentication 필드
    function getDIDDocumentAuthentication(
        string memory id
    ) public view returns (Authentication memory) {
        bytes32 key = keccak256(abi.encodePacked(id));
        return didDocuments[key].authentication;
    }

    // DID 문서 데이터를 조회하는 함수 - services 필드
    function getDIDDocumentServices(
        string memory id
    ) public view returns (Services memory) {
        bytes32 key = keccak256(abi.encodePacked(id));
        return didDocuments[key].services;
    }

    // DIDDocument 구조체의 모든 필드를 수정하는 함수
    function updateDIDDocument(
        string memory id,
        string memory newPublicKey,
        string memory newSignature,
        string memory newDateOfBirth,
        string memory newPassportNumber,
        string memory newWebsite,
        string memory newEmail,
        string memory newPhone
    ) public {
        bytes32 key = keccak256(abi.encodePacked(id));
        DIDDocument storage document = didDocuments[key];

        // 존재하지 않는 키에 대한 처리
        if (bytes(document.id).length == 0) {
            revert("DID does not exist.");
        }

        document.id = id;
        document.publicKey = newPublicKey;
        document.authentication.signature = newSignature;
        document.authentication.dateOfBirth = newDateOfBirth;
        document.authentication.passportNumber = newPassportNumber;
        document.services.website = newWebsite;
        document.services.email = newEmail;
        document.services.phone = newPhone;
    }
}
