const { ethers   } = require("hardhat")
const { Contract } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js");
const yf = require('./yf_toolkit.js').default;

const addresses = getAddresses(hre.network.name);

t0      = "UNI"
t1      = "WETH"
feeTier = "500"

async function main() {
    const signer2  = await ethers.getSigners();
    const provider = ethers.provider
    const signer_address = await signer2[0].getAddress()
    const network = hre.network.name

    console.log("Network: ", network);
    console.log("Token0 : ", t0);
    console.log("Token1 : ", t1);
    console.log("FeeTier: ", feeTier);
    console.log("Signer : ", signer_address);
    console.log("")

    const token1_Contract  = new Contract(addresses[t1], artifacts[t1].abi, provider)
    const token0_Contract  = new Contract(addresses[t0], artifacts[t0].abi, provider)

    const YfScContract = new Contract(addresses['YF_SC'], artifacts['YfSc'].abi, provider);

    let rebalance = false;
    let external  = true;

    const balanceToken1_before = await token1_Contract.connect(signer2[2]).balanceOf(signer_address);
    const balanceToken0_before = await token0_Contract.connect(signer2[2]).balanceOf(signer_address);

    console.log("Token1 balance before collecting: ", ethers.utils.formatEther(balanceToken1_before));
    console.log("Token0 balance before collecting: ", ethers.utils.formatEther(balanceToken0_before));

    const tx4 = await YfScContract.connect(signer2[2]).collect(addresses[t0], addresses[t1], feeTier,
        0, 0, external, {gasLimit: '2000000'})
    await tx4.wait()

    const balanceToken1_after = await token1_Contract.connect(signer2[2]).balanceOf(signer_address);
    const balanceToken0_after = await token0_Contract.connect(signer2[2]).balanceOf(signer_address);

    console.log("Token1 balance after collecting: ", ethers.utils.formatEther(balanceToken1_after));
    console.log("Token0 balance after collecting: ", ethers.utils.formatEther(balanceToken0_after));
}
// npx hardhat run --network sepolia yf_sdk/yfsc_collect.js

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });