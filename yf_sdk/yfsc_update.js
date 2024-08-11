const { ethers   } = require("hardhat")
const { Contract } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js");

const addresses = getAddresses(hre.network.name);

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

  const YfScContract = new Contract(addresses['YF_SC'], artifacts['YfSc'].abi, provider);

  const ticks_upper = "3"
  const ticks_lower = "3"

  console.log("Updating Upper ticks to +", ticks_upper, "to current price")
  console.log("Updating Lower ticks to -", ticks_lower, "to current price")
  
  const tx02 = await YfScContract.connect(signer2[0]).updatePosition(
    addresses[t0],
    addresses[t1],
    feeTier,
    ticks_upper, 
    ticks_lower, 
    {gasLimit: '2000000'})
  await tx02.wait()

}
// npx hardhat run --network sepolia more_scripts/yfsc_update.js

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });