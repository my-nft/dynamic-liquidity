const { Contract} = require("ethers");
const { ethers } = require("hardhat");
const { getAddresses, artifacts } = require("./addresses.js");

const addresses = getAddresses(hre.network.name);

YFSC_ADDRESS = addresses['YF_SC']

t0 = "UNI"
t1 = "WETH"
T0 = addresses[t0]
T1 = addresses[t1]

feeTier    = "3000"

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer1:", signer2[0]);
  const provider = ethers.provider

  const token1 = new Contract(T1, artifacts[t1].abi, provider)
  const token0 = new Contract(T0, artifacts[t0].abi, provider)

  await token1.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))
  await token0.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))

  const YfScContract = new Contract(YFSC_ADDRESS, artifacts.YfSc.abi,provider)


  const tx = await YfScContract.connect(signer2[0]).decreaseLiquidity(T0, T1, feeTier, "100", {gasLimit: '1000000' })
  await tx.wait()
  console.log("decrease liquidity validated: ", tx);

  const public_poolNftId = await YfScContract.public_poolNftId();

  console.log("public_poolNftId: ", public_poolNftId);

  const public_half = await YfScContract.public_half();
  console.log("public_half: ", public_half);

  const public_amountOut = await YfScContract.public_amountOut();
  console.log("public_amountOut: ", public_amountOut);

  const public_balanceToken0 = await YfScContract.public_balanceToken0();
  console.log("public_balanceToken0: ", public_balanceToken0);

  const public_balanceToken1 = await YfScContract.public_balanceToken1();
  console.log("public_balanceToken1: ", public_balanceToken1);

  const public_oldLiquidity = await YfScContract.public_oldLiquidity();
  console.log("public_oldLiquidity: ", public_oldLiquidity);

  const public_newLiquidity = await YfScContract.public_newLiquidity();
  console.log("public_newLiquidity: ", public_newLiquidity);
 
  console.log("done!")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });