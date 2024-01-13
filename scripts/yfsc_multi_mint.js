const { ethers   } = require("hardhat")
const { Contract } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js");

const addresses = getAddresses(hre.network.name);

YF_SC = addresses['YF_SC']

t0 = "UNI"
t1 = "WETH"
T0 = addresses[t0]
T1 = addresses[t1]

tick_lower0 = "22579957097400000" 
tick_upper0 = "1000000000000000" 

tick_lower1 = "45159914194900000" 
tick_upper1 = "2000000000000000" 

feeTier = "3000"

async function main() {
  const signer = await ethers.getSigners();
  console.log("signer1:", signer[0].getAddress());
  const provider = ethers.provider

  const YfScContract = new Contract(YF_SC, artifacts.YfSc.abi, provider)
  console.log("initialized");

  const token1 = new Contract(T1, artifacts[t1].abi, provider)
  const token0 = new Contract(T0, artifacts[t0].abi, provider)

  await token1.connect(signer[0]).approve(YF_SC, "1000");
  await token0.connect(signer[0]).approve(YF_SC, "1000");

  //await token1.connect(signer[1]).approve(YF_SC, "1000");
  //await token0.connect(signer[1]).approve(YF_SC, "1000");

  console.log("approved");


  const tx2 = await YfScContract.connect(signer[0]).mintNFT(T0, T1, feeTier, tick_upper0, tick_lower0, {gasLimit: '2000000' })
  await tx2.wait()

  const tx3 = await YfScContract.connect(signer[1]).mintNFT(T0, T1, feeTier, tick_upper1, tick_lower1, {gasLimit: '2000000' })
  await tx3.wait()

  console.log("done!")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });