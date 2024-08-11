const { Contract} = require("ethers");
const { ethers } = require("hardhat");
const { Utils } = require("alchemy-sdk");
const { getAddresses, artifacts } = require("./addresses.js");
const uniV3 = require('./UNI_v3.js');
const {getAmountsForLiquidityRange, tickMath} = require('@thanpolas/univ3prices');

const { priceToClosestTick, TICK_SPACINGS, nearestUsableTick, Position, NonfungiblePositionManager, MintOptions, Pool } = require("@uniswap/v3-sdk")
const { BigIntish, Percent } = require('@uniswap/sdk-core')

const addresses = getAddresses(hre.network.name);

POSITION_MANAGER_ADDRESS =  addresses['POSITION_MANAGER_ADDRESS']
ISWAP_ROUTER             =  addresses['ISWAP_ROUTER']
UV3Factory_address       =  addresses['UniswapV3Factory']
YF_SC                    =  addresses['YF_SC']

t0 = "UNI"
t1 = "WETH"
T0 = addresses[t0]
T1 = addresses[t1]

feeTier    = "3000"

const provider = ethers.provider  


async function getTokenDecimals(token_name,tokenAddress) {
    const tokenContract = new ethers.Contract(tokenAddress, artifacts[token_name].abi, provider);
    return await tokenContract.decimals();
}

async function getPositionDetails(nftId) {
    const positionManagerContract = new Contract(POSITION_MANAGER_ADDRESS, artifacts.NonfungiblePositionManager.abi, provider);

    const position = await positionManagerContract.positions(nftId);

    return {
        tokenId: nftId,
        liquidity: position.liquidity.toString(),
        token0: position.token0,
        token1: position.token1,
        fee: Number(position.fee),
        tickLower: Number(position.tickLower),
        tickUpper: Number(position.tickUpper)
    };
}

async function getOwnedNFTs(address) {
    const positionManagerContract = new Contract(POSITION_MANAGER_ADDRESS, artifacts.NonfungiblePositionManager.abi, provider);

    const filter = positionManagerContract.filters.Transfer(null, address);

    const events = await positionManagerContract.queryFilter(filter);

    return events.map(event => event.args.tokenId.toString());
}

async function updateNFT(nftId) {
    const positionDetails = await getPositionDetails(nftId);
    console.log('Current NFT Position Details:', positionDetails);

    const uniswapV3Factory = new Contract(UV3Factory_address, artifacts.UniswapV3Factory.abi, provider);

    const poolAddr = await uniswapV3Factory.getPool(T0, T1, feeTier);
    console.log("pool Addr:", poolAddr);

    const poolContract = new Contract(poolAddr, artifacts.UniswapV3Pool.abi, provider);

    const tickSpacing = await poolContract.tickSpacing();
    console.log('Tick Spacing:', Number(tickSpacing));

    const slot0 = await poolContract.slot0();
    const currentTick = slot0.tick;
    const sqrtPriceX96 = slot0.sqrtPriceX96;
    console.log('Current Tick:', Number(currentTick));
    console.log('Current Price:', Math.pow(Number(sqrtPriceX96),2));

    const newTickLower = Number(currentTick) - 5 * Number(tickSpacing);
    const newTickUpper = Number(currentTick) + 5 * Number(tickSpacing);
    console.log(`New Tick Range: [${newTickLower}, ${newTickUpper}]`);

    // Calculate the square root values for the price range
    const sqrtPriceLower = Math.sqrt(Math.pow(1.0001, newTickLower));
    const sqrtPriceUpper = Math.sqrt(Math.pow(1.0001, newTickUpper));
    console.log(`New Price Range: [${Math.pow(sqrtPriceLower,2)}, ${Math.pow(sqrtPriceUpper,2)}]`);

    const token0Decimals = await getTokenDecimals(t0, T0);
    const token1Decimals = await getTokenDecimals(t1, T1);
    console.log(`Token 0 decimals :${token0Decimals}| Token 1 decimals :${token1Decimals}`);

    const [amount0, amount1] = uniV3.get_amounts(Math.pow(Number(currentTick),2),
                                                 Math.pow(Number(sqrtPriceLower),2),
                                                 Math.pow(Number(sqrtPriceUpper),2),
                                                 token0Decimals,
                                                 token1Decimals);
    console.log(`amount 0 :${amount0}| amount 1 :${amount1}`);

    // await burnNFT(nftId);

    // await mintNFT(newTickLower, newTickUpper, amount0, amount1);
}

function read_position() {
    console.log(__dirname);
    // read position from the position.json file here.
    // return the range "tick_lower": 198603, "tick_upper": 199404 associated with the latest position  
    // the json is a dico of key id int and position as value they are rank by id
    const positionData = require("./positions.json");
    const latestPosition = positionData[Object.keys(positionData).length - 1];
    const tickLower = latestPosition.tick_lower;
    const tickUpper = latestPosition.tick_upper;
    return { tick_lower: Number(tickLower), tick_upper: Number(tickUpper) };
}

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
async function getAmountsForPosition(poolAddress, tickLower, tickUpper, liquidityPercent, provider) {
    const poolContract = new ethers.Contract(poolAddress, artifacts.UniswapV3Pool.abi, provider);
    const slot0 = await poolContract.slot0();
    const liquidity = await poolContract.liquidity();

    // Convert the liquidity percent to a proportion of the total liquidity
    const liquidityProportion = Number(liquidity) * (liquidityPercent / 100);

    // Calculate square root price values for the given ticks
    let sqrtPriceX96 = slot0.sqrtPriceX96.toString();
    let sqrtPriceLX96 = tickMath.getSqrtRatioAtTick(tickLower);
    let sqrtPriceUX96 = tickMath.getSqrtRatioAtTick(tickUpper);

    // Calculate the amounts for the given liquidity range
    const [amount0BigInt, amount1BigInt] = getAmountsForLiquidityRange(
        sqrtPriceX96, sqrtPriceLX96, sqrtPriceUX96, liquidityProportion.toString()
    );

    // Convert big integers to numbers (be cautious with precision loss for very large values)
    const amount0 = Number(amount0BigInt);
    const amount1 = Number(amount1BigInt);

    return { 'amount0' : amount0, 'amount1' : amount1 };
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
    const uniswapV3Factory = new Contract(UV3Factory_address, artifacts.UniswapV3Factory.abi, provider);
    const poolAddress = await uniswapV3Factory.getPool(token0Address, token1Address, feeTier);
    const poolContract = new Contract(poolAddress, artifacts.UniswapV3Pool.abi, provider);

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
        liquidity: Number(liquidity)
    };
}

async function main() {
    const signer2 = await ethers.getSigners();
    const myAddress = await signer2[0].getAddress();
    console.log("My Address:", myAddress);

    // Retrieve owned NFTs
    const ownedNFTs = await getOwnedNFTs(myAddress);
    console.log("Owned NFT IDs:", ownedNFTs);

    // Update each NFT (for demonstration, we'll just update the first one)
    if (ownedNFTs.length > 0) {
        const nftIdToUpdate = ownedNFTs[0];
        console.log(`Updating NFT ID: ${nftIdToUpdate}`);
        await updateNFT(nftIdToUpdate);
    }

    const signer = await ethers.getSigners();
    const user = signer[0].address;
    console.log("user:", user);

    const provider = ethers.provider

    const { poolAddress, tickSpacing, fee, currentTick, currentPrice, liquidity } = await getPoolInfo(T0, T1, feeTier, provider);
    console.log("Pool Address    :", poolAddress);
    console.log("Tick Spacing    :", tickSpacing);
    console.log("Fee Tier        :", fee);
    console.log("Current Tick    :", currentTick);
    console.log("Current Price   :", currentPrice);
    console.log("Current Liquidity:", liquidity);

    range = await get_ticks();
    console.log("previous UR", Number(range['upper_tick']));
    console.log("previous LR", Number(range['lower_tick']));

    last_position = read_position();
    console.log("tick_lower position", last_position.tick_lower); // currentTick - 2 * Number(tickSpacing)
    console.log("tick_upper position", last_position.tick_upper); // currentTick + 2 * Number(tickSpacing)

    // or priceToClosestTick(targetPrice) if range come from price not tick first
    const newTickLower = nearestUsableTick(last_position.tick_lower, TICK_SPACINGS[feeTier]);
    const newTickUpper = nearestUsableTick(last_position.tick_upper, TICK_SPACINGS[feeTier]);

    // Calculate the square root values for the price range
    const newPriceLower = Number(Math.pow(1.0001, -newTickLower));
    const newPriceUpper = Number(Math.pow(1.0001, -newTickUpper));

    console.log(`New Tick Range : ${newTickLower} - ${newTickUpper}`);
    console.log(`New Price Range: ${newPriceLower} - ${newPriceUpper}`);

    const token0 = await getToken(t0, T0, provider);
    const token1 = await getToken(t1, T1, provider);

    const token0Decimals = await token0.decimals();
    const token1Decimals = await token1.decimals();

    const amounts = await getAmountsForPosition(poolAddr, newTickLower, newTickUpper, Number(0.01), provider)
    const amount0_b = amounts.amount0
    const amount1_b = amounts.amount1

    a0 = Number(amount0_b) * Number(10**-Number(token0Decimals))
    a1 = Number(amount1_b) * Number(10**-Number(token1Decimals))

    console.log(`Token 0 decimals: ${token0Decimals}| Token 1 decimals : ${token1Decimals}`);
    console.log(`amount 0 : ${Math.round(a0 * 10**7) / 10**7}| amount 1 : ${Math.round(a1 * 10**7) / 10**7}`);


    /*
    const positionManagerContract = new Contract(POSITION_MANAGER_ADDRESS, artifacts['NonfungiblePositionManager'].abi, provider);

    const configuredPool = Pool(token0, token1, 3000, slot0.sqrtPriceX96.toString(), liquidity.toString(), Number(slot0.tick))
    console.log('Pool')

    const position = Position.fromAmounts({
        pool: configuredPool,
        tickLower: newTickLower,
        tickUpper: newTickUpper,
        amount0: amount0,
        amount1: amount1,
        useFullPrecision: false,
    })

    const mintOptions = {recipient: user, deadline: Math.floor(Date.now() / 1000) + 60 * 20, slippageTolerance: new Percent(50, 10_000)}

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
    */

    // const tx2 = await poolContract.connect(signer[0]).mint(String(user), BigInt(newTickUpper), BigInt(newTickLower), BigInt(amount0_b))
    // await tx2.wait();

    // const nftID = "79442";
    // const position = await positionManagerContract.positions(nftID);

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

    const tx2 = await positionManagerContract.connect(signer[0]).mint(T0, T1, feeTier,
        String(newTickLower),
        String(newTickUpper),
        String(amount0_b),
        String(amount1_b),
        String(0), String(0), user, deadline);
    await tx2.wait();

    console.log("tokenId  :", tx2.tokenId);
    console.log("liquidity:", tx2.liquidity);
    console.log("amount0  :", tx2.amount0);
    console.log("amount1  :", tx2.amount1);

    console.log("NFT minted");
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});
