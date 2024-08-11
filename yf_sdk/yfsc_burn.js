const { Contract} = require("ethers");
const { ethers } = require("hardhat");
const { getAddresses, artifacts } = require("./addresses.js");
const yf = require('./yf_toolkit.js').default;

const addresses = getAddresses(hre.network.name);

t0      = "UNI"
t1      = "WETH"
feeTier = "500"

async function main() {
  const signer2  = await ethers.getSigners();
  const provider = ethers.provider
  const signer_address = await signer2[0].getAddress()
  const network = hre.network.name
  
  console.log("Network: ", network);
  console.log("Token0 : ", t0);
  console.log("Token1 : ", t1);
  console.log("FeeTier: ", feeTier);
  console.log("Signer : ", signer_address);
  console.log("")

  const YfScContract = new Contract(addresses['YF_SC'], artifacts['YfSc'].abi, provider);

  _rebalance = false;
  const tx409 = await YfScContract.connect(signer2[2]).decreaseLiquidity(addresses[t0], addresses[t1], feeTier,
    "100", _rebalance, {gasLimit: '1000000'})
  await tx409.wait()
}

// npx hardhat run --network sepolia yf_sdk/yfsc_burn.js

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });