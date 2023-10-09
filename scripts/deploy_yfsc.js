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

  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, signer2[0]);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, POSITION_MANAGER_ADDRESS);

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))

  await wethContract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"))

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

//   const nonfungiblePositionManager = new Contract(
//     POSITION_MANAGER_ADDRESS,
//     artifacts.NonfungiblePositionManager.abi,
//     provider
//   )

  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(
    MINTER_ROLE, YfScContract.target,
    { gasLimit: '1000000' }
  )
  await tx.wait()

  const tx2 = await YfScContract.connect(signer2[0]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "145986691695200",
    // "10000000000000", 
    { gasLimit: '1000000' }
  )
  await tx2.wait()

  // tickLower = -27060;
  // tickUpper = -25680;

  // int24 public tickLower = -887220;
  //   int24 public tickUpper = 887220;
  // "-887220",  "887220"
  // "-27060",  "-25680"
  const getAmount1ForAmount0 = await YfScContract.getAmount1ForAmount0("-27060",  "-25680", "14598669169") 
  console.log("getAmount1ForAmount0: ", getAmount1ForAmount0);

  const getLiquidityForAmount0 = await YfScContract.getLiquidityForAmount0("-27060",  "-25680", "14598669169") 
  console.log("getLiquidityForAmount0: ", getLiquidityForAmount0);



  // const getLiquidityForAmount1 = await YfScContract.getLiquidityForAmount1("-27060",  "-25680", "10000000000") 
  // console.log("getLiquidityForAmount1: ", getLiquidityForAmount1);


  // const tx4 = await YfScContract.connect(signer2[0]).decreaseLiquidity( 
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "50", 
  //   { gasLimit: '1000000' } 
  // ) 
  // await tx4.wait() 
  // console.log("decrease liquidity validated: ", tx4); 

  const amoun1 = await YfScContract.amount1_public(); 
  // console.log("amoun1: ", amoun1); 

  const tx5 = await YfScContract.connect(signer2[0]).updatePosition(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",
    { gasLimit: '1000000' }
  )
  await tx5.wait()
  // console.log("update liquidity position: ", tx5);

  const tick_lower_0 = await YfScContract.tick_lower_0() 
  console.log("tick_lower_0: ", tick_lower_0);
  const tick_upper_0 = await YfScContract.tick_upper_0() 
  console.log("tick_upper_0: ", tick_upper_0);

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