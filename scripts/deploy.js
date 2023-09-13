import { ethers } from "hardhat";
// import { mine } from "@nomicfoundation/hardhat-network-helpers";

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PositionsNFT = await ethers.deployContract("PositionsNFT");
  
    console.log("PositionsNFT address:", await PositionsNFT.getAddress());

    const YfSc = await ethers.deployContract("YfSc", [PositionsNFT.getAddress()]);
  
    console.log("YfSc address:", await PositionsNFT.getAddress());
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });