const { ethers   } = require("hardhat")
const { Contract } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js");
const yf = require('./yf_toolkit.js');

const addresses = getAddresses(hre.network.name);

t0      = "UNI"
t1      = "WETH"
feeTier = "500"

async function main() {
    const signer2  = await ethers.getSigners();
    const provider = ethers.provider
    const signer_address = await signer2[0].getAddress()
    const network = hre.network.name
    const user_address = await signer2[1].getAddress()

    console.log("Network: ", network);
    console.log("Token0 : ", t0);
    console.log("Token1 : ", t1);
    console.log("FeeTier: ", feeTier);
    console.log("Signer : ", signer_address);
    console.log("User   : ", user_address);
    console.log("")

    const SwapContract = new Contract(addresses['ISWAP_ROUTER'], artifacts.SwapRouter.abi, provider)

    const token1_Contract  = new Contract(addresses[t1], artifacts[t1].abi, provider)
    const token0_Contract  = new Contract(addresses[t0], artifacts[t0].abi, provider)

    // console.log("Approving ...")
    // const a1 = await yf.approveIfNeeded(token1_Contract, signer2[0], addresses['YF_SC'], ethers.parseEther("1000"));
    // const a0 = await yf.approveIfNeeded(token0_Contract, signer2[0], addresses['YF_SC'], ethers.parseEther("1000"));
    // console.log("Approved")
    // console.log("")

    // await token1_Contract.connect(signer2[2]).approve(addresses['YF_SC'], ethers.parseEther("1000"));
    // await token0_Contract.connect(signer2[2]).approve(addresses['YF_SC'], ethers.parseEther("1000"));

    const swapParams2 = {
      tokenOut: addresses[t0],
      tokenIn: addresses[t1],
      fee: feeTier,
      recipient: signer_address,
      amountIn: "10000000000000000",
      amountOutMinimum: "0",
      sqrtPriceLimitX96: "0"
    }

    console.log("")
    console.log("Swapping ...")
    console.log("swapParams2: ", swapParams2);
    const tx21 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams2, { gasLimit: "3000000" });
    await tx21.wait();
    console.log("Swap tx hashes: ", tx21.hash);

    console.log("Another Swap with same parameters ...")
    const tx22 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams2);
    await tx22.wait();
    console.log("Swap tx hashes: ", tx22.hash);
    console.log("")

    const swapParams21 = {
        tokenOut: addresses[t0],
        tokenIn : addresses[t1],
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
    console.log("Swap tx hashes: ", tx211.hash);

    const tx2121 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
    await tx2121.wait();
    console.log("Swap tx hashes: ", tx2121.hash);

    const tx2112 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
    await tx2112.wait()
    console.log("Swap tx hashes: ", tx2112.hash);

    const tx212 = await SwapContract.connect(signer2[0]).exactInputSingle(swapParams21);
    await tx212.wait()
    console.log("Swap tx hashes: ", tx212.hash);

    console.log("")
    console.log("Done swaping")
  
}
// npx hardhat run --network sepolia more_scripts/yfsc_swaps.js

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });