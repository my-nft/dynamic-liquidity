UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
ISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
YF_SC = "0xf69544b65073495dDdfaa66866E3C61630e3BAc4"
POSITION_NFT = "0x47Ddb0D61CEC3EB1d9DB9166473B0DdaC273C01E"

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

const artifacts = {
  NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
  WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
  UNI: require("../artifacts/contracts/yfsc.sol/Token.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/yfsc.sol/PositionsNFT.json"),
};

// const { ethers } = require("hardhat")

const { Contract, ContractFactory, utils, BigNumber  } = require("ethers")
// const { Contract} = require("ethers")

async function main() {
  const signer = await ethers.getSigners();
  console.log("signer1:", signer[0]);
  const provider = ethers.provider

  const YfScContract = new Contract(
    YF_SC,
    artifacts.YfSc.abi,
    provider
  )

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const tx2 = await YfScContract.connect(signer[0]).collect(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",
    { gasLimit: '2000000' }
  )
  await tx2.wait()

  const tx3 = await YfScContract.connect(signer[1]).collect(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",
    { gasLimit: '2000000' }
  )
  await tx3.wait()
  console.log("done!")
}

/*
  npx hardhat run --network localhost scripts/04_addLiquidity.js
*/

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });