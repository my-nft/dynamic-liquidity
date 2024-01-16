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

  approveIfNeeded(token0, signer2[0], YF_SC, am)
  approveIfNeeded(token1, signer2[0], YF_SC, bm)

  const gasPrice = await provider.getGasPrice()

  console.log("gasPrice", gasPrice.toString())

  const gasLimit = await YfScContract.connect(signer2[0]).estimateGas.mintNFT(T0, T1, feeTier, am, bm, "3", "3", {gasPrice: gasPrice.toString() })

  const tx2 = await YfScContract.connect(signer2[0]).mintNFT(T0, T1, feeTier, am, bm, "3", "3", {gasLimit: '2000000' })
  await tx2.wait()

  var previousLR = await YfScContract.tickLower();
  var previousUR = await YfScContract.tickUpper();

  console.log("current UR", Number(previousUR));
  console.log("current LR", Number(previousLR));

  // transaction succeeded
  console.log("mintNFT transaction receipt:");
  console.log("Tx Hash :", tx2.hash);
  console.log("Block Nb:", tx2.blockNumber);
  console.log("Gas Used:", tx2.gasUsed.toString());
  console.log("Logs    :", tx2.logs);

  console.log("done!")
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });