UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
ISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
YF_SC = "0xA14E2abe5197d19Ff75BAA650b43E167e82592de"
POSITION_NFT = "0x695aC77272CfA60E5A41cCf34B2C71b242DAdE06"

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

const artifacts = {
  NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
  WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
  UNI: require("../artifacts/contracts/yfsc.sol/Token.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/yfsc.sol/PositionsNFT.json"),
};

const { Contract, ContractFactory, utils, BigNumber  } = require("ethers")

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer1:", signer2[0]);
  const provider = ethers.provider

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const YfScContract = new Contract(
    YF_SC,
    artifacts.YfSc.abi,
    provider
  )

  // const tx4 = await YfScContract.connect(signer2[0]).decreaseLiquidity( 
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "50", 
  //   { gasLimit: '1000000' } 
  // ) 
  // await tx4.wait() 
  // console.log("decrease liquidity validated: ", tx4); 

  const tx8 = await YfScContract.connect(signer2[0]).setTicks(
    // "-21960",
    "-27060",
    "-20820",
    { gasLimit: '1000000' }
  )
  await tx8.wait()

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

/*
  npx hardhat run --network localhost scripts/04_addLiquidity.js
*/

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });