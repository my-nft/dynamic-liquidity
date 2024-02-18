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
  UNI: require("../artifacts/contracts/utils.sol/Token.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/positionNFT.sol/PositionsNFT.json"),
  SwapRouter: require("../artifacts/contracts/ISwapRouter.sol/ISwapRouter.json"),
  UniswapV3Pool: require("../artifacts/contracts/IUniswapV3Pool.sol/IUniswapV3Pool.json"),
  Utils: require("../artifacts/contracts/utils.sol/Utils.json"),

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

  let UtilsContract = new ContractFactory(artifacts.Utils.abi, artifacts.Utils.bytecode, signer2[0]);
  UtilsContract = await UtilsContract.deploy(POSITION_MANAGER_ADDRESS);


  let YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, POSITION_MANAGER_ADDRESS, ISWAP_ROUTER, UtilsContract.target);

  // TokenContract = new ContractFactory(artifacts.Token.abi, artifacts.Token.bytecode, signer2[0]);
  // TokenContract = await YfScContract.deploy("Test Token", "TT");

  // UNI_ADDRESS = TokenContract.target;

  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(
    MINTER_ROLE, YfScContract.target,
    { gasLimit: '1000000' }
  )
  await tx.wait()


  

  const tx001 = await YfScContract.connect(signer2[0]).setInitialTicksForPool(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "1",
    "2",
    { gasLimit: '1000000' }
  )
  await tx001.wait()
 

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
    // "1",
    // "2",
    { gasLimit: '2000000' }
  )
  await tx0.wait()

  // const swapParams3 = {
  //   tokenIn: UNI_ADDRESS,
  //   tokenOut: WETH_ADDRESS,
  //   fee: "3000",
  //   recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
  //   deadline: "92265983778560",
  //   amountIn: "34234234234",
  //   amountOutMinimum: "0",
  //   sqrtPriceLimitX96: "0"
  // }

  // await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"))

  // const tx002 = await SwapContract.connect(signer2[0]).exactInputSingle(
  //       swapParams3,
  //       { 
  //           gasLimit: '2000000', 
  //           value: '0'
  //       }
  //   );
  // await tx002.wait()
  // 921758699482278
  // 519594342036717

  await wethContract.connect(signer2[2]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[2]).approve(YfScContract.target, ethers.parseEther("1000"))

  const tx110 = await YfScContract.connect(signer2[2]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "7351019098278",
    "2000000000000", 
    // "1",
    // "2",
    { gasLimit: '2000000' }
  )
  await tx110.wait()

  // const tx10 = await YfScContract.connect(signer2[1]).mintNFT(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "92265983778560",
  //   "10000000000000", 
  //   "1",
  //   "2",
  //   { gasLimit: '2000000' }
  // )
  // await tx10.wait()

  // const tx100 = await YfScContract.connect(signer2[1]).mintNFT(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "10000", 
  //   "92265983778560",
  //   "10000000000000", 
  //   "1",
  //   "2",
  //   { gasLimit: '2000000' }
  // )
  // await tx100.wait()

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

  // const swapParams = {
  //   tokenIn: UNI_ADDRESS,
  //   tokenOut: WETH_ADDRESS,
  //   fee: "3000",
  //   recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
  //   deadline: "92265983778560",
  //   amountIn: "34234234234",
  //   amountOutMinimum: "0",
  //   sqrtPriceLimitX96: "0"
  // }

  // await uniContract.connect(signer2[0]).approve(ISWAP_ROUTER, ethers.parseEther("1000"))

  // const tx2 = await SwapContract.connect(signer2[0]).exactInputSingle(
  //       swapParams,
  //       { 
  //           gasLimit: '2000000', 
  //           value: '0'
  //       }
  //   );
  // await tx2.wait()

  // const swapParams2 = {
  //   tokenOut: WETH_ADDRESS,
  //   tokenIn: UNI_ADDRESS,
  //   fee: "3000",
  //   recipient: "0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0",
  //   deadline: "12265983778560",
  //   amountIn: "14234234234",
  //   amountOutMinimum: "0",
  //   sqrtPriceLimitX96: "0"
  // }

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

  const tx02 = await YfScContract.connect(signer2[0]).updatePosition( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",  
    "3",
    "3",
    { gasLimit: '2000000' } 
  ) 
  await tx02.wait() 

  const public_amount0 = await YfScContract.public_amount0();
  console.log("public_amount0        : ", public_amount0);
  const public_balance0 = await YfScContract.public_balance0();
  console.log("public_balance0       : ", public_balance0);

  const public_adjustedAmount0 = await YfScContract.public_adjustedAmount0();
  console.log("public_adjustedAmount0: ", public_adjustedAmount0);

  const public_amount1 = await YfScContract.public_amount1();
  console.log("public_amount1        : ", public_amount1);
  const public_balance1 = await YfScContract.public_balance1();
  console.log("public_balance1       : ", public_balance1);

  const public_adjustedAmount1 = await YfScContract.public_adjustedAmount1();
  console.log("public_adjustedAmount1: ", public_adjustedAmount1);

  

  const tx020 = await YfScContract.connect(signer2[0]).updatePosition( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",  
    "2",
    "2",
    { gasLimit: '2000000' } 
  ) 
  await tx020.wait() 



  let _rebalance = false;
  const tx40 = await YfScContract.connect(signer2[2]).decreaseLiquidity( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "100", 
    _rebalance,
    { gasLimit: '1000000' } 
  ) 
  await tx40.wait() 

  _rebalance = false;
  const tx410 = await YfScContract.connect(signer2[1]).decreaseLiquidity( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "100", 
    _rebalance,
    { gasLimit: '1000000' } 
  ) 
  await tx410.wait() 

  // _rebalance = false;
  // const tx409 = await YfScContract.connect(signer2[2]).decreaseLiquidity( 
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "100", 
  //   _rebalance,
  //   { gasLimit: '1000000' } 
  // ) 
  // await tx409.wait() 

  // _rebalance = false;
  // const tx4109 = await YfScContract.connect(signer2[1]).decreaseLiquidity( 
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000", 
  //   "100", 
  //   _rebalance,
  //   { gasLimit: '1000000' } 
  // ) 
  // await tx4109.wait() 

  const originalNftId = await YfScContract.originalPoolNftIds(UNI_ADDRESS, WETH_ADDRESS, "3000")

  console.log("originalNftId: ", originalNftId);

  const totalStatesForNft = await YfScContract.totalStatesForNft(originalNftId);

  console.log("totalStatesForNft: ", totalStatesForNft);

  for(var i = 1; i <= totalStatesForNft; i++){
    var coef = await YfScContract.liquidityChangeCoef(originalNftId, i);
    console.log("coef: ", coef);
  }

  const public_userLiquidity = await YfScContract.public_userLiquidity();

  console.log("public_userLiquidity         : ", public_userLiquidity);
  
  const public_userLiquidityCorrected = await YfScContract.public_userLiquidityCorrected();

  console.log("public_userLiquidityCorrected: ", public_userLiquidityCorrected);


  // const public_amount0 = await YfScContract.public_amount0();
  // console.log("public_amount0        : ", public_amount0);

  // const public_adjustedAmount0 = await YfScContract.public_adjustedAmount0();
  // console.log("public_adjustedAmount0: ", public_adjustedAmount0);

  // const public_amount1 = await YfScContract.public_amount1();
  // console.log("public_amount1        : ", public_amount1);

  // const public_adjustedAmount1 = await YfScContract.public_adjustedAmount1();
  // console.log("public_adjustedAmount1: ", public_adjustedAmount1);

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