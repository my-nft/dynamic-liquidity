const hhEthers = require("hardhat").ethers;
const { Contract, ContractFactory, utils, BigNumber  } = require("ethers")
const { getAddresses, artifacts } = require("/Users/armandmorin/Downloads/dynamic-liquidity-main/scripts/addresses.js");

const addresses = getAddresses(hre.network.name);

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

async function main() {
  const T1 = 'UNI';
  const T0 = 'WETH';
  const fee = "3000"
  const provider = ethers.provider
  const signer2 = await ethers.getSigners();
  const user = signer2[0].address;
  console.log("user:", user);

  const token0_adr = addresses[T0]
  const token1_adr = addresses[T1]
  console.log(`Token 0: ${T0} @ : ${token0_adr}`);
  console.log(`Token 1: ${T1} @ : ${token1_adr}`);

  // const uniswapV3Factory = await hhEthers.getContractAt("IUniswapV3Factory",addresses['UniswapV3Factory']);

  // const poolAddr_3000 = await uniswapV3Factory.getPool(token0_adr, token1_adr, '3000');
  // const poolAddr_500  = await uniswapV3Factory.getPool(token0_adr, token1_adr, '500');
  // console.log(`Pool address 3000 : ${poolAddr_3000} --|-- 500 : ${poolAddr_500}`);

  const SwapContract = new Contract(addresses['ISWAP_ROUTER'], artifacts.SwapRouter.abi, provider)

  // deploy new NFT position Manager
  // PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, user);
  // PositionsNFTContract = await PositionsNFTContract.deploy();

  // deploy new YFSC
  // YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, user);
  // YfScContract = await YfScContract.deploy(PositionsNFTContract.target, POSITION_MANAGER_ADDRESS, addresses['ISWAP_ROUTER']);

  // load contract YFSC & YF PM
  
  const PositionsNFTContract = new Contract(addresses['YF_POSITION_NFT'], artifacts.PositionsNFT.abi, user);
  const YfScContract = new Contract(addresses['YF_SC'], artifacts.YfSc.abi, user);

  ticksUpToSend   = "1";
  ticksDownToSend = "2";

  var previousLR = await YfScContract.connect(user).tickLower();
  var previousUR = await YfScContract.connect(user).tickUpper();
  console.log(previousLR);
  const tx01 = await YfScContract.connect(user).setRates(token0_adr, token1_adr, fee, "1", "2", { gasLimit: '2000000' })
  await tx01.wait()

  const tx = await PositionsNFTContract.connect(user).grantRole(MINTER_ROLE, YfScContract.target, {gasLimit:'1000000'})
  await tx.wait()

  // const tx001 = await YfScContract.connect(user).setTicks(
  //   // "-21960",
  //   "-55512500",
  //   "-55009900",
  //   // "-27060",
  //   // "-20820",
  //   { gasLimit: '1000000' }
  // )
  // await tx001.wait()
  // const sqrtPriceToPrice = (sqrtPriceX96, token0Decimals, token1Decimals) => {
  //   let mathPrice = Number(sqrtPriceX96) ** 2 / 2 ** 192;
  //   const decimalAdjustment = 10 ** (token0Decimals - token1Decimals);
  //   const price = mathPrice * decimalAdjustment;
  //   return price;
  // };
  
  const tick1 = await YfScContract.connect(user).tickLower()
  const tick2 = await YfScContract.connect(user).tickUpper()

  console.log("Previous tickLower: ", Number(previousLR));
  console.log("Previous tickUpper: ", Number(previousUR));
  console.log("Current  tickLower: ", Number(tick1));
  console.log("Current  tickUpper: ", Number(tick2));
  console.log("YfScContract address        : ", YfScContract.target);
  console.log("PositionsNFTContract address: ", PositionsNFTContract.target);

  const Token0_Contract = new Contract(token0_adr,artifacts[T0].abi,provider)
  const Token1_Contract = new Contract(token1_adr,artifacts[T1].abi,provider)

  await Token0_Contract.connect(user).approve(YfScContract.target, ethers.parseEther("1000"))
  await Token1_Contract.connect(user).approve(YfScContract.target, ethers.parseEther("1000"))

  const tx0 = await YfScContract.connect(user).mintNFT(token0_adr, token1_adr, fee, "92265983778560538", "1000000000000000", {gasLimit: '2000000'})
  await tx0.wait()

  const tx110 = await YfScContract.connect(user).mintNFT(token0_adr, token1_adr, fee, "92265983778560538", "1000000000000000", { gasLimit: '2000000'})
  await tx110.wait()

  const tx10 = await YfScContract.connect(user).mintNFT(token0_adr, token1_adr, fee, "92265983778560538", "1000000000000000", {gasLimit:'2000000'})
  await tx10.wait()

  const swapParams = {tokenIn: token0_adr, tokenOut: token1_adr, fee: fee,
    recipient: user, deadline: "92265983778560", amountIn: "34234234234", amountOutMinimum: "0", sqrtPriceLimitX96: "0"}

  await Token0_Contract.connect(user).approve(addresses['ISWAP_ROUTER'], ethers.parseEther("1000"))

  // perform swap to generate some fees
  const tx2 = await SwapContract.connect(user).exactInputSingle(swapParams,{ gasLimit: '2000000', value: '0'});
  await tx2.wait()

  // collect fees generated
  const tx4 = await YfScContract.connect(user).collect(token0_adr, token1_adr, fee, 0, 0, {gasLimit:'2000000'})
  await tx4.wait()

  // rebalance again
  var previousUR = await YfScContract.connect(user).tickUpper();
  var previousLR = await YfScContract.connect(user).tickLower();

  const tx00 = await YfScContract.connect(user).setRates(token0_adr, token1_adr, fee, "4",  "5", {gasLimit:'2000000'})
  await tx00.wait()

  var tickUpper = await YfScContract.connect(user).tickUpper();
  var tickLower = await YfScContract.connect(user).tickLower();

  console.log("Previous tickLower: ", Number(previousLR));
  console.log("Previous tickUpper: ", Number(previousUR));
  console.log("tickUpper: ", tickUpper);
  console.log("tickLower: ", tickLower);

  const tx02 = await YfScContract.connect(user).updatePosition(token0_adr, token1_adr, fee, {gasLimit:'1000000'}) 
  await tx02.wait() 
  console.log("update position: ", tx02); 

  const uniNftId = await YfScContract.connect(user).poolNftIds(token0_adr, token1_adr, fee)
  console.log("uniNftId: ", Number(uniNftId));

  const pool_address_1 = "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0";
  const pool_address_2 = "0xD54f6DBde8E90DB546a0Af3bB4d27DFDe0a269ff";
  const positionNftId1 = await PositionsNFTContract.connect(user).getUserNftPerPool(pool_address_1, uniNftId)
  const positionNftId2 = await PositionsNFTContract.connect(user).getUserNftPerPool(pool_address_2, uniNftId)
  console.log("positionNftId1: ", Number(positionNftId1));
  console.log("positionNftId2: ", Number(positionNftId2));

  const totalStatesForPosition1 = await PositionsNFTContract.connect(user).totalStatesForPosition(positionNftId1)
  const totalStatesForPosition2 = await PositionsNFTContract.connect(user).totalStatesForPosition(positionNftId2)
  console.log("totalStatesForPosition1: ", Number(totalStatesForPosition1));
  console.log("totalStatesForPosition2: ", Number(totalStatesForPosition2));


  console.log("");
  console.log("liquidity for position ------> ", Number(positionNftId1))

  for(var  ind = 0; ind <= parseInt(totalStatesForPosition1); ind++){
    var stateIdForPosition = await PositionsNFTContract.connect(user).statesIdsForPosition(positionNftId1, ind);
    var liquidityAtState = await PositionsNFTContract.connect(user).liquidityForUserInPoolAtState(positionNftId1, stateIdForPosition);
    var poolLiquidityAtState = await YfScContract.connect(user).getTotalLiquidityAtStateForPosition(uniNftId, stateIdForPosition);

    console.log("position state id   : ", Number(ind));
    console.log("global state id     : ", Number(stateIdForPosition));
    console.log("liquidityAtState    : ", Number(liquidityAtState));
    console.log("poolLiquidityAtState: ", Number(poolLiquidityAtState));
  }

  
  console.log("");
  console.log("liquidity for position ------> ", Number(positionNftId2))

  for(var  ind = 0; ind <= parseInt(totalStatesForPosition2); ind++){
    var stateIdForPosition = await PositionsNFTContract.connect(user).statesIdsForPosition(positionNftId2, ind);
    var liquidityAtState = await PositionsNFTContract.connect(user).liquidityForUserInPoolAtState(positionNftId2, stateIdForPosition);
    var poolLiquidityAtState = await YfScContract.connect(user).getTotalLiquidityAtStateForPosition(uniNftId, stateIdForPosition);

    console.log("position state id   : ",  Number(ind));
    console.log("global state id     : ", Number(stateIdForPosition));
    console.log("liquidityAtState    : ", Number(liquidityAtState));
    console.log("poolLiquidityAtState: ", Number(poolLiquidityAtState));
  }

  const pendingrewardForPosition1 = await YfScContract.connect(user).getPendingrewardForPosition(token0_adr, token1_adr, fee);
  console.log("pendingrewardForPosition1: ", pendingrewardForPosition1);
}

main().then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });