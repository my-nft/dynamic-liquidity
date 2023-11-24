UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
ISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564"

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

const artifacts = {
  NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
  WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
  UNI: require("../artifacts/contracts/yfsc.sol/Token.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/yfsc.sol/PositionsNFT.json"),
  SwapRouter: require("../artifacts/contracts/ISwapRouter.sol/ISwapRouter.json"),
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

  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, signer2[0]);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, POSITION_MANAGER_ADDRESS, ISWAP_ROUTER);
  
  const tx01 = await YfScContract.connect(signer2[0]).setRates(
    UNI_ADDRESS,
    WETH_ADDRESS,
    "3000",
    "1",
    "2",
    { gasLimit: '2000000' }
  )
  await tx01.wait()

  // const tx001 = await YfScContract.connect(signer2[0]).setTicks(
  //   // "-21960",
  //   "-55512500",
  //   "-55009900",
  //   // "-27060",
  //   // "-20820",
  //   { gasLimit: '1000000' }
  // )
  // await tx001.wait()

  // var tickUpper = await YfScContract.connect(signer2[0]).tickUpper();
  // console.log("tickUpper: ", tickUpper);

  // var tickLower = await YfScContract.connect(signer2[0]).tickLower();
  // console.log("tickLower: ", tickLower);

  // const sqrtPriceToPrice = (sqrtPriceX96, token0Decimals, token1Decimals) => {
  //   let mathPrice = Number(sqrtPriceX96) ** 2 / 2 ** 192;
  //   const decimalAdjustment = 10 ** (token0Decimals - token1Decimals);
  //   const price = mathPrice * decimalAdjustment;
  //   return price;
  // };
  
  const tick1 = await YfScContract.connect(signer2[1]).tickLower()
  console.log("tickLower: ", tick1);
  const tick2 = await YfScContract.connect(signer2[1]).tickUpper()
  console.log("tickUpper: ", tick2);
  // return;
  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(
    MINTER_ROLE, YfScContract.target,
    { gasLimit: '1000000' }
  )
  // await tx.wait()

  console.log("YfScContract address: ", YfScContract.target);
  console.log("PositionsNFTContract address: ", PositionsNFTContract.target);

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))

  await wethContract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[1]).approve(YfScContract.target, ethers.parseEther("1000"))

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const tx0 = await YfScContract.connect(signer2[0]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "92265983778560538",
    "1000000000000000", 
    // "9226598377856050",
    // "1000000000000000", 
    { gasLimit: '2000000' }
  )
  await tx0.wait()

  const tx110 = await YfScContract.connect(signer2[0]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "92265983778560538",
    "1000000000000000", 
    // "9226598377856050",
    // "1000000000000000", 
    { gasLimit: '2000000' }
  )
  await tx110.wait()

  const tx10 = await YfScContract.connect(signer2[0]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "92265983778560538",
    "1000000000000000", 
    // "9226598377856050",
    // "1000000000000000", 
    { gasLimit: '2000000' }
  )
  await tx10.wait()

  const tx1 = await YfScContract.connect(signer2[1]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "9226598377856053",
    "100000000000000", 
    { gasLimit: '2000000' }
  )
  await tx1.wait()

  const tx11 = await YfScContract.connect(signer2[1]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "9226598377856053",
    "100000000000000", 
    { gasLimit: '2000000' }
  )
  await tx11.wait()

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

  await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"))

  const tx2 = await SwapContract.connect(signer2[0]).exactInputSingle(
        swapParams,
        { 
            gasLimit: '2000000', 
            value: '0'
        }
    );
    await tx2.wait()

  const tx3 = await YfScContract.connect(signer2[1]).collect(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",
    0,
    0,
    { gasLimit: '2000000' }
  )
  await tx3.wait()

  const tx4 = await YfScContract.connect(signer2[0]).collect(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",
    0,
    0,
    { gasLimit: '2000000' }
  )
  await tx4.wait()

  // const tx001 = await YfScContract.connect(signer2[0]).setRates(
  //   "40000000000000000", 
  //   "120000000000000000", 
  //   { gasLimit: '2000000' }
  // )
  // await tx001.wait()

  // const tx100 = await YfScContract.connect(signer2[0]).setTicks(
  //   // "-21960",
  //   "-27060",
  //   "-20820",
  //   { gasLimit: '1000000' }
  // )
  // await tx100.wait()

  const tx00 = await YfScContract.connect(signer2[0]).setRates(
    UNI_ADDRESS,
    WETH_ADDRESS,
    "3000",
    "4",
    "5",
    { gasLimit: '2000000' }
  )
  await tx00.wait()

  // const tx01 = await YfScContract.connect(signer2[0]).setRates(
  //   UNI_ADDRESS,
  //   WETH_ADDRESS,
  //   "3000",
  //   "1",
  //   { gasLimit: '2000000' }
  // )
  // await tx01.wait()


  var tickUpper = await YfScContract.connect(signer2[0]).tickUpper();
  console.log("tickUpper: ", tickUpper);

  var tickLower = await YfScContract.connect(signer2[0]).tickLower();
  console.log("tickLower: ", tickLower);

  const tx02 = await YfScContract.connect(signer2[0]).updatePosition( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",  
    { gasLimit: '2000000' } 
  ) 
  await tx02.wait() 
  console.log("update position: ", tx02); 

  const uniNftId = await YfScContract.connect(signer2[0]).poolNftIds(UNI_ADDRESS, WETH_ADDRESS, "3000")
  console.log("uniNftId: ", uniNftId);
  const positionNftId1 = await PositionsNFTContract.connect(signer2[0]).getUserNftPerPool("0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0", uniNftId)
  const positionNftId2 = await PositionsNFTContract.connect(signer2[0]).getUserNftPerPool("0xD54f6DBde8E90DB546a0Af3bB4d27DFDe0a269ff", uniNftId)
  console.log("positionNftId1: ", positionNftId1);
  console.log("positionNftId2: ", positionNftId2);
  const totalStatesForPosition1 = await PositionsNFTContract.connect(signer2[0]).totalStatesForPosition(positionNftId1)
  const totalStatesForPosition2 = await PositionsNFTContract.connect(signer2[0]).totalStatesForPosition(positionNftId2)
  console.log("totalStatesForPosition1: ", totalStatesForPosition1);
  console.log("totalStatesForPosition2: ", totalStatesForPosition2);
  console.log("");
  console.log("liquidity for position ------> ", positionNftId1)
  for(var  ind = 0; ind <= parseInt(totalStatesForPosition1); ind++){
    console.log("position state id   : ", ind);
    var stateIdForPosition = await PositionsNFTContract.connect(signer2[0]).statesIdsForPosition(positionNftId1, ind);
    console.log("global state id     : ", stateIdForPosition);
    var liquidityAtState = await PositionsNFTContract.connect(signer2[0]).liquidityForUserInPoolAtState(positionNftId1, stateIdForPosition);
    console.log("liquidityAtState    : ", liquidityAtState);
    var poolLiquidityAtState = await YfScContract.connect(signer2[0]).getTotalLiquidityAtStateForPosition(uniNftId, stateIdForPosition);
    console.log("poolLiquidityAtState: ", poolLiquidityAtState);
  }
  console.log("");
  console.log("liquidity for position ------> ", positionNftId2)
  for(var  ind = 0; ind <= parseInt(totalStatesForPosition2); ind++){
    console.log("position state id   : ", ind);
    var stateIdForPosition = await PositionsNFTContract.connect(signer2[0]).statesIdsForPosition(positionNftId2, ind);
    console.log("global state id     : ", stateIdForPosition);
    var liquidityAtState = await PositionsNFTContract.connect(signer2[0]).liquidityForUserInPoolAtState(positionNftId2, stateIdForPosition);
    console.log("liquidityAtState    : ", liquidityAtState);
    var poolLiquidityAtState = await YfScContract.connect(signer2[0]).getTotalLiquidityAtStateForPosition(uniNftId, stateIdForPosition);
    console.log("poolLiquidityAtState: ", poolLiquidityAtState);
  }

  const pendingrewardForPosition1 = await YfScContract.connect(signer2[0]).getPendingrewardForPosition(UNI_ADDRESS, WETH_ADDRESS, "3000");
  console.log("pendingrewardForPosition1: ", pendingrewardForPosition1);

  const pendingrewardForPosition2 = await YfScContract.connect(signer2[1]).getPendingrewardForPosition(UNI_ADDRESS, WETH_ADDRESS, "3000");
  console.log("pendingrewardForPosition2: ", pendingrewardForPosition2);

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