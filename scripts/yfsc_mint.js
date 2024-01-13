const { ethers   } = require("hardhat")
const { Contract } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js");

const addresses = getAddresses(hre.network.name);

YF_SC =  addresses['YF_SC']

t0 = "UNI"
t1 = "WETH"
T0 = addresses[t0]
T1 = addresses[t1]

feeTier = "3000"

async function approveIfNeeded(token, owner, spender, requiredAmount) {
  const currentAllowance = await token.allowance(owner, spender);

  if (currentAllowance.lt(requiredAmount)) {
      const amountToApprove = requiredAmount.sub(currentAllowance);
      await token.connect(owner).approve(spender, amountToApprove);
  }
}

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer: ", signer2[0].getAddress());

  const provider = ethers.provider

  const YfScContract = new Contract(YF_SC,artifacts.YfSc.abi,provider)

  // const token1 = new Contract(T1, artifacts[t1].abi, provider)
  // const token0 = new Contract(T0, artifacts[t0].abi, provider)

  // await token1.connect(signer2[0]).approve(YF_SC, "1000");
  // await token0.connect(signer2[0]).approve(YF_SC, "1000");

  const uniswapV3Factory = new Contract(addresses['UniswapV3Factory'], artifacts.UniswapV3Factory.abi, provider);

  const poolAddr = await uniswapV3Factory.getPool(T0, T1, feeTier);
  console.log("pool Addr:", poolAddr);

  const poolContract = new Contract(poolAddr, artifacts.UniswapV3Pool.abi, provider);

  const tickSpacing = await poolContract.tickSpacing();
  console.log('Tick Spacing:', Number(tickSpacing));

  const slot0 = await poolContract.slot0();
  const currentTick = slot0.tick;
  const sqrtPriceX96 = slot0.sqrtPriceX96;
  console.log('Current Tick:', Number(currentTick));
  console.log('Current Price:', Math.pow(Number(sqrtPriceX96),2));

  const newTickLower = Number(currentTick) - 5 * Number(tickSpacing);
  const newTickUpper = Number(currentTick) + 5 * Number(tickSpacing);
  console.log(`New Tick Range: [${newTickLower}, ${newTickUpper}]`);

  console.log("Starting mint!")

  const tx2 = await YfScContract.connect(signer2[0]).mintNFT(T0, T1, feeTier, String(newTickUpper), String(newTickLower), {gasLimit: '2000000' })
  await tx2.wait()

  console.log("done!")
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });