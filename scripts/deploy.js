// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
// imports 
require("@nomicfoundation/hardhat-verify");
const { ethers, run, network } = require("hardhat")




async function main() {

  const CrowdfundingFactory = await ethers.getContractFactory("Crowdfunding")
  console.log("Deploying contract ... ")

  const Crowdfunding = await CrowdfundingFactory.deploy();
  await Crowdfunding.waitForDeployment();

  const contractAddress = await Crowdfunding.getAddress();
  console.log(`Contract deployed at ${contractAddress}`);

  const deployoor = contractAddress.deploymentTransaction();
  console.log(`Contract deployer is: ${deployoor.from}`);

  // fuji testnet verify may not work, so do:
  // npx hardhat verify --network fuji *contractAddress*
  if (network.config.chainId === 43114 && process.env.SNOWTRACE_KEY) {
    await Crowdfunding.waitForDeployment(6)
    await verify(contractAddress, []);
  }


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});