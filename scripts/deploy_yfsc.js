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
    "10000000000000", 
    { gasLimit: '1000000' }
  )
  await tx2.wait()

//   const tx3 = await YfScContract.connect(signer2[0]).mintNFT(
//     UNI_ADDRESS, 
//     WETH_ADDRESS, 
//     "3000", 
//     "14598669169", 
//     "1000000000", 
//     { gasLimit: '1000000' }
//   )
//   await tx3.wait()

  // const tx4 = await YfScContract.connect(signer2[0]).decreaseLiquidity(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "50", 
  //   { gasLimit: '1000000' }
  // )
  // await tx4.wait()
  // console.log("decrease liquidity validated: ", tx4);

  const tx5 = await YfScContract.connect(signer2[0]).updatePosition(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",
    { gasLimit: '1000000' }
  )
  await tx5.wait()
  console.log("update liquidity position: ", tx5);

  // const tx5 = await YfScContract.connect(signer2[0]).decreaseLiquidity(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "40", 
  //   { gasLimit: '1000000' }
  // )
  // await tx5.wait()
  // console.log("decrease liquidity validated: ", tx5);

  // const tx6 = await YfScContract.connect(signer2[0]).decreaseLiquidity(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "10", 
  //   { gasLimit: '1000000' }
  // )
  // await tx6.wait()
  // console.log("decrease liquidity validated: ", tx6);

  // const tx5 = await YfScContract.connect(signer2[0]).sweepToken(
  //   UNI_ADDRESS, 
  //   "300000000", 
  //   "100x80520E99aDD46c642052Ca5B476a1Dd40dB973B00", 
  //   { gasLimit: '1000000' }
  // )
  // await tx5.wait()
  // console.log("sweep token success: ", tx5);

//   const tx5 = await YfScContract.connect(signer2[0]).updatePosition(
//     UNI_ADDRESS, 
//     WETH_ADDRESS, 
//     "3000",
//     { gasLimit: '1000000' }
//   )
//   await tx5.wait()
//   console.log("decrease liquidity validated: ", tx5);

// lock liquidity uniquement for users to withdraw 
// calculer la deuxieme valeur a partir de la premiere valeur 

  const tokenId = await YfScContract.public_nft_id();
  const public_liquidityToRemove = await YfScContract.public_liquidityToRemove();
  const public_amount0Min = await YfScContract.public_amount0Min();
  const public_amount1Min = await YfScContract.public_amount1Min();
  const public_deadline = await YfScContract.public_deadline();

  const public_balance0Before = await YfScContract.public_balance0Before();
  const public_balance1Before = await YfScContract.public_balance1Before();
  const public_balance0After = await YfScContract.public_balance0After();
  const public_balance1After = await YfScContract.public_balance1After();


  console.log("tokenId:", tokenId);
  console.log("public_liquidityToRemove:", public_liquidityToRemove);
  console.log("public_amount0Min:", public_amount0Min);
  console.log("public_amount1Min:", public_amount1Min);
  console.log("public_deadline:", public_deadline);

  console.log("public_balance0Before:", public_balance0Before);
  console.log("public_balance1Before:", public_balance1Before);
  console.log("public_balance0After:", public_balance0After);
  console.log("public_balance1After:", public_balance1After);

  const public_update_position_balance0 = await YfScContract.public_update_position_balance0();
  const public_update_position_balance1 = await YfScContract.public_update_position_balance1();
  
  console.log("public_update_position_balance0:", public_update_position_balance0);
  console.log("public_update_position_balance1:", public_update_position_balance1);

  // const liquidity_before = await YfScContract.liquidity_before();
  // const tokensOwed0_before = await YfScContract.tokensOwed0_before();
  // const tokensOwed1_before = await YfScContract.tokensOwed1_before();

  // const liquidity_after = await YfScContract.liquidity_after();
  // const tokensOwed0_after = await YfScContract.tokensOwed0_after();
  // const tokensOwed1_after = await YfScContract.tokensOwed1_after();

  // console.log("liquidity_before:", liquidity_before);
  // console.log("tokensOwed0_before:", tokensOwed0_before);
  // console.log("tokensOwed1_before:", tokensOwed1_before);
  // console.log("liquidity_after:", liquidity_after);
  // console.log("tokensOwed0_after:", tokensOwed0_after);
  // console.log("tokensOwed1_after:", tokensOwed1_after);

  
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