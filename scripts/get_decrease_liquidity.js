UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"

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
  const signer2 = await ethers.getSigners();
  console.log("signer1:", signer2[0]);
//   console.log("signer2:", signer2[1]);
  const provider = ethers.provider

  YFSC_ADDRESS = "0x14E598614b152Ff4be2A4A451b1994A306D5404d";

  const YfScContract = new Contract(
    YFSC_ADDRESS,
    artifacts.YfSc.abi,
    provider
  )


  // const tx4 = await YfScContract.connect(signer2[0]).decreaseLiquidity(
  //     UNI_ADDRESS, 
  //     WETH_ADDRESS, 
  //     "3000", 
  //     "100", 
  //     { gasLimit: '1000000' }
  //   )
  //   await tx4.wait()
  // console.log("decrease liquidity validated: ", tx4);

  const nonfungiblePositionManager = new Contract(
    POSITION_MANAGER_ADDRESS,
    artifacts.NonfungiblePositionManager.abi,
    provider
  )

  // const tx5 = await nonfungiblePositionManager.connect(signer2[0]).sweepToken(
  //   UNI_ADDRESS, 
  //   "100", 
  //   UNI_ADDRESS,
  //   { gasLimit: '1000000' }
  // )
  // await tx5.wait()
  // console.log("decrease liquidity validated: ", tx5);

  const tx4 = await YfScContract.connect(signer2[0]).decreaseLiquidity(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "100", 
    { gasLimit: '1000000' }
  )
  await tx4.wait()
  console.log("decrease liquidity validated: ", tx4);

  // const tx5 = await nonfungiblePositionManager.connect(signer2[0]).sweepToken(
  //   UNI_ADDRESS, 
  //   "100", 
  //   UNI_ADDRESS,
  //   { gasLimit: '1000000' }
  // )
  // await tx5.wait()
  // console.log("decrease liquidity validated: ", tx5);

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