
UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984" // sepolia
WETH_ADDRESS = "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14" // sepolia 
POSITION_MANAGER_ADDRESS = "0x1238536071E1c677A632429e3655c799b22cDA52" // sepolia
ISWAP_ROUTER = "0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E" // sepolia
QUOTER = "0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3" // sepolia 

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

const artifacts = {
  NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
  WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
  UNI: require("../artifacts/contracts/utils.sol/ERC20.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/positionNFT.sol/PositionsNFT.json"),
  SwapRouter: require("../artifacts/contracts/ISwapRouter.sol/ISwapRouter.json"),
  UniswapV3Pool: require("../artifacts/contracts/IUniswapV3Pool.sol/IUniswapV3Pool.json"),
  Utils: require("../artifacts/contracts/utils.sol/Utils.json"),
  StatesVariables: require("../artifacts/contracts/StatesVariables.sol/StatesVariables.json"),
};

// const { ethers } = require("hardhat")

const { Contract, ContractFactory, utils, BigNumber  } = require("ethers")
// const { Contract} = require("ethers")

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer0:", signer2[0]);

  const provider = ethers.provider

  const SwapContract = new Contract(
    ISWAP_ROUTER,
    artifacts.SwapRouter.abi,
    provider
  )

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const swapParams2 = {
    tokenOut: UNI_ADDRESS,
    tokenIn: WETH_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    // deadline: "12265983778560",
    amountIn: "100000000000000",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }
  
  // await wethContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"));
  await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"));
  
  // const allowance = await wethContract.allowance(signer2[0], ISWAP_ROUTER);
  // console.log("allowance: ", allowance);
  // console.log("SwapContract: ", SwapContract);
  // console.log("swapParams2: ", swapParams2);
  // console.log("signer2[0]: ", signer2[0]);
  const tx21 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams2, {gasLimit: "3000000"});
  await tx21.wait();
 
  const tx22 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams2);
  await tx22.wait();

  const swapParams21 = {
    tokenIn: WETH_ADDRESS,
    tokenOut: UNI_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    deadline: "12265983778560",
    amountIn: "100000000000000",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  let approve_tx = await wethContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"));
  await approve_tx.wait();
  console.log("approved last ")
  const tx211 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  await tx211.wait();
  const tx2121 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  await tx2121.wait();

  const swapParams21_2 = {
    tokenIn: UNI_ADDRESS,
    tokenOut: WETH_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    deadline: "12265983778560",
    amountIn: "50000000000000",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  let approve_tx_2 = await wethContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"));
  await approve_tx_2.wait();
  console.log("approved last 2")
  const tx211_2 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21_2);
  await tx211_2.wait();
  const tx2121_2 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21_2);
  await tx2121_2.wait();

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