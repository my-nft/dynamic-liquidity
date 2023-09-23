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
  const [signer2] = await ethers.getSigners();
//   console.log("signer:", signer2);
  const provider = ethers.provider

  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, signer2);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  console.log("PositionsNFTContract: ", PositionsNFTContract);

  YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, POSITION_MANAGER_ADDRESS);

  console.log("YfScContract: ", YfScContract);

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer2).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2).approve(YfScContract.target, ethers.parseEther("1000"))

//   const poolContract = new Contract(USDT_USDC_500, artifacts.UniswapV3Pool.abi, provider)
  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 
  console.log("deadline: ", deadline);
//   console.log("deadline.toString(): ", deadline.toString());

//   const nonfungiblePositionManager = new Contract(
//     POSITION_MANAGER_ADDRESS,
//     artifacts.NonfungiblePositionManager.abi,
//     provider
//   )

  const tx = await PositionsNFTContract.connect(signer2).grantRole(
    MINTER_ROLE, YfScContract.target,
    { gasLimit: '1000000' }
  )
  await tx.wait()

  const tx2 = await YfScContract.connect(signer2).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    // "-887220", 
    // "887220", 
    "1459866916952", 
    "100000000000", 
    // "0", 
    // "0", 
    // deadline.toString(),
    { gasLimit: '1000000' }
  )
  await tx2.wait()

  const tx3 = await YfScContract.connect(signer2).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    // "-887220", 
    // "887220", 
    "1459866916952", 
    "100000000000", 
    // "0", 
    // "0", 
    // deadline.toString(),
    { gasLimit: '1000000' }
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