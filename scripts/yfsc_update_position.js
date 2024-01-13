const { Contract} = require("ethers");
const { ethers } = require("hardhat");
const { getAddresses, artifacts } = require("./addresses.js");

const addresses = getAddresses(hre.network.name);

YF_SC =  addresses['YF_SC']

t0 = "UNI"
t1 = "WETH"
T0 = addresses[t0]
T1 = addresses[t1]

tick_lower = "-27060" 
tick_upper = "-20820" 
feeTier    = "3000"

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer: ", signer2[0].getAddress());

  const provider = ethers.provider
  const YfScContract = new Contract(YF_SC, artifacts.YfSc.abi, provider)

  const token1 = new Contract(T1, artifacts[t1].abi, provider)
  const token0 = new Contract(T0, artifacts[t0].abi, provider)

  await token1.connect(signer2[0]).approve(YF_SC, ethers.parseEther("1000"))
  await token0.connect(signer2[0]).approve(YF_SC, ethers.parseEther("1000"))

  var previousLR = await YfScContract.tickLower();
  var previousUR = await YfScContract.tickUpper();

  console.log("UR", Number(previousUR));
  console.log("LR", Number(previousLR));


  const tx1 = await YfScContract.connect(signer2[0]).setTicks(tick_lower,tick_upper,{gasLimit:'1000000'})
  const receipt1 = await tx1.wait();

  console.log("setTicks transaction receipt:");
  console.log("Tx Hash :", receipt1.transactionHash);
  console.log("Block Nb:", receipt1.blockNumber);
  console.log("Gas Used:", receipt1.gasUsed.toString());
  console.log("Logs    :", receipt1.logs);

  // Check if the transaction was successful
  if (receipt1.status === 1) {
    console.log("setTicks transaction successful");
  } else {
    console.error("setTicks transaction failed");
    // Additional error handling if needed
  }
  console.log("");

  const tx2 = await YfScContract.connect(signer2[0]).updatePosition(T0, T1, feeTier, {gasLimit: '1000000'}) 
  const receipt2 = await tx2.wait();

  console.log("updatePosition transaction receipt:");
  console.log("Tx Hash :", receipt2.transactionHash);
  console.log("Block Nb:", receipt2.blockNumber);
  console.log("Gas Used:", receipt2.gasUsed.toString());
  console.log("Logs    :", receipt2.logs);

  if (receipt2.status === 1) {
    console.log("updatePosition transaction successful");
  } else {
    console.error("updatePosition transaction failed");
  }

  console.log("done!")
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });