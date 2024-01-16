const { Contract} = require("ethers");
const { ethers } = require("hardhat");
const { getAddresses, artifacts } = require("./addresses.js");

const addresses = getAddresses(hre.network.name);

YF_SC =  addresses['YF_SC']

t0 = "UNI"
t1 = "WETH"
T0 = addresses[t0]
T1 = addresses[t1]

feeTier    = "3000"

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer: ", signer2[0].getAddress());

  const provider = ethers.provider
  const YfScContract = new Contract(YF_SC, artifacts.YfSc.abi, provider)

  // const token1 = new Contract(T1, artifacts[t1].abi, provider)
  // const token0 = new Contract(T0, artifacts[t0].abi, provider)

  // await token1.connect(signer2[0]).approve(YF_SC, ethers.parseEther("1000"))
  // await token0.connect(signer2[0]).approve(YF_SC, ethers.parseEther("1000"))

  var previousLR = await YfScContract.tickLower();
  var previousUR = await YfScContract.tickUpper();

  console.log("previous UR", Number(previousUR));
  console.log("previous LR", Number(previousLR));

  const tx2 = await YfScContract.connect(signer2[0]).updatePosition(T0, T1, feeTier, "5", "5",{gasLimit: '2000000'}) 
  const receipt2 = await tx2.wait();

  console.log("updatePosition transaction receipt:");
  console.log("Tx Hash :", receipt2.transactionHash);
  console.log("Block Nb:", receipt2.blockNumber);
  console.log("Gas Used:", receipt2.gasUsed.toString());

  if (receipt2.status === 1) {
    console.log("updatePosition transaction successful");
  } else {
    console.error("updatePosition transaction failed");
  }

  var currentLR = await YfScContract.tickLower();
  var currentUR = await YfScContract.tickUpper();

  console.log("current UR", Number(currentLR));
  console.log("current LR", Number(currentUR));

  console.log("done!")
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });