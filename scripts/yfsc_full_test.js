// UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984" // goerli
// WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6" // goerli 
// POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88" // goerli
// ISWAP_ROUTER = "0xe592427a0aece92de3edee1f18e0157c05861564" // goerli
// QUOTER = "0xb27308f9f90d607463bb33ea1bebb41c27ce5ab6" // goerli 
// UNISWAP_V3_Pool = "0x4d1892f15b03db24b55e73f9801826a56d6f0755" // goerli 

// UNI_ADDRESS = "0xbB763C91A8b1D7D8Dc727426Ed1514b8a6D067ba" // base sepolia
// WETH_ADDRESS = "0x4200000000000000000000000000000000000006" // base sepolia 
// POSITION_MANAGER_ADDRESS = "0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2" // base sepolia
// ISWAP_ROUTER = "0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4" // base sepolia
// QUOTER = "0xC5290058841028F1614F3A6F0F5816cAd0df5E27" // base sepolia 
// UNISWAP_V3_Pool = "0x4d1892f15b03db24b55e73f9801826a56d6f0755" // base sepolia 
// sqrtPriceX96   uint160 :  24797325480956012864567387421

UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984" // sepolia
WETH_ADDRESS = "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14" // sepolia 
POSITION_MANAGER_ADDRESS = "0x1238536071E1c677A632429e3655c799b22cDA52" // sepolia
ISWAP_ROUTER = "0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E" // sepolia
QUOTER = "0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3" // sepolia 
// UNISWAP_V3_Pool = "0x4d1892f15b03db24b55e73f9801826a56d6f0755" // sepolia 
// sqrtPriceX96   uint160 :  24797325480956012864567387421


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

  // const UniswapV3PoolContract = new Contract(
  //   UNISWAP_V3_Pool ,
  //   artifacts.UniswapV3Pool.abi,
  //   provider
  // )

  console.log("will start deploying")
  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, 
    artifacts.PositionsNFT.bytecode, signer2[0]);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  console.log("PositionsNFTContract address: ", PositionsNFTContract.target);

  let UtilsContract = new ContractFactory(artifacts.Utils.abi, artifacts.Utils.bytecode, signer2[0]);
  UtilsContract = await UtilsContract.deploy(POSITION_MANAGER_ADDRESS);

  console.log("UtilsContract address: ", UtilsContract.target);

  let YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, 
    POSITION_MANAGER_ADDRESS, UtilsContract.target);

  console.log("YfScContract address: ", YfScContract.target);
  
  let StatesVariableContract = new ContractFactory(artifacts.StatesVariables.abi, 
    artifacts.StatesVariables.bytecode, signer2[0]);
  StatesVariableContract = await StatesVariableContract.deploy(PositionsNFTContract.target, 
    POSITION_MANAGER_ADDRESS, YfScContract.target, ISWAP_ROUTER);

  console.log("States Variable address: ", StatesVariableContract.target);
  // TokenContract = new ContractFactory(artifacts.Token.abi, artifacts.Token.bytecode, signer2[0]);
  // TokenContract = await YfScContract.deploy("Test Token", "TT");

  // UNI_ADDRESS = TokenContract.target;

  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(
    MINTER_ROLE, YfScContract.target,
    { gasLimit: '1000000' }
  )
  await tx.wait()

  const tx9 = await PositionsNFTContract.connect(signer2[0]).grantRole(
    MINTER_ROLE, StatesVariableContract.target,
    { gasLimit: '1000000' }
  )
  await tx9.wait()

  const tx10 = await YfScContract.connect(signer2[0]).setStatesVariables(
    StatesVariableContract.target,
    { gasLimit: '1000000' }
  )
  await tx10.wait()
  

  const tx001 = await StatesVariableContract.connect(signer2[0]).setInitialTicksForPool(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "10",
    "10",
    { gasLimit: '1000000' }
  )
  await tx001.wait()
 
  console.log("PositionsNFTContract address: ", PositionsNFTContract.target);

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer2[1]).approve(YfScContract.target, 
    ethers.parseEther("1000"));

  await uniContract.connect(signer2[1]).approve(YfScContract.target, 
    ethers.parseEther("1000"));

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 
  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter starting: ", statesCounter);
  
  const tx0 = await YfScContract.connect(signer2[1]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "5351019098",
    "1000000000000", 
    // "1",
    // "2",
    { gasLimit: '2000000' }
  )
  await tx0.wait()

  // return;

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter mint 1: ", statesCounter);

  await wethContract.connect(signer2[2]).approve(YfScContract.target, 
    ethers.parseEther("1000"));

  await uniContract.connect(signer2[2]).approve(YfScContract.target, 
    ethers.parseEther("1000"));

  const tx110 = await YfScContract.connect(signer2[2]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "735101909",
    "2000000000000", 
    // "1",
    // "2",
    { gasLimit: '2000000' }
  )
  await tx110.wait()

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter mint 2: ", statesCounter);

  const swapParams2 = {
    tokenOut: UNI_ADDRESS,
    tokenIn: WETH_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    // deadline: "12265983778560",
    amountIn: "10000000000000000",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }
  
  await wethContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"));
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
    tokenOut: UNI_ADDRESS,
    tokenIn: WETH_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    deadline: "12265983778560",
    amountIn: "142342342340",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"));

  const tx211 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  await tx211.wait();
  const tx2121 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  await tx2121.wait();
  // const tx2112 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  // await tx2112.wait()
  // const tx212 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  // await tx212.wait()

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
  // 0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0 0x62f77aDEc6273aB0d44Ebb08ea53464abec70A69
// return;
  // const tx02 = await YfScContract.connect(signer2[0]).updatePosition( 
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000",  
  //   "3",
  //   "3",
  //   { gasLimit: '2000000' } 
  // ) 
  // await tx02.wait() 

  // const tx020 = await YfScContract.connect(signer2[0]).updatePosition( 
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000",  
  //   "2",
  //   "2",
  //   { gasLimit: '2000000' } 
  // ) 
  // await tx020.wait() 

  // return; 

  // const tx020 = await YfScContract.connect(signer2[0]).updatePosition( 
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000",  
  //   "2",
  //   "2",
  //   { gasLimit: '2000000' } 
  // ) 
  // await tx020.wait() 

// statesCounter starting:  0n
// statesCounter mint 1:  1n
// statesCounter mint 2:  2n
// statesCounter update 01:  2n
// pendingReward0:  Result(2) [ 0n, 0n ]
// pendingReward1:  Result(2) [ 0n, 0n ]
// originalPoolNftIds:  11760n
// rewardToken0_1:  0n
// rewardToken0_2:  0n
// rewardToken0_3:  0n
// rewardToken0_4:  0n
// rewardToken1_1:  0n
// rewardToken1_2:  0n
// rewardToken1_3:  5339287n
// rewardToken1_4:  5339287n

// pending rewards not calculated correctly
// 0 if no update 
// wrong values if updates 

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter update 01: ", statesCounter);



  // console.log("balance token0: ", await uniContract.connect(signer2[0]).balanceOf(YfScContract.target));
  // console.log("balance token1: ", await wethContract.connect(signer2[0]).balanceOf(YfScContract.target));
    
  let rebalance = false;
  let external = true;
  const tx3 = await YfScContract.connect(signer2[1]).collect( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    0, 
    0, 
    rebalance, 
    external,
    { gasLimit: '2000000' } 
  ) 
  await tx3.wait() 
  const tx31 = await YfScContract.connect(signer2[2]).collect( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    0, 
    0, 
    rebalance, 
    external,
    { gasLimit: '2000000' } 
  ) 
  await tx31.wait() 
  var pendingReward0 = await YfScContract.connect(signer2[1]).getPendingrewardForPosition(
    UNI_ADDRESS, WETH_ADDRESS, "3000");
  var pendingReward1 = await YfScContract.connect(signer2[2]).getPendingrewardForPosition(
    UNI_ADDRESS, WETH_ADDRESS, "3000");
  console.log("pendingReward0: ", pendingReward0);
  console.log("pendingReward1: ", pendingReward1);

  let originalPoolNftIds = await YfScContract.connect(signer2[0]).
  originalPoolNftIds(UNI_ADDRESS, WETH_ADDRESS, "3000");
  console.log("originalPoolNftIds: ", originalPoolNftIds);
  var rewardToken0_1 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 1);
  var rewardToken0_2 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 2);
  var rewardToken0_3 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 3);
  var rewardToken0_4 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 4);

  console.log("rewardToken0_1: ", rewardToken0_1);
  console.log("rewardToken0_2: ", rewardToken0_2);
  console.log("rewardToken0_3: ", rewardToken0_3);
  console.log("rewardToken0_4: ", rewardToken0_4);
  
  var rewardToken1_1 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 1);
  var rewardToken1_2 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 2);
  var rewardToken1_3 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 3);
  var rewardToken1_4 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 4);
  var rewardToken1_5 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 5);
  var rewardToken1_6 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 6);
  
  console.log("rewardToken1_1: ", rewardToken1_1);
  console.log("rewardToken1_2: ", rewardToken1_2);
  console.log("rewardToken1_3: ", rewardToken1_3);
  console.log("rewardToken1_4: ", rewardToken1_4);
  console.log("rewardToken1_5: ", rewardToken1_5);
  console.log("rewardToken1_6: ", rewardToken1_6);

  console.log("balance token0: ", await uniContract.connect(signer2[0]).balanceOf(YfScContract.target));
  console.log("balance token1: ", await wethContract.connect(signer2[0]).balanceOf(YfScContract.target));
  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter collect 1: ", statesCounter);
  return;
  const swapParams219 = {
    tokenOut: UNI_ADDRESS,
    tokenIn: WETH_ADDRESS,
    fee: "3000",
    recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
    deadline: "12265983778560",
    amountIn: "142342342340",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"));

  const tx2119 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams219);
  await tx2119.wait();
  const tx21219 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams219);
  await tx21219.wait();

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter collect 1: ", statesCounter);

  const tx4 = await YfScContract.connect(signer2[2]).collect(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",
    0,
    0,
    external,
    { gasLimit: '2000000' }
  )
  await tx4.wait()

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter collect 2: ", statesCounter);



  originalPoolNftIds = await YfScContract.connect(signer2[0]).originalPoolNftIds(UNI_ADDRESS, WETH_ADDRESS, "3000");
  console.log("originalPoolNftIds: ", originalPoolNftIds);
  var rewardToken0_1 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 1);
  var rewardToken0_2 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 2);
  var rewardToken0_3 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 3);
  var rewardToken0_4 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 4);

  console.log("rewardToken0_1: ", rewardToken0_1);
  console.log("rewardToken0_2: ", rewardToken0_2);
  console.log("rewardToken0_3: ", rewardToken0_3);
  console.log("rewardToken0_4: ", rewardToken0_4);
  
  var rewardToken1_1 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 1);
  var rewardToken1_2 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 2);
  var rewardToken1_3 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 3);
  var rewardToken1_4 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 4);
  
  console.log("rewardToken1_1: ", rewardToken1_1);
  console.log("rewardToken1_2: ", rewardToken1_2);
  console.log("rewardToken1_3: ", rewardToken1_3);
  console.log("rewardToken1_4: ", rewardToken1_4);
  

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();

  var public_reward_0 = await YfScContract.connect(signer2[0]).public_reward_0();
  var public_reward_1 = await YfScContract.connect(signer2[0]).public_reward_1();
  
  console.log("public_reward_0: ", public_reward_0);
  console.log("public_reward_1: ", public_reward_1);
  
  console.log("statesCounter: ", statesCounter);
  // return;

  let _rebalance = false;
  const tx40 = await YfScContract.connect(signer2[2]).decreaseLiquidity( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "50", 
    _rebalance,
    { gasLimit: '1000000' } 
  ) 
  await tx40.wait() 

  var rewardToken0_5 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 5);

  console.log("rewardToken0_5: ", rewardToken0_5);

  var rewardToken1_5 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 5);
  
  console.log("rewardToken1_5: ", rewardToken1_5);
  
  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter decrease liquidity 01 : ", statesCounter);

  _rebalance = false;
  const tx410 = await YfScContract.connect(signer2[1]).decreaseLiquidity( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "50", 
    _rebalance,
    { gasLimit: '1000000' } 
  ) 
  await tx410.wait() 

  var rewardToken0_6 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 6);

  console.log("rewardToken0_6: ", rewardToken0_6);

  var rewardToken1_6 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 6);
  
  console.log("rewardToken1_6: ", rewardToken1_6);
  
  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter decrease liquidity 02 : ", statesCounter);

  _rebalance = false;
  const tx409 = await YfScContract.connect(signer2[2]).decreaseLiquidity( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "100", 
    _rebalance,
    { gasLimit: '1000000' } 
  ) 
  await tx409.wait() 

  var rewardToken0_7 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 7);

  console.log("rewardToken0_7: ", rewardToken0_7);

  var rewardToken1_7 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 7);
  
  console.log("rewardToken1_7: ", rewardToken1_7);
  
  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter decrease liquidity 03 : ", statesCounter);

  _rebalance = false;
  const tx4109 = await YfScContract.connect(signer2[1]).decreaseLiquidity( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "100", 
    _rebalance,
    { gasLimit: '1000000' } 
  ) 
  await tx4109.wait() 

  var rewardToken0_8 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken0(originalPoolNftIds, 8);

  console.log("rewardToken0_8: ", rewardToken0_8);

  var rewardToken1_8 = await StatesVariableContract.connect(signer2[1]).
  getRewardAtStateForNftToken1(originalPoolNftIds, 8);
  
  console.log("rewardToken1_8: ", rewardToken1_8);
  
  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter decrease liquidity 04 : ", statesCounter);

  const poolNftIds = await YfScContract.poolNftIds(UNI_ADDRESS, WETH_ADDRESS, "3000")

  console.log("poolNftIds: ", poolNftIds);

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