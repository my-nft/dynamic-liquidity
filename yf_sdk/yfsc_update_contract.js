const { Contract } = require("ethers");
const toml = require("toml");
const fs = require("fs");
const path = require("path");

const { getAddresses, artifacts } = require("./addresses.js");
const {getAmountsForLiquidityRange, tickMath} = require("@thanpolas/univ3prices");
const {priceToClosestTick, TICK_SPACINGS, nearestUsableTick, Position, NonfungiblePositionManager, MintOptions, Pool} = require("@uniswap/v3-sdk");
const { BigIntish, Percent } = require("@uniswap/sdk-core");

const addresses = getAddresses(hre.network.name);

POSITION_MANAGER_ADDRESS = addresses["POSITION_MANAGER_ADDRESS"];
ISWAP_ROUTER = addresses["ISWAP_ROUTER"];
UV3Factory_address = addresses["UniswapV3Factory"];
YF_SC = addresses["YF_SC"];


/**
 * Calculate token amounts for a given liquidity range in a Uniswap v3 pool.
 *
 * @param {string} poolAddress - The address of the Uniswap v3 pool.
 * @param {number} tickLower - The lower tick of the liquidity range.
 * @param {number} tickUpper - The upper tick of the liquidity range.
 * @param {number} liquidityPercent - The percentage of the pool's liquidity to calculate amounts for.
 * @param {ethers.providers.Provider} provider - The ethers provider instance.
 * @returns {Promise<{amount0: number, amount1: number}>} - The calculated token amounts.
 */
async function getAmountsForPosition(
  poolAddress,
  tickLower,
  tickUpper,
  liquidityPercent,
  provider
) {
  const poolContract = new ethers.Contract(
    poolAddress,
    artifacts.UniswapV3Pool.abi,
    provider
  );
  const slot0 = await poolContract.slot0();
  const liquidity = await poolContract.liquidity();

  // Convert the liquidity percent to a proportion of the total liquidity
  const liquidityProportion = Number(liquidity) * (liquidityPercent / 100);

  // Calculate square root price values for the given ticks
  let sqrtPriceX96 = slot0.sqrtPriceX96.toString();
  let sqrtPriceLX96 = tickMath.getSqrtRatioAtTick(Number(tickLower));
  let sqrtPriceUX96 = tickMath.getSqrtRatioAtTick(Number(tickUpper));

  // Calculate the amounts for the given liquidity range
  const [amount0BigInt, amount1BigInt] = getAmountsForLiquidityRange(
    sqrtPriceX96,
    sqrtPriceLX96,
    sqrtPriceUX96,
    liquidityProportion.toString()
  );

  // Convert big integers to numbers (be cautious with precision loss for very large values)
  const amount0 = Number(amount0BigInt);
  const amount1 = Number(amount1BigInt);

  return { amount0: amount0, amount1: amount1 };
}

/**
 * Fetches and returns information about a Uniswap v3 pool.
 *
 * @param {string} token0Address - The address of the first token in the pool.
 * @param {string} token1Address - The address of the second token in the pool.
 * @param {string} feeTier - The fee tier of the pool.
 * @param {ethers.providers.Provider} provider - The ethers provider instance.
 * @returns {Promise<Object>} - An object containing details about the pool.
 */
async function getPoolInfo(token0Address, token1Address, feeTier, provider) {
  const uniswapV3Factory = new Contract(
    UV3Factory_address,
    artifacts.UniswapV3Factory.abi,
    provider
  );
  const poolAddress = await uniswapV3Factory.getPool(
    token0Address,
    token1Address,
    feeTier
  );
  const poolContract = new Contract(
    poolAddress,
    artifacts.UniswapV3Pool.abi,
    provider
  );

  const tickSpacing = await poolContract.tickSpacing();
  const fee = await poolContract.fee();
  const slot0 = await poolContract.slot0();
  const currentTick = Number(slot0.tick);
  const currentPrice = Number(Math.pow(1.0001, currentTick));
  const liquidity = await poolContract.liquidity();

  return {
    poolAddress,
    tickSpacing: Number(tickSpacing),
    fee: Number(fee),
    currentTick,
    currentPrice,
    liquidity: Number(liquidity),
  };
}

async function getPositionDetails(nftId) {
  // Ensure the provider is defined globally or passed as an argument
  const provider = ethers.provider;

  const positionManagerContract = new ethers.Contract(POSITION_MANAGER_ADDRESS, artifacts['NonfungiblePositionManager'].abi, provider);

  const position = await positionManagerContract.positions(nftId);

  return {
      tokenId: nftId,
      liquidity: position.liquidity.toString(),
      token0: position.token0,
      token1: position.token1,
      fee: Number(position.fee),
      tickLower: Number(position.tickLower),
      tickUpper: Number(position.tickUpper),
      feeGrowthInside0LastX128: position.feeGrowthInside0LastX128.toString(),
      feeGrowthInside1LastX128: position.feeGrowthInside1LastX128.toString(),
      tokensOwed0: position.tokensOwed0.toString(),
      tokensOwed1: position.tokensOwed1.toString(),
  };
}

function tick_to_shift(tickLower, tickUpper, currentTick, feeTier) {
  // return the tick shift for the next position
  tickLower = Math.floor(tickLower);
  tickUpper = Math.floor(tickUpper);
  const tickSpacing =  Math.floor(TICK_SPACINGS[feeTier]);

  // or priceToClosestTick(targetPrice) if range come from price not tick first
  const newTickLower = tickLower // nearestUsableTick(tickLower, tickSpacing);
  const newTickUpper = tickUpper // nearestUsableTick(tickUpper, tickSpacing);

  // euclidian division to return an int
  const shiftL = Math.floor((currentTick - newTickLower) / tickSpacing);
  const shiftU = Math.floor((currentTick - newTickUpper) / tickSpacing);

  return { shiftLower: shiftL, shiftUpper: shiftU};
}

async function mintNFT(YF_SC, T0, T1, feeTier, amount0Desired, amount1Desired) {
  const signer = await ethers.getSigners();

  const provider = ethers.provider;

  const YfScContract = new Contract(YF_SC, artifacts.YfSc.abi, provider);

  // just for the inital nft minted
  const tx001 = await YfScContract.connect(signer[0]).setInitialTicksForPool(T0, T1, feeTier, "5", "5", { gasLimit: '1000000' })
  await tx001.wait()

  const current_range = await get_ticks();
  console.log("current UR", Number(current_range["upper_tick"]));
  console.log("current LR", Number(current_range["lower_tick"]));

  const tx0 = await YfScContract.connect(signer[0]).mintNFT(T0, T1, feeTier,
    "1000000000000", //amount0Desired.toString(),
    "2000000000000", //amount1Desired.toString(),
    { gasLimit: '2000000'})
  await tx0.wait()

  console.log("mintNFT transaction receipt:");
  console.log("Tx Hash :", tx0.hash);
  // console.log("Block Nb:", tx0.blockNumber);
  // console.log("Gas Used:", tx0.gasUsed.toString());
  console.log("Logs    :", tx0.logs);
}

async function burnNFT(YF_SC, amount) {
  const signer = await ethers.getSigners();

  const provider = ethers.provider;

  const YfScContract = new Contract(YF_SC, artifacts.YfSc.abi, provider);

  const tx = await YfScContract.connect(signer[0]).decreaseLiquidity(T0, T1, feeTier, String(amount), { gasLimit: "1000000" });
  await tx.wait();
  console.log("decrease liquidity validated: ", tx);
}

async function updateNFT(YF_SC, T0, T1, feeTier, shiftLower, shiftUpper) {
  const signer = await ethers.getSigners();

  const provider = ethers.provider;

  const YfScContract = new Contract(YF_SC, artifacts.YfSc.abi, provider);

  const range = await get_ticks();
  console.log("previous UR", Number(range["upper_tick"]));
  console.log("previous LR", Number(range["lower_tick"]));

  const tx2 = await YfScContract.connect(signer[0]).updatePosition(T0, T1, feeTier, 
    "1", // String(shiftLower),
    "1", //  String(shiftUpper),
    { gasLimit: "2000000" });
  const receipt2 = await tx2.wait();

  // TODO create an event to get the nft ID out of the receipt

  console.log("UpdatePosition transaction receipt:");

  console.log("Tx Hash :", receipt2.hash);
  console.log("Block Nb:", receipt2.blockNumber);
  console.log("Gas Used:", receipt2.gasUsed.toString());

  if (receipt2.status === 1) {
    console.log("updatePosition transaction successful");
  } else {
    console.error("updatePosition transaction failed");
  }

  const current_range = await get_ticks();
  console.log("current UR", Number(current_range["upper_tick"]));
  console.log("current LR", Number(current_range["lower_tick"]));
}


async function executePoolUpdate(t0, t1, feeTier) {
  const T0 = addresses[t0];
  const T1 = addresses[t1];

  const signer = await ethers.getSigners();
  const user = signer[0].address;
  console.log("user:", user);

  const provider = ethers.provider;

  const {poolAddress, tickSpacing, fee, currentTick, currentPrice, liquidity} = await getPoolInfo(T0, T1, feeTier, provider);
  console.log("Pool Address    :", poolAddress);
  console.log("Tick Spacing    :", tickSpacing);
  console.log("Fee Tier        :", fee);
  console.log("Current Tick    :", currentTick);
  console.log("Current Price   :", currentPrice);
  console.log("Current Liquidity:", liquidity);

  const last_position = read_position();
  tickLower = String(last_position.tick_lower);
  tickUpper = String(last_position.tick_upper);
  console.log("tick_lower position", tickLower); // currentTick - 2 * Number(tickSpacing)
  console.log("tick_upper position", tickUpper); // currentTick + 2 * Number(tickSpacing)

  // priceToClosestTick(targetPrice) if range come from price not tick first

  const newPriceLower = Number(Math.pow(1.0001, tickLower));
  const newPriceUpper = Number(Math.pow(1.0001, tickUpper));

  console.log(`New Tick Range : ${tickLower} - ${tickUpper}`);
  console.log(`New Price Range: ${newPriceLower} - ${newPriceUpper}`);

  const token0 = await getToken(t0, T0, provider);
  const token1 = await getToken(t1, T1, provider);

  const token0Decimals = await token0.decimals();
  const token1Decimals = await token1.decimals();

  const amounts = await getAmountsForPosition(poolAddress, tickLower, tickUpper, Number(0.001), provider);
  const amount0_b = amounts.amount0;
  const amount1_b = amounts.amount1;

  a0 = Number(amount0_b) * Number(10 ** -Number(token0Decimals));
  a1 = Number(amount1_b) * Number(10 ** -Number(token1Decimals));

  am = Math.round(a0 * 10 ** 7) / 10 ** 7
  bm = Math.round(a1 * 10 ** 7) / 10 ** 7

  console.log(`Token 0 decimals: ${token0Decimals}| Token 1 decimals : ${token1Decimals}`);
  console.log(`raw amount 0 : ${amount0_b}| raw amount 1 : ${amount1_b}`);
  console.log(`amount 0         : ${am}| amount 1       : ${bm}`);

  const shifts = tick_to_shift(tickLower, tickUpper, currentTick)
  shiftLower = 4; // shifts.shiftLower;
  shiftUpper = 4; // shifts.shiftUpper;

  console.log(`shift_lower : ${shiftLower}| shift_upper : ${shiftUpper}`);

  // await first_mintNFT(YF_SC, T0, T1, feeTier, amount0_b, amount1_b)

  await updateNFT(YF_SC, T0, T1, feeTier, shiftLower, shiftUpper)

  const pos = await getPositionDetails(93220)
  console.log(pos)

  // await burnNFT(YF_SC, 4141140630522276969)

}


async function main() {
  console.log("Script started");

  const configPath = path.join(__dirname, "../config.toml");
  const config = toml.parse(fs.readFileSync(configPath, "utf-8"));

  const { t0, t1 }  = config.tokens;
  const { feeTier } = config.settings;

  await executePoolUpdate(t0, t1, feeTier);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


  // send tokens to the contract after deploying
  // create waller addresses fr new users
  // use individual nft for strategies
