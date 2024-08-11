const { ContractFactory } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js");
const addresses = getAddresses(hre.network.name);
const yf = require('./yf_toolkit.js');

MINTER_ROLE     = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

t0      = "UNI"
t1      = "WETH"
feeTier = "500"


async function main() {
  const signer2  = await ethers.getSigners();
  const provider = ethers.provider
  const signer_address = await signer2[0].getAddress()
  const network = hre.network.name

  console.log("network: ", network);
  console.log("Token0: ", t0);
  console.log("Token1: ", t1);
  console.log("feeTier: ", feeTier);
  console.log("signer:", signer_address);
  console.log("")

  console.log("Deploying Positions NFT Contract ...")
  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, signer2[0]);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  console.log("Deploying Utils Contract ...")
  let UtilsContract = new ContractFactory(artifacts.Utils.abi, artifacts.Utils.bytecode, signer2[0]);
  UtilsContract = await UtilsContract.deploy(addresses['POSITION_MANAGER_ADDRESS']);

  console.log("Deploying YfSc Contract ...")
  let YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, addresses['POSITION_MANAGER_ADDRESS'], UtilsContract.target);
  
  console.log("Deploying States Variable Contract ...")
  let StatesVariableContract = new ContractFactory(artifacts.StatesVariables.abi, artifacts.StatesVariables.bytecode, signer2[0]);
  StatesVariableContract = await StatesVariableContract.deploy(PositionsNFTContract.target, addresses['POSITION_MANAGER_ADDRESS'], YfScContract.target, addresses['ISWAP_ROUTER']);
  
  console.log("PositionsNFTContract address : ", PositionsNFTContract.target);
  console.log("Utils Contract       address : ", UtilsContract.target);
  console.log("YfSc Contract        address : ", YfScContract.target);
  console.log("States Variable      address : ", StatesVariableContract.target);
  console.log("")
  console.log("")

  console.log("Granting Minter Role to YfScContract ...")
  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(MINTER_ROLE, YfScContract.target, {gasLimit:'1000000'})
  await tx.wait()
  console.log("")

  console.log("Granting Minter Role to StatesVariableContract ...")
  const tx9 = await PositionsNFTContract.connect(signer2[0]).grantRole(MINTER_ROLE, StatesVariableContract.target, {gasLimit:'1000000'})
  await tx9.wait()
  console.log("")

  console.log("Setting StatesVariableContract as owner of YfScContract ...")
  const tx10 = await YfScContract.connect(signer2[0]).setStatesVariables(StatesVariableContract.target, {gasLimit: '1000000'})
  await tx10.wait()
  console.log("")

  const tickUpper = "10"
  const tickLower = "10"
  console.log("Initializing Upper ticks to +", tickUpper, "to current price")
  console.log("Initializing Lower ticks to -", tickLower, "to current price")

  const tx001 = await StatesVariableContract.connect(signer2[0]).setInitialTicksForPool(addresses[t0], addresses[t1], feeTier, 
    tickUpper, tickLower, {gasLimit: '1000000'})
  await tx001.wait()
  console.log("")

  console.log("Done deploying contracts")
  console.log("Needs to approve YfScContract           to spend UNI and WETH")
  console.log("Needs to approve StatesVariableContract to spend UNI and WETH")
  console.log("Needs to approve ISWAP_ROUTER           to spend UNI and WETH")
  console.log("")
}

// npx hardhat run --network sepolia yf_sdk/yfsc_deploy.js

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });