const { ethers } = require("hardhat")
const { Contract } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js");

const addresses = getAddresses(hre.network.name);

t0 = "UNI"
t1 = "WETH"
feeTier = "3000"

POSITION_MANAGER_ADDRESS = addresses['POSITION_MANAGER_ADDRESS']
UniswapV3Factory = addresses['UniswapV3Factory']

T0 = addresses[t0]
T1 = addresses[t1]

async function main() {
    const signer2 = await ethers.getSigners();
    console.log("signer1:", signer2[0].getAddress());

    const provider = ethers.provider

    const uniswapV3Factory = new ethers.Contract(UniswapV3Factory, artifacts.UniswapV3Factory.abi, provider);
    const poolAddr = await uniswapV3Factory.getPool(T0, T1, feeTier);
    console.log("pool Addr:", poolAddr);

    const poolContract = new ethers.Contract(poolAddr, artifacts.UniswapV3Pool.abi, provider);

    const tickSpacing = await poolContract.tickSpacing();
    console.log('Tick Spacing:', Number(tickSpacing));

    const allTicks = [];
    const invalidTicks = [];

    // Query tick info for all ticks
    for (let i = -887220; i <= 887220; i++) {
        const targetTick = BigInt(i) * BigInt(tickSpacing);

        try {
            // Query tick info for each potential tick
            const tickInfo = await poolContract.ticks(targetTick.toString());

            // Check if tick info is not all 0 and the last value is false
            if (!tickInfo.slice(0, -1).every(value => value === 0n) && tickInfo[tickInfo.length - 1] === false) {
                console.log(`Tick ${targetTick} Info:`, tickInfo);
                allTicks.push(targetTick);
            } else {
                invalidTicks.push(targetTick);
            }
        } catch (error) {
            // If an error occurs, the tick is not valid
            //invalidTicks.push(targetTick);
        }
    }

    //console.log('Invalid Ticks:', invalidTicks);
    console.log('Valid Ticks:', allTicks);

    // // Get slot0 information
    // const slot0 = await poolContract.slot0();
    // const currentTick = "-27060" //slot0.tick;
    // const tickSpacing = await poolContract.tickSpacing();
    // console.log('Current Tick:', Number(currentTick));
    // console.log('Tick Spacing:', Number(tickSpacing));

    // const potentialTicks = [];

    // // Verify each potential tick
    // for (let i = -100; i <= 100; i++) {
    //     const targetTick = currentTick + BigInt(i) * BigInt(tickSpacing);

    //     try {
    //         // Query tick info for each potential tick
    //         const tickInfo = await poolContract.ticks(targetTick.toString());

    //         // Check if tick info is not all 0 and the last value is false
    //         if (!tickInfo.slice(0, -1).every(value => value === 0n) && tickInfo[tickInfo.length - 1] === false) {
    //             console.log(`Tick ${targetTick.initialized} Info:`, tickInfo);
    //             potentialTicks.push(targetTick);
    //         } else {
    //             console.error(`Tick ${targetTick.initialized} is not valid:`, tickInfo);
    //         }
    //     } catch (error) {
    //         // If an error occurs, the tick is not valid
    //         console.error(`Tick ${targetTick} is not valid:`, error.message);
    //     }
    // }

    // console.log('Valid Ticks:', potentialTicks);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});