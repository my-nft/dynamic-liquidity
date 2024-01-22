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
  else {
      console.log("Already approved");
  }
}

async function main() {
  const signer2 = await ethers.getSigners();
  const usr_adr = await signer2[0].getAddress()
  console.log("signer: ", usr_adr);

  const provider = ethers.provider
  
  const YfScContract = new Contract(YF_SC,artifacts.YfSc.abi,provider)

  // const token1 = new Contract(T1, artifacts[t1].abi, provider)
  // const token0 = new Contract(T0, artifacts[t0].abi, provider)

  // await token1.connect(signer2[0]).approve(YF_SC, "1000");
  // await token0.connect(signer2[0]).approve(YF_SC, "1000");

  console.log("Starting mint!")
  const a = 0.43845131638258594
  const b = 0.110433
  const am = BigInt(a * 10**18)
  const bm = BigInt(b * 10**18)

  console.log(artifacts.YfSc.abi);

  console.log(nonfungiblePositionManager.positions(_poolNftId))

  const sqrtDict = await YfScContract.connect(signer2[0]).sqrtRatios(T0, T1, feeTier);
  const sqrtRatioX96  = sqrtDict[0];
  const sqrtRatioAX96 = sqrtDict[1];
  const sqrtRatioBX96 = sqrtDict[2];
  const sqrtPriceX96  = sqrtDict[3];

  console.log("sqrtRatioX96", sqrtRatioX96.toString())
  console.log("sqrtRatioAX96", sqrtRatioAX96.toString())
  console.log("sqrtRatioBX96", sqrtRatioBX96.toString())
  console.log("sqrtPriceX96", sqrtPriceX96.toString())

  const adj_amnt = liquidityAmounts(am, bm, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96)
  const _adjustedAmount0 = adj_amnt[0]
  const _adjustedAmount1 = adj_amnt[1]

  console.log("adjustedAmount0", _adjustedAmount0.toString())
  console.log("adjustedAmount1", _adjustedAmount1.toString())

  approveIfNeeded(token0, signer2[0], YF_SC, _adjustedAmount0)
  approveIfNeeded(token1, signer2[0], YF_SC, _adjustedAmount1)

  const gasPrice = await provider.getGasPrice()

  console.log("gasPrice", gasPrice.toString())

  const gasLimit = await YfScContract.connect(signer2[0]).estimateGas.mintNFT(T0, T1, feeTier, am, bm, "3", "3", {gasPrice: gasPrice.toString() })

  // const tx2 = await YfScContract.connect(signer2[0]).mintNFT(T0, T1, feeTier, am, bm, "3", "3", {gasLimit: '2000000' })
  // await tx2.wait()

  var previousLR = await YfScContract.tickLower();
  var previousUR = await YfScContract.tickUpper();

  console.log("current UR", Number(previousUR));
  console.log("current LR", Number(previousLR));

  // transaction succeeded
  // console.log("mintNFT transaction receipt:");
  // console.log("Tx Hash :", tx2.hash);
  // console.log("Block Nb:", tx2.blockNumber);
  // console.log("Gas Used:", tx2.gasUsed.toString());
  // console.log("Logs    :", tx2.logs);

  console.log("done!")
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });