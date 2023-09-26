const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DID", function () {
  it("Should set and get a DID Document", async function () {
    const [owner] = await ethers.getSigners();

    // 배포
    const DID = await ethers.getContractFactory("DID");
    const did = await DID.deploy();

    await did.deployed();

    // DID Document를 설정
    await did.setDIDDocument(
      "did:example:123",
      "publicKey",
      "signature",
      "dateOfBirth",
      "passportNumber",
      "website",
      "email",
      "phone"
    );

    // DID Document를 가져오기
    const didDocument = await did.getDIDDocument("did:example:123");

    // 결과 확인
    expect(didDocument.id).to.equal("did:example:123");
    expect(didDocument.publicKey).to.equal("publicKey");
    expect(didDocument.authentication.signature).to.equal("signature");
    expect(didDocument.services.website).to.equal("website");
  });

  it("Should prevent updating a non-existing DID Document", async function () {
    const [owner] = await ethers.getSigners();

    // 배포
    const DID = await ethers.getContractFactory("DID");
    const did = await DID.deploy();

    await did.deployed();

    // 존재하지 않는 DID Document를 업데이트 시도
    await expect(
      did.updateDIDDocument(
        "did:nonexistent:456",
        "newPublicKey",
        "newSignature",
        "newDateOfBirth",
        "newPassportNumber",
        "newWebsite",
        "newEmail",
        "newPhone"
      )
    ).to.be.revertedWith("DID does not exist.");
  });
});
