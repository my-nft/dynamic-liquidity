const { Contract} = require("ethers");
const { ethers } = require("hardhat");
const { Utils } = require("alchemy-sdk");
const { getAddresses, artifacts } = require("/Users/armandmorin/Downloads/dynamic-liquidity-main/scripts/addresses.js");
const uniV3 = require('./UNI_v3.js');

const addresses = getAddresses(hre.network.name);

POSITION_MANAGER_ADDRESS = addresses['POSITION_MANAGER_ADDRESS']
UV3Factory_address       = addresses['UniswapV3Factory']

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

async function burnNFT(nftId) {
    const signer = await ethers.getSigners();
    const positionManagerContract = new Contract(POSITION_MANAGER_ADDRESS, artifacts.NonfungiblePositionManager.abi, signer[0]);

    const DEFAULT_GAS_LIMIT = BigInt(Utils.parseUnits("1000000", "gwei")); // adjust as needed

    // Estimate gas for the burn transaction
    try {
        const estimatedBurnGas = await positionManagerContract.connect(signer[0]).estimateGas.burn(nftId);
        const burnGasLimit = estimatedBurnGas.add(estimatedBurnGas.mul(20).div(100)); // Adding 20% buffer
        console.log('burnGasLimit :', burnGasLimit);
    } catch (error) {
        console.error("Error estimating gas for burnNFT function:", error);
        console.log('Using default gas limit:', DEFAULT_GAS_LIMIT.toString());
        const burnGasLimit = DEFAULT_GAS_LIMIT;
    }
    const burnGasLimit = DEFAULT_GAS_LIMIT;
    
    // Execute the burn transaction
    const burnTx = await positionManagerContract.connect(signer[0]).burn(nftId, { gasLimit: burnGasLimit });
    await burnTx.wait();
    console.log('NFT burned:', nftId);

    // Collect the tokens after burning
    const collectParams = {
        tokenId: nftId,
        recipient: signer[0].getAddress(),
        amount0Max: ethers.constants.MaxUint256,
        amount1Max: ethers.constants.MaxUint256
    };
    
    // Estimate gas for the collect transaction
    const estimatedCollectGas = await positionManagerContract.connect(signer[0]).estimateGas.collect(collectParams);
    const collectGasLimit = estimatedCollectGas.add(estimatedCollectGas.mul(20).div(100)); // Adding 20% buffer

    // Execute the collect transaction
    const collectTx = await positionManagerContract.connect(signer[0]).collect(collectParams, { gasLimit: collectGasLimit });
    const collectReceipt = await collectTx.wait();
    console.log('Tokens collected:', collectReceipt);
}

async function mintNFT(tickLower, tickUpper, amount0Desired, amount1Desired) {
    const signer = await ethers.getSigners();

    const positionManagerContract = new ethers.Contract(POSITION_MANAGER_ADDRESS, artifacts.NonfungiblePositionManager.abi, signer[0]);

    const mintParams = {
        token0: T0,
        token1: T1,
        fee: feeTier,
        tickLower: tickLower,
        tickUpper: tickUpper,
        amount0Desired: amount0Desired,
        amount1Desired: amount1Desired,
        amount0Min: 0,
        amount1Min: 0,
        recipient: signer[0].getAddress(),
        deadline: Math.floor(Date.now() / 1000) + 60 * 10 // 10 minutes from the current time
    };

    // Estimate gas limit
    const estimatedGasLimit = await positionManagerContract.connect(signer[0]).estimateGas.mint(mintParams);
    const gasLimit = estimatedGasLimit.add(estimatedGasLimit.mul(20).div(100)); // Adding 20% buffer

    // Execute the transaction with the estimated gas limit
    const mintTx = await positionManagerContract.connect(signer[0]).mint(mintParams, { gasLimit: gasLimit });
    const mintReceipt = await mintTx.wait();
    console.log('NFT minted:', mintReceipt);
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

    await burnNFT(nftId);

    await mintNFT(newTickLower, newTickUpper, amount0, amount1);
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
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});
