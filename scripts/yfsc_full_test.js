UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
ISWAP_ROUTER = "0xe592427a0aece92de3edee1f18e0157c05861564"
QUOTER = "0xb27308f9f90d607463bb33ea1bebb41c27ce5ab6"
UNISWAP_V3_Pool = "0x4d1892f15b03db24b55e73f9801826a56d6f0755"

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

const artifacts = {
  NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
  WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
  UNI: require("../artifacts/contracts/yfsc.sol/Token.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/yfsc.sol/PositionsNFT.json"),
  SwapRouter: require("../artifacts/contracts/ISwapRouter.sol/ISwapRouter.json"),
  UniswapV3Pool: require("../artifacts/contracts/IUniswapV3Pool.sol/IUniswapV3Pool.json"),
};

// const { ethers } = require("hardhat")

const { Contract, ContractFactory, utils, BigNumber  } = require("ethers")
// const { Contract} = require("ethers")

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer1:", signer2[0]);

  const provider = ethers.provider

  const SwapContract = new Contract(
    ISWAP_ROUTER,
    artifacts.SwapRouter.abi,
    provider
  )

  const UniswapV3PoolContract = new Contract(
    UNISWAP_V3_Pool ,
    artifacts.UniswapV3Pool.abi,
    provider
  )

  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, signer2[0]);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  let YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, POSITION_MANAGER_ADDRESS, ISWAP_ROUTER);

  // TokenContract = new ContractFactory(artifacts.Token.abi, artifacts.Token.bytecode, signer2[0]);
  // TokenContract = await YfScContract.deploy("Test Token", "TT");

  // UNI_ADDRESS = TokenContract.target;

  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(
    MINTER_ROLE, YfScContract.target,
    { gasLimit: '1000000' }
  )
  await tx.wait()

  console.log("YfScContract address: ", YfScContract.target);
  console.log("PositionsNFTContract address: ", PositionsNFTContract.target);

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  // const uniContract = TokenContract;
  // await wethContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))
  // await wethContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))
  // console.log("transfer init");
  // const uni_balance = await uniContract.balanceOf("0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0");
  // const uni_balance = await uniContract.balanceOf(signer2[3]);
  // console.log("uni_balance: ", uni_balance);
  // await uniContract.connect(signer2[2]).transfer(signer2[0], "5351019098278");
  // console.log("after transfer init");
  // await wethContract.connect(signer2[0]).deposit({ value: ethers.parseEther("20")});

  // const weth_balance0 = await wethContract.balanceOf(signer2[1]);
  // console.log("weth_balance0: ", weth_balance0);

  // await wethContract.connect(signer2[0]).transfer(signer2[1], ethers.parseEther("1"));

  // const weth_balance1 = await wethContract.balanceOf(signer2[0]);
  // console.log("weth_balance1: ", weth_balance1);
  // const weth_balance2 = await wethContract.balanceOf(signer2[1]);
  // console.log("weth_balance2: ", weth_balance2);
  // console.log("signer2[0]: ", signer2[0]);

  // const uni_balance_pool = await uniContract.balanceOf("0x4d1892f15b03db24b55e73f9801826a56d6f0755");
  // console.log("uni_balance_pool: ", uni_balance_pool);


  // const swapParams0 = {
  //   tokenOut: WETH_ADDRESS,
  //   tokenIn: UNI_ADDRESS,
  //   fee: "3000",
  //   recipient: signer2[0],
  //   deadline: "92265983778560",
  //   amountIn: ethers.parseEther("0.01"),
  //   amountOutMinimum: "0",
  //   sqrtPriceLimitX96: "0"
  // }

  // // await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"));
  // await wethContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("10"));
  // console.log("approved");

  // const tx01 = await SwapContract.connect(signer2[0]).exactInputSingle(
  //       swapParams0,
  //       { 
  //           gasLimit: '2000000', 
  //           // value: ethers.parseEther("10")
  //       }
  //   );
  // await tx01.wait()
  // const uni_balance = await uniContract.balanceOf(signer2[0]);
  // console.log("uni_balance: ", uni_balance);

  await wethContract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"))

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const tx0 = await YfScContract.connect(signer2[1]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "5351019098278",
    "1000000000000", 
    "1",
    "2",
    { gasLimit: '2000000' }
  )
  await tx0.wait()

  const swapParams3 = {
    tokenIn: UNI_ADDRESS,
    tokenOut: WETH_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    deadline: "92265983778560",
    amountIn: "34234234234",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  // await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"))

  // const tx002 = await SwapContract.connect(signer2[0]).exactInputSingle(
  //       swapParams3,
  //       { 
  //           gasLimit: '2000000', 
  //           value: '0'
  //       }
  //   );
  // await tx002.wait()

  await wethContract.connect(signer2[2]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[2]).approve(YfScContract.target, ethers.parseEther("1000"))

  const tx110 = await YfScContract.connect(signer2[2]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "7351019098278",
    "2000000000000", 
    "1",
    "2",
    { gasLimit: '2000000' }
  )
  await tx110.wait()

  const tx10 = await YfScContract.connect(signer2[1]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "92265983778560",
    "10000000000000", 
    "1",
    "2",
    { gasLimit: '2000000' }
  )
  await tx10.wait()

  const tx100 = await YfScContract.connect(signer2[1]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "10000", 
    "92265983778560",
    "10000000000000", 
    "1",
    "2",
    { gasLimit: '2000000' }
  )
  await tx100.wait()

  // await wethContract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"))
  // await uniContract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"))


  // const tx1 = await YfScContract.connect(signer2[1]).mintNFT(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "9226598377856",
  //   "100000000000", 
  //   "1",
  //   "2",
  //   { gasLimit: '2000000' }
  // )
  // await tx1.wait()

  // const tx11 = await YfScContract.connect(signer2[1]).mintNFT(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "9226598377856053",
  //   "100000000000000", 
  //   "1",
  //   "2",
  //   { gasLimit: '2000000' }
  // )
  // await tx11.wait()

  const swapParams = {
    tokenIn: UNI_ADDRESS,
    tokenOut: WETH_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    deadline: "92265983778560",
    amountIn: "34234234234",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  // await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"))

  // const tx2 = await SwapContract.connect(signer2[0]).exactInputSingle(
  //       swapParams,
  //       { 
  //           gasLimit: '2000000', 
  //           value: '0'
  //       }
  //   );
  // await tx2.wait()

  const swapParams2 = {
    tokenOut: WETH_ADDRESS,
    tokenIn: UNI_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    deadline: "12265983778560",
    amountIn: "14234234234",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  // await wethContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"))

  // const tx21 = await SwapContract.connect(signer2[0]).exactInputSingle(
  //       swapParams2,
  //       { 
  //           gasLimit: '2000000', 
  //           value: '0'
  //       }
  //   );
  // await tx21.wait()

  // const tx3 = await YfScContract.connect(signer2[1]).collect(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000",
  //   0,
  //   0,
  //   { gasLimit: '2000000' }
  // )
  // await tx3.wait()

  // const tx4 = await YfScContract.connect(signer2[0]).collect(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000",
  //   0,
  //   0,
  //   { gasLimit: '2000000' }
  // )
  // await tx4.wait()

  // var tickUpper = await YfScContract.connect(signer2[0]).tickUpper();
  // console.log("tickUpper: ", tickUpper);

  // var tickLower = await YfScContract.connect(signer2[0]).tickLower();
  // console.log("tickLower: ", tickLower);

  // const tx02 = await YfScContract.connect(signer2[0]).updatPosition( 
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000",  
  //   "3",
  //   "3",
  //   { gasLimit: '2000000' } 
  // ) 
  // await tx02.wait() 
  let _rebalance = false;
  const tx40 = await YfScContract.connect(signer2[1]).decreaseLiquidity( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "100", 
    _rebalance,
    { gasLimit: '1000000' } 
  ) 
  await tx40.wait() 


  // const tx020 = await YfScContract.connect(signer2[0]).withdraw( 
  //   UNI_ADDRESS, 
  //   { gasLimit: '200000' } 
  // ) 
  // await tx020.wait() 

  // const tx0200 = await YfScContract.connect(signer2[0]).withdraw( 
  //   WETH_ADDRESS, 
  //   { gasLimit: '200000' } 
  // ) 
  // await tx0200.wait() 

  const uniNftId = await YfScContract.connect(signer2[0]).poolNftIds(UNI_ADDRESS, WETH_ADDRESS, "3000")
  console.log("uniNftId: ", uniNftId);
  const positionNftId1 = await PositionsNFTContract.connect(signer2[1]).getUserNftPerPool("0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0", uniNftId)
  const positionNftId2 = await PositionsNFTContract.connect(signer2[2]).getUserNftPerPool("0x72DDbDc341BBFc00Fe4F3f49695532841965bF0E", uniNftId)
  console.log("positionNftId1: ", positionNftId1);
  console.log("positionNftId2: ", positionNftId2);
  const totalStatesForPosition1 = await PositionsNFTContract.connect(signer2[1]).totalStatesForPosition(positionNftId1)
  const totalStatesForPosition2 = await PositionsNFTContract.connect(signer2[2]).totalStatesForPosition(positionNftId2)
  console.log("totalStatesForPosition1: ", totalStatesForPosition1);
  console.log("totalStatesForPosition2: ", totalStatesForPosition2);
  console.log("");
  console.log("liquidity for position ------> ", positionNftId1)

  const public_poolNftId = await YfScContract.connect(signer2[0]).public_poolNftId()
  console.log("public_poolNftId        : ", public_poolNftId);
  const public_liquidityToRemove = await YfScContract.connect(signer2[0]).public_liquidityToRemove()
  console.log("public_liquidityToRemove: ", public_liquidityToRemove);

  // const public_lastLiquidityUpdateStateForPosition = await YfScContract.connect(signer2[0]).public_lastLiquidityUpdateStateForPosition()
  // console.log("public_lastLiquidityUpdateStateForPosition        : ", public_lastLiquidityUpdateStateForPosition);
  // const public_userPositionLastUpdateState = await YfScContract.connect(signer2[0]).public_userPositionLastUpdateState()
  // console.log("public_userPositionLastUpdateState: ", public_userPositionLastUpdateState);

  // const public_timestamp = await YfScContract.connect(signer2[0]).public_timestamp();
  // console.log("public_timestamp: ", public_timestamp);

  // const liquidityLockTime = await YfScContract.connect(signer2[0]).liquidityLockTime();
  // console.log("liquidityLockTime: ", liquidityLockTime);

  // const liquidityLastDepositTime0 = await YfScContract.connect(signer2[0]).liquidityLastDepositTime(0);
  // console.log("liquidityLastDepositTime0: ", liquidityLastDepositTime0);


  // const liquidityLastDepositTime1 = await YfScContract.connect(signer2[0]).liquidityLastDepositTime(1);
  // console.log("liquidityLastDepositTime1: ", liquidityLastDepositTime1);

  const rebalance = await YfScContract.connect(signer2[0]).public_rebalance();
  console.log("rebalance: ", rebalance);

  const public_userAddedLiquidity = await YfScContract.connect(signer2[0]).public_userAddedLiquidity();
  console.log("public_userAddedLiquidity: ", public_userAddedLiquidity);
  
  const public_totalCollected0 = await YfScContract.connect(signer2[0]).public_totalCollected0();
  console.log("public_totalCollected0: ", public_totalCollected0);

  const public_totalCollected1 = await YfScContract.connect(signer2[0]).public_totalCollected1();
  console.log("public_totalCollected1: ", public_totalCollected1);

  const public_totalPendingRewards0 = await YfScContract.connect(signer2[0]).public_totalPendingRewards0();
  console.log("public_totalPendingRewards0: ", public_totalPendingRewards0);

  const public_totalPendingRewards1 = await YfScContract.connect(signer2[0]).public_totalPendingRewards1();
  console.log("public_totalPendingRewards1: ", public_totalPendingRewards1);

  const public_positionRewardToken0 = await YfScContract.connect(signer2[0]).public_positionRewardToken0();
  console.log("public_positionRewardToken0: ", public_positionRewardToken0);

  const public_positionRewardToken1 = await YfScContract.connect(signer2[0]).public_positionRewardToken1();
  console.log("public_positionRewardToken1: ", public_positionRewardToken1);

  const public_maxStateIdForNFT = await YfScContract.connect(signer2[0]).public_maxStateIdForNFT();
  console.log("public_maxStateIdForNFT: ", public_maxStateIdForNFT);

  const public_statesCounter = await YfScContract.connect(signer2[0]).public_statesCounter();
  console.log("public_statesCounter: ", public_statesCounter);

  const public_previousLiquidity = await YfScContract.connect(signer2[0]).public_previousLiquidity();
  console.log("public_previousLiquidity: ", public_previousLiquidity);

  const public_newLiquidity = await YfScContract.connect(signer2[0]).public_newLiquidity();
  console.log("public_newLiquidity: ", public_newLiquidity);

  const public_userPreviousLiquidity = await YfScContract.connect(signer2[0]).public_userPreviousLiquidity();
  console.log("public_userPreviousLiquidity: ", public_userPreviousLiquidity);

  // for(var  ind = 0; ind <= parseInt(totalStatesForPosition1); ind++){
  //   console.log("position state id   : ", ind);
  //   var stateIdForPosition = await PositionsNFTContract.connect(signer2[1]).statesIdsForPosition(positionNftId1, ind);
  //   console.log("global state id     : ", stateIdForPosition);
  //   var liquidityAtState = await PositionsNFTContract.connect(signer2[1]).liquidityForUserInPoolAtState(positionNftId1, stateIdForPosition);
  //   console.log("liquidityAtState    : ", liquidityAtState);
  //   // var poolLiquidityAtState = await YfScContract.connect(signer2[0]).getTotalLiquidityAtStateForPosition(uniNftId, stateIdForPosition);
  //   // console.log("poolLiquidityAtState: ", poolLiquidityAtState);
  // }
  // console.log("");
  // console.log("liquidity for position ------> ", positionNftId2)
  // for(var  ind = 0; ind <= parseInt(totalStatesForPosition2); ind++){
  //   console.log("position state id   : ", ind);
  //   var stateIdForPosition = await PositionsNFTContract.connect(signer2[2]).statesIdsForPosition(positionNftId2, ind);
  //   console.log("global state id     : ", stateIdForPosition);
  //   var liquidityAtState = await PositionsNFTContract.connect(signer2[2]).liquidityForUserInPoolAtState(positionNftId2, stateIdForPosition);
  //   console.log("liquidityAtState    : ", liquidityAtState);
  //   // var poolLiquidityAtState = await YfScContract.connect(signer2[0]).getTotalLiquidityAtStateForPosition(uniNftId, stateIdForPosition);
  //   // console.log("poolLiquidityAtState: ", poolLiquidityAtState);
  // }
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