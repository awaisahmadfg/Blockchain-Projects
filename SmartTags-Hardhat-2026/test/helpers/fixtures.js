const { ethers, upgrades } = require("hardhat");

async function deploySmartTagsFixture() {
  const [registrar, other] = await ethers.getSigners();

  const SmartTags = await ethers.getContractFactory("SmartTags");
  const smartTags = await upgrades.deployProxy(SmartTags, [], {
    kind: "uups",
    initializer: "initialize",
  });
  await smartTags.waitForDeployment();

  return {
    smartTags,
    registrar,
    other,
    address: await smartTags.getAddress(),
  };
}

module.exports = { deploySmartTagsFixture };
