const { Contract } = require("ethers");
const { getAddresses, artifacts } = require("./addresses.js");
const { get_amounts, get_liquidity } = require('./core.js');
const {getAmountsForLiquidityRange, tickMath} = require('@thanpolas/univ3prices');


const { priceToClosestTick, TICK_SPACINGS, nearestUsableTick, Position, NonfungiblePositionManager, MintOptions, Pool } = require("@uniswap/v3-sdk")
const { BigIntish, Percent } = require('@uniswap/sdk-core')

const addresses = getAddresses(hre.network.name);

t0 = "UNI"
t1 = "WETH"
T0 = addresses[t0]
T1 = addresses[t1]

feeTier = "3000"

POSITION_MANAGER_ADDRESS =  addresses['POSITION_MANAGER_ADDRESS']
ISWAP_ROUTER             =  addresses['ISWAP_ROUTER']
UV3Factory_address       =  addresses['UniswapV3Factory']


async function getToken(token_name,tokenAddress, provider) {
  const contractName = token_name === 'WETH' ? token_name : 'ERC20';

  const tokenContract = new ethers.Contract(tokenAddress, artifacts[contractName].abi, provider);
  return await tokenContract;
}

async function main() {
  const signer = await ethers.getSigners();
  const user = signer[0].address;
  console.log("user:", user);

  const provider = ethers.provider

  const uniswapV3Factory = new Contract(UV3Factory_address, artifacts.UniswapV3Factory.abi, provider);

  const poolAddr = await uniswapV3Factory.getPool(T0, T1, feeTier);
  console.log("pool Addr:", poolAddr);

  const poolContract = new Contract(poolAddr, artifacts.UniswapV3Pool.abi, provider);

  const tickSpacing = await poolContract.tickSpacing();
  const fT = await poolContract.fee();

  const slot0 = await poolContract.slot0();
  const currentTick  = Number(slot0.tick);
  const currentPrice = Number(Math.pow(1.0001, currentTick));
  const liquidity = await poolContract.liquidity();

  console.log("Tick Spacing     :", Number(tickSpacing));
  console.log("feeTier          :", Number(fT));
  console.log("Current Tick     :", currentTick);
  console.log("Current Price    :", currentPrice);
  console.log("Current Liquidity:", Number(liquidity));


  // or priceToClosestTick(targetPrice) if range come from price not tick first
  const newTickLower = -887272 // nearestUsableTick(currentTick - 2 * Number(tickSpacing), TICK_SPACINGS[feeTier]);
  const newTickUpper = 887272 // nearestUsableTick(currentTick + 2 * Number(tickSpacing), TICK_SPACINGS[feeTier]);

  // Calculate the square root values for the price range
  const newPriceLower = Number(Math.pow(1.0001, newTickLower));
  const newPriceUpper = Number(Math.pow(1.0001, newTickUpper));

  console.log(`New Tick Range : ${newTickLower} - ${newTickUpper}`);
  console.log(`New Price Range: ${newPriceLower} - ${newPriceUpper}`);

  const token0 = await getToken(t0, T0, provider);
  const token1 = await getToken(t1, T1, provider);

  const token0Decimals = await token0.decimals();
  const token1Decimals = await token1.decimals();

  console.log(`Token 0 decimals:${token0Decimals}| Token 1 decimals :${token1Decimals}`);

  // Not 100% precise
  const [amount0, amount1] = get_amounts(
    currentPrice, newPriceLower, newPriceUpper,
    Number(liquidity) * Number(0.0001),
    Number(token0Decimals),
    Number(token1Decimals)
  );
  console.log(`amount 0 :${amount0}| amount 1 :${amount1}`);

  // 100% precise
  let sqrtPriceX96 = slot0.sqrtPriceX96.toString()
  let sqrtPriceLX96 = tickMath.getSqrtRatioAtTick(newTickLower);
  let sqrtPriceUX96 = tickMath.getSqrtRatioAtTick(newTickUpper);  

  const [amount0_b, amount1_b] = getAmountsForLiquidityRange(sqrtPriceX96, sqrtPriceLX96, sqrtPriceUX96, (Number(liquidity) * Number(0.0001)).toString());

  a0 = Number(amount0_b) * Number(10**-18)
  a1 = Number(amount1_b) * Number(10**-18)
  console.log(`amount 0 :${Math.round(a0 * 10**7) / 10**7}| amount 1 :${Math.round(a1 * 10**7) / 10**7}`);


  const positionManagerContract = new Contract(POSITION_MANAGER_ADDRESS, artifacts['NonfungiblePositionManager'].abi, provider);
  /*
  const configuredPool = Pool(
    tocken0,
    tocken1,
    3000,
    slot0.sqrtPriceX96.toString(),
    liquidity.toString(),
    Number(slot0.tick),
  )
  console.log('Pool')

  const position = Position.fromAmounts({
    pool: configuredPool,
    tickLower: newTickLower,
    tickUpper: newTickUpper,
    amount0: amount0,
    amount1: amount1,
    useFullPrecision: false,
  })
  
  const mintOptions = {recipient: user,
    deadline: Math.floor(Date.now() / 1000) + 60 * 20,
    slippageTolerance: new Percent(50, 10_000),
  }
  
  // get calldata for minting a position
  const { calldata, value } = NonfungiblePositionManager.addCallParameters(position, mintOptions)

  const transaction = {
    data: calldata,
    to: POSITION_MANAGER_ADDRESS,
    value: value,
    from: user,
    maxFeePerGas: 100000000000,
    maxPriorityFeePerGas: 100000000000,
  }
  const wallet = new ethers.Wallet("a89f7441836ce5818eb957dcd43256211749ee0e7b775d57022de8728d5964f7", provider)

  const txRes = await wallet.sendTransaction(transaction)

  let receipt = null
  let mintCallOutput

  while (receipt === null) {
    try {
      receipt = await provider.getTransactionReceipt(txRes.hash);

      if (receipt === null) {
        continue;
      } else {
        const callTraces = await provider.send("trace_transaction", [txRes.hash]);
        mintCallOutput = callTraces[0].result.output;
      }
    } catch (e) {
      break;
    }
  }
  */
  
  // const tx2 = await poolContract.connect(signer[0]).mint(String(user), BigInt(newTickUpper), BigInt(newTickLower), BigInt(amount0_b))
  // await tx2.wait();

  const nftID = "79442";
  const position = await positionManagerContract.positions(nftID);

  // const previousTickLower = Number(position.tickLower);
  // const previousTickUpper = Number(position.tickUpper);

  // const prevPriceLower = Math.pow(1.0001, previousTickLower);
  // const prevPriceUpper = Math.pow(1.0001, previousTickUpper);

  // console.log(`previous Tick Range : ${previousTickLower}, ${previousTickUpper}`);
  // console.log(`previous Price Range: ${prevPriceLower}, ${prevPriceUpper}`);

  // console.log("Position Details:");
  // console.log("Token0 Address:", position.token0);
  // console.log("Token1 Address:", position.token1);
  // console.log("Fee       :", position.fee.toString());
  // console.log("Liquidity:", position.liquidity.toString());
  // console.log("Fee Growth Inside 0 Last X128:", position.feeGrowthInside0LastX128.toString());
  // console.log("Fee Growth Inside 1 Last X128:", position.feeGrowthInside1LastX128.toString());
  // console.log("Tokens Owed 0:", position.tokensOwed0.toString());
  // console.log("Tokens Owed 1:", position.tokensOwed1.toString());

  // const tx = await positionManagerContract.connect(signer[0]).burn(nftID);
  // await tx.wait();
  // console.log("NFT burned");

  /* function: mint
  inputs: {
    token0: address        
    token1: address       
    fee: uint24        
    tickLower: int24       
    tickUpper: int24     
    amount0Desired: uint256        
    amount1Desired: uint256   
    amount0Min: uint256       
    amount1Min: uint256       
    recipient: address      
    deadline: uint256
  }
  */

  const block = await provider.getBlock('latest')
  const deadline = block.timestamp + 3000;

  const tx2 = await positionManagerContract.connect(signer[0]).mint(
    String(T0), String(T1), Number(feeTier),
    Number(newTickLower), Number(newTickUpper),
    Number(amount0_b), Number(amount1_b),
    0, 0,
    String(user), Number(deadline));
  await tx2.wait();

  console.log("tokenId  :", tx2.tokenId);
  console.log("liquidity:", tx2.liquidity);
  console.log("amount0  :", tx2.amount0);
  console.log("amount1  :", tx2.amount1);

  console.log("NFT minted");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
