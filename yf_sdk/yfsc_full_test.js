const { Contract, ContractFactory } = require("ethers");
const { ethers } = require("hardhat");
const { getAddresses, artifacts } = require("./addresses.js");
const addresses = getAddresses(hre.network.name);

t0      = "UNI"
t1      = "WETH"
feeTier = "3000"

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"


async function main() {
  const signer2  = await ethers.getSigners();
  const provider = ethers.provider
  const signer_address = await signer2[0].getAddress()
  const network = hre.network.name

  console.log("network: ", network);
  console.log("Token0: ", t0);
  console.log("Token1: ", t1);
  console.log("feeTier: ", feeTier);
  console.log("signer:", signer_address);
  console.log("")

  const SwapContract = new Contract(addresses['ISWAP_ROUTER'], artifacts.SwapRouter.abi, provider)
  // const UniswapV3PoolContract = new Contract(addresses['UNISWAP_V3_Pool'], artifacts.UniswapV3Pool.abi, provider)


  console.log("Deploying Positions NFT Contract ...")
  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, signer2[0]);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  console.log("Deploying Utils Contract ...")
  let UtilsContract = new ContractFactory(artifacts.Utils.abi, artifacts.Utils.bytecode, signer2[0]);
  UtilsContract = await UtilsContract.deploy(addresses['POSITION_MANAGER_ADDRESS']);

  console.log("Deploying YfSc Contract ...")
  let YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, addresses['POSITION_MANAGER_ADDRESS'], UtilsContract.target);
  
  console.log("Deploying States Variable Contract ...")
  let StatesVariableContract = new ContractFactory(artifacts.StatesVariables.abi, artifacts.StatesVariables.bytecode, signer2[0]);
  StatesVariableContract = await StatesVariableContract.deploy(PositionsNFTContract.target, addresses['POSITION_MANAGER_ADDRESS'], YfScContract.target, addresses['ISWAP_ROUTER']);
  
  console.log("PositionsNFTContract address : ", PositionsNFTContract.target);
  console.log("Utils Contract       address : ", UtilsContract.target);
  console.log("YfSc Contract        address : ", YfScContract.target);
  console.log("States Variable      address : ", StatesVariableContract.target);
  console.log("")
  console.log("")

  console.log("Granting Minter Role to YfScContract ...")
  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(MINTER_ROLE, YfScContract.target, {gasLimit:'1000000'})
  await tx.wait()
  console.log("")

  console.log("Granting Minter Role to StatesVariableContract ...")
  const tx9 = await PositionsNFTContract.connect(signer2[0]).grantRole(MINTER_ROLE, StatesVariableContract.target, {gasLimit:'1000000'})
  await tx9.wait()
  console.log("")

  console.log("Setting StatesVariableContract as owner of YfScContract ...")
  const tx10 = await YfScContract.connect(signer2[0]).setStatesVariables(StatesVariableContract.target, {gasLimit: '1000000'})
  await tx10.wait()
  console.log("")

  const tickUpper = "10"
  const tickLower = "10"
  console.log("Setting Upper and Lower ticks to ", tickUpper, tickLower)
  const tx001 = await StatesVariableContract.connect(signer2[0]).setInitialTicksForPool(addresses[t0], addresses[t1], feeTier, 
    tickUpper, tickLower, {gasLimit: '1000000'})
  await tx001.wait()
  console.log("")


  const token1_Contract = new Contract(addresses[t1], artifacts[t1].abi, provider)
  const token0_Contract  = new Contract(addresses[t0], artifacts[t0].abi, provider)

  await token1_Contract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"));
  await token0_Contract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"));

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10);
  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter starting at : ", statesCounter);
  console.log("")
  console.log("")

  console.log("Minting NFT 1 ...")
  const tx0 = await YfScContract.connect(signer2[1]).mintNFT(addresses[t0], addresses[t1], feeTier,
    "5351019098", "1000000000000", { gasLimit: '2000000' })
  console.log("NFT 1 minted with tx: ", tx0.hash);
  await tx0.wait()

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter after mint 1: ", statesCounter);
  console.log("")

  await token1_Contract.connect(signer2[2]).approve(YfScContract.target, ethers.parseEther("1000"));
  await token0_Contract.connect(signer2[2]).approve(YfScContract.target, ethers.parseEther("1000"));

  console.log("Minting NFT 2 ...")
  const tx110 = await YfScContract.connect(signer2[2]).mintNFT(addresses[t0], addresses[t1], feeTier,
    "735101909", "2000000000000", {gasLimit: '2000000'})
  console.log("NFT 2 minted with tx: ", tx110.hash);
  await tx110.wait()

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter after mint 2: ", statesCounter);
  console.log("")

  const swapParams2 = {
    tokenOut: addresses[t0],
    tokenIn: addresses[t1],
    fee: feeTier,
    recipient: signer_address,
    amountIn: "10000000000000000",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  await token1_Contract.connect(signer2[0]).approve(addresses['ISWAP_ROUTER'], ethers.parseEther("1000"));
  await token0_Contract.connect(signer2[0]).approve(addresses['ISWAP_ROUTER'], ethers.parseEther("1000"));

  // const allowance = await token1_Contract.allowance(signer2[0], addresses['ISWAP_ROUTER']);
  // console.log("allowance: ", allowance);
  // console.log("SwapContract: ", SwapContract);
  
  console.log("")
  console.log("")
  console.log("Swapping ...")
  console.log("swapParams2: ", swapParams2);
  const tx21 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams2, { gasLimit: "3000000" });
  await tx21.wait();

  console.log("Another Swap with same parameters ...")
  const tx22 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams2);
  await tx22.wait();
  console.log("")

  const swapParams21 = {
    tokenOut: addresses[t0],
    tokenIn: addresses[t1],
    fee: feeTier,
    recipient: signer_address,
    deadline: "12265983778560",
    amountIn: "142342342340",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }

  console.log("")
  console.log("Swapping 4 more times ...")
  const tx211 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  await tx211.wait();

  const tx2121 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  await tx2121.wait();

  const tx2112 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  await tx2112.wait()

  const tx212 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
  await tx212.wait()

  console.log("")
  console.log("Updating position with 3 to ticks upper and lower spacing to current price")
  const tx02 = await YfScContract.connect(signer2[0]).updatePosition(addresses[t0], addresses[t1], feeTier,
    "3", "3", {gasLimit: '2000000'})
  await tx02.wait()

  console.log("")
  console.log("Updating position with 2 to ticks upper and lower spacing to current price")
  const tx020 = await YfScContract.connect(signer2[0]).updatePosition(addresses[t0], addresses[t1], feeTier,
    "2", "2", {gasLimit: '2000000'})
  await tx020.wait()
  console.log("")

  console.log("")
  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter update 01: ", statesCounter);

  console.log("")
  const balanceToken0 = await token0_Contract.connect(signer2[0]).balanceOf(YfScContract.target);
  const balanceToken1 = await token1_Contract.connect(signer2[0]).balanceOf(YfScContract.target);

  console.log("balance token0: ", ethers.utils.formatEther(balanceToken0));
  console.log("balance token1: ", ethers.utils.formatEther(balanceToken1));
  console.log("")
  console.log("")

  let rebalance = false;
  let external  = true;

  const tx3 = await YfScContract.connect(signer2[1]).collect(addresses[t0], addresses[t1], feeTier,
    0, 0, rebalance, external, {gasLimit: '2000000'})
  await tx3.wait()

  const tx31 = await YfScContract.connect(signer2[2]).collect(addresses[t0], addresses[t1], feeTier,
    0, 0, rebalance, external, {gasLimit: '2000000'})
  await tx31.wait()

  var pendingReward0 = await YfScContract.connect(signer2[1]).getPendingrewardForPosition(addresses[t0], addresses[t1], feeTier);
  console.log("pendingReward0: ", ethers.utils.formatEther(pendingReward0));

  var pendingReward1 = await YfScContract.connect(signer2[2]).getPendingrewardForPosition(addresses[t0], addresses[t1], feeTier);
  console.log("pendingReward1: ", ethers.utils.formatEther(pendingReward1));

  let originalPoolNftIds = await YfScContract.connect(signer2[0]).originalPoolNftIds(addresses[t0], addresses[t1], feeTier);
  console.log("originalPoolNftIds: ", originalPoolNftIds);

  var rewardToken0_1 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 1);
  var rewardToken0_2 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 2);
  var rewardToken0_3 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 3);
  var rewardToken0_4 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 4);

  console.log("rewardToken0_1: ", ethers.utils.formatEther(rewardToken0_1));
  console.log("rewardToken0_2: ", ethers.utils.formatEther(rewardToken0_2));
  console.log("rewardToken0_3: ", ethers.utils.formatEther(rewardToken0_3));
  console.log("rewardToken0_4: ", ethers.utils.formatEther(rewardToken0_4));

  var rewardToken1_1 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 1);
  var rewardToken1_2 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 2);
  var rewardToken1_3 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 3);
  var rewardToken1_4 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 4);
  var rewardToken1_5 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 5);
  var rewardToken1_6 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 6);

  console.log("rewardToken1_1: ", ethers.utils.formatEther(rewardToken1_1));
  console.log("rewardToken1_2: ", ethers.utils.formatEther(rewardToken1_2));
  console.log("rewardToken1_3: ", ethers.utils.formatEther(rewardToken1_3));
  console.log("rewardToken1_4: ", ethers.utils.formatEther(rewardToken1_4));
  console.log("rewardToken1_5: ", ethers.utils.formatEther(rewardToken1_5));
  console.log("rewardToken1_6: ", ethers.utils.formatEther(rewardToken1_6));

  console.log("balance token0: ", await token0_Contract.connect(signer2[0]).balanceOf(YfScContract.target));
  console.log("balance token1: ", await token1_Contract.connect(signer2[0]).balanceOf(YfScContract.target));

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter collect 1: ", statesCounter);

  const swapParams219 = {
    tokenOut: addresses[t0],
    tokenIn: addresses[t1],
    fee: feeTier,
    recipient: signer_address,
    deadline: "12265983778560",
    amountIn: "142342342340",
    amountOutMinimum: "0",
    sqrtPriceLimitX96: "0"
  }
  await token0_Contract.connect(signer2[0]).approve(addresses['ISWAP_ROUTER'], ethers.parseEther("1000"));

  const tx2119 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams219);
  await tx2119.wait();
  const tx21219 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams219);
  await tx21219.wait();

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter collect 1: ", statesCounter);

  const tx4 = await YfScContract.connect(signer2[2]).collect(addresses[t0], addresses[t1], feeTier,
    0, 0, external, {gasLimit: '2000000'})
  await tx4.wait()

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter collect 2: ", statesCounter);


  originalPoolNftIds = await YfScContract.connect(signer2[0]).originalPoolNftIds(addresses[t0], addresses[t1], feeTier,);
  console.log("originalPoolNftIds: ", originalPoolNftIds);

  var rewardToken0_1 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 1);
  var rewardToken0_2 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 2);
  var rewardToken0_3 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 3);
  var rewardToken0_4 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 4);

  console.log("rewardToken0_1: ", ethers.utils.formatEther(rewardToken0_1));
  console.log("rewardToken0_2: ", ethers.utils.formatEther(rewardToken0_2));
  console.log("rewardToken0_3: ", ethers.utils.formatEther(rewardToken0_3));
  console.log("rewardToken0_4: ", ethers.utils.formatEther(rewardToken0_4));

  var rewardToken1_1 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 1);
  var rewardToken1_2 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 2);
  var rewardToken1_3 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 3);
  var rewardToken1_4 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 4);

  console.log("rewardToken1_1: ", ethers.utils.formatEther(rewardToken1_1));
  console.log("rewardToken1_2: ", ethers.utils.formatEther(rewardToken1_2));
  console.log("rewardToken1_3: ", ethers.utils.formatEther(rewardToken1_3));
  console.log("rewardToken1_4: ", ethers.utils.formatEther(rewardToken1_4));

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();

  console.log("statesCounter: ", statesCounter);

  let _rebalance = false;
  // const tx40 = await YfScContract.connect(signer2[2]).decreaseLiquidity(addresses[t0], addresses[t1], feeTier,
  //   "50", _rebalance, {gasLimit: '1000000'}) 
  // await tx40.wait() 

  var rewardToken0_5 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 5);
  console.log("rewardToken0_5: ", ethers.utils.formatEther(rewardToken0_5));

  var rewardToken1_5 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 5);
  console.log("rewardToken1_5: ", ethers.utils.formatEther(rewardToken1_5));

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter decrease liquidity 01 : ", statesCounter);

  _rebalance = false;
  // const tx410 = await YfScContract.connect(signer2[1]).decreaseLiquidity(addresses[t0], addresses[t1], feeTier,
  //   "50", _rebalance, {gasLimit: '1000000'}) 
  // await tx410.wait() 

  var rewardToken0_6 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 6);
  console.log("rewardToken0_6: ", ethers.utils.formatEther(rewardToken0_6));

  var rewardToken1_6 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 6);
  console.log("rewardToken1_6: ", ethers.utils.formatEther(rewardToken1_6));

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter decrease liquidity 02 : ", statesCounter);

  _rebalance = false;
  const tx409 = await YfScContract.connect(signer2[2]).decreaseLiquidity(addresses[t0], addresses[t1], feeTier,
    "100", _rebalance, {gasLimit: '1000000'})
  await tx409.wait()

  var rewardToken0_7 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 7);
  console.log("rewardToken0_7: ", ethers.utils.formatEther(rewardToken0_7));

  var rewardToken1_7 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 7);
  console.log("rewardToken1_7: ", ethers.utils.formatEther(rewardToken1_7));

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter decrease liquidity 03 : ", statesCounter);

  _rebalance = false;
  const tx4109 = await YfScContract.connect(signer2[1]).decreaseLiquidity(addresses[t0], addresses[t1], feeTier,
    "100", _rebalance, {gasLimit: '1000000'})
  await tx4109.wait()

  var rewardToken0_8 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 8);
  console.log("rewardToken0_8: ", ethers.utils.formatEther(rewardToken0_8));

  var rewardToken1_8 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 8);
  console.log("rewardToken1_8: ", ethers.utils.formatEther(rewardToken1_8));

  var statesCounter = await StatesVariableContract.connect(signer2[0]).getStatesCounter();
  console.log("statesCounter decrease liquidity 04 : ", statesCounter);

  const poolNftIds = await YfScContract.poolNftIds(addresses[t0], addresses[t1], feeTier,)

  // const tx020 = await YfScContract.connect(signer2[0]).withdraw(addresses[t0], {gasLimit: '200000'}) 
  // await tx020.wait() 

  // const tx0200 = await YfScContract.connect(signer2[0]).withdraw(addresses[t1], {gasLimit: '200000'}) 
  // await tx0200.wait() 
}


main().then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });