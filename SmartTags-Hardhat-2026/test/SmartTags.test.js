const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deploySmartTagsFixture } = require("./helpers/fixtures");

const CID_A = "QmTestPropertyAlpha123456789";
const CID_B = "QmTestPropertyBeta987654321";
const CID_C = "QmTestPropertyGamma555555555";

describe("SmartTags", function () {
  describe("Initialization (UUPS)", function () {
    it("sets ERC721 name and symbol", async function () {
      const { smartTags } = await loadFixture(deploySmartTagsFixture);
      expect(await smartTags.name()).to.equal("SmartTags");
      expect(await smartTags.symbol()).to.equal("STA");
    });

    it("sets SUPER_ADMIN to deployer and next token id to 1", async function () {
      const { smartTags, registrar } = await loadFixture(deploySmartTagsFixture);
      expect(await smartTags.SUPER_ADMIN()).to.equal(registrar.address);
      expect(await smartTags.getNextTokenId()).to.equal(1n);
    });

    it("supports ERC721 interface", async function () {
      const { smartTags } = await loadFixture(deploySmartTagsFixture);
      const erc721 = "0x80ac58cd";
      expect(await smartTags.supportsInterface(erc721)).to.equal(true);
    });
  });

  describe("registerLand", function () {
    it("mints token 1 to SUPER_ADMIN with ipfs URI and property record", async function () {
      const { smartTags, registrar } = await loadFixture(deploySmartTagsFixture);

      await expect(smartTags.registerLand(CID_A))
        .to.emit(smartTags, "PropertyRegistered")
        .withArgs(1n, registrar.address, CID_A);

      expect(await smartTags.ownerOf(1)).to.equal(registrar.address);
      expect(await smartTags.tokenURI(1)).to.equal(`ipfs://${CID_A}`);
      expect(await smartTags.isCIDUsed(CID_A)).to.equal(true);
      expect(await smartTags.getNextTokenId()).to.equal(2n);

      const prop = await smartTags.getProperty(1);
      expect(prop.tokenId).to.equal(1n);
      expect(prop.cid).to.equal(CID_A);
      expect(prop.landOwner).to.equal(registrar.address);
    });

    it("assigns sequential token ids", async function () {
      const { smartTags } = await loadFixture(deploySmartTagsFixture);

      await smartTags.registerLand(CID_A);
      await smartTags.registerLand(CID_B);

      expect(await smartTags.ownerOf(1)).to.not.equal(ethers.ZeroAddress);
      expect(await smartTags.ownerOf(2)).to.not.equal(ethers.ZeroAddress);
      expect(await smartTags.getNextTokenId()).to.equal(3n);
    });

    it("reverts on empty cid", async function () {
      const { smartTags } = await loadFixture(deploySmartTagsFixture);
      await expect(smartTags.registerLand("")).to.be.revertedWithCustomError(
        smartTags,
        "InvalidCID"
      );
    });

    it("reverts when cid already used", async function () {
      const { smartTags } = await loadFixture(deploySmartTagsFixture);
      await smartTags.registerLand(CID_A);
      await expect(smartTags.registerLand(CID_A)).to.be.revertedWithCustomError(
        smartTags,
        "CIDAlreadyUsed"
      );
    });

    it("reverts when caller is not SUPER_ADMIN", async function () {
      const { smartTags, other } = await loadFixture(deploySmartTagsFixture);
      await expect(smartTags.connect(other).registerLand(CID_A)).to.be.revertedWithCustomError(
        smartTags,
        "NotAuthorized"
      );
    });
  });

  describe("updateProperty", function () {
    async function registeredFixture() {
      const base = await loadFixture(deploySmartTagsFixture);
      await base.smartTags.registerLand(CID_A);
      return base;
    }

    it("updates cid, tokenURI, and cid usage map", async function () {
      const { smartTags, registrar } = await loadFixture(registeredFixture);

      await expect(smartTags.updateProperty(1, CID_B))
        .to.emit(smartTags, "PropertyUpdated")
        .withArgs(1n, registrar.address, CID_A, CID_B);

      expect(await smartTags.tokenURI(1)).to.equal(`ipfs://${CID_B}`);
      expect(await smartTags.isCIDUsed(CID_A)).to.equal(false);
      expect(await smartTags.isCIDUsed(CID_B)).to.equal(true);

      const prop = await smartTags.getProperty(1);
      expect(prop.cid).to.equal(CID_B);
    });

    it("reverts for non-existent token", async function () {
      const { smartTags } = await loadFixture(deploySmartTagsFixture);
      await expect(smartTags.updateProperty(99, CID_B)).to.be.revertedWithCustomError(
        smartTags,
        "PropertyNotFound"
      );
    });

    it("reverts on empty new cid", async function () {
      const { smartTags } = await loadFixture(registeredFixture);
      await expect(smartTags.updateProperty(1, "")).to.be.revertedWithCustomError(
        smartTags,
        "InvalidCID"
      );
    });

    it("reverts when new cid already used elsewhere", async function () {
      const { smartTags } = await loadFixture(registeredFixture);
      await smartTags.registerLand(CID_B);
      await expect(smartTags.updateProperty(1, CID_B)).to.be.revertedWithCustomError(
        smartTags,
        "CIDAlreadyUsed"
      );
    });

    it("reverts when new cid equals current cid (cid still marked used)", async function () {
      const { smartTags } = await loadFixture(registeredFixture);
      await expect(smartTags.updateProperty(1, CID_A)).to.be.revertedWithCustomError(
        smartTags,
        "CIDAlreadyUsed"
      );
    });

    it("reverts when caller is not SUPER_ADMIN", async function () {
      const { smartTags, other } = await loadFixture(registeredFixture);
      await expect(smartTags.connect(other).updateProperty(1, CID_C)).to.be.revertedWithCustomError(
        smartTags,
        "NotAuthorized"
      );
    });
  });

  describe("Views", function () {
    it("getProperty reverts for missing token", async function () {
      const { smartTags } = await loadFixture(deploySmartTagsFixture);
      await expect(smartTags.getProperty(1)).to.be.revertedWithCustomError(
        smartTags,
        "PropertyNotFound"
      );
    });

    it("isCIDUsed returns false for unused cid", async function () {
      const { smartTags } = await loadFixture(deploySmartTagsFixture);
      expect(await smartTags.isCIDUsed(CID_C)).to.equal(false);
    });
  });
});
