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
    const user_address = await signer2[1].getAddress()

    console.log("Network: ", network);
    console.log("Token0 : ", t0);
    console.log("Token1 : ", t1);
    console.log("FeeTier: ", feeTier);
    console.log("Signer : ", signer_address);
    console.log("User   : ", user_address);
    console.log("")

    const token1_Contract  = new Contract(addresses[t1], artifacts[t1].abi, provider)
    const token0_Contract  = new Contract(addresses[t0], artifacts[t0].abi, provider)

    const YfScContract = new Contract(addresses['YF_SC'], artifacts['YfSc'].abi, provider);

    let rebalance = false;
    let external  = true;

    console.log("")
    const YfScContract_balanceToken0_before = await token0_Contract.connect(signer2[0]).balanceOf(YfScContract.target);
    const YfScContract_balanceToken1_before = await token1_Contract.connect(signer2[0]).balanceOf(YfScContract.target);

    const user_balanceToken0_before = await token0_Contract.connect(signer2[0]).balanceOf(user_address);
    const user_balanceToken1_before = await token1_Contract.connect(signer2[0]).balanceOf(user_address);

    console.log("YfScContract balance token0 before mint: ", ethers.formatEther(YfScContract_balanceToken0_before));
    console.log("YfScContract balance token1 before mint: ", ethers.formatEther(YfScContract_balanceToken1_before));
    console.log("User balance token0 before mint        : ", ethers.formatEther(user_balanceToken0_before));
    console.log("User balance token1 before mint        : ", ethers.formatEther(user_balanceToken1_before));
    console.log("")
    console.log("")

    console.log("Collecting rewards for user : ", user_address)
    const tx = await YfScContract.connect(signer2[1]).collect(addresses[t0], addresses[t1], feeTier,
      0, 0, rebalance, external, {gasLimit: '2000000'})
    await tx.wait()
    console.log("Collecting rewards with tx: ", tx.hash);

    console.log("")
    const YfScContract_balanceToken0_after = await token0_Contract.connect(signer2[0]).balanceOf(YfScContract.target);
    const YfScContract_balanceToken1_after = await token1_Contract.connect(signer2[0]).balanceOf(YfScContract.target);

    const user_balanceToken0_after = await token0_Contract.connect(signer2[0]).balanceOf(user_address);
    const user_balanceToken1_after = await token1_Contract.connect(signer2[0]).balanceOf(user_address);

    console.log("YfScContract balance token0 after mint: ", ethers.formatEther(YfScContract_balanceToken0_after));
    console.log("YfScContract balance token1 after mint: ", ethers.formatEther(YfScContract_balanceToken1_after));
    console.log("User balance token0 after mint        : ", ethers.formatEther(user_balanceToken0_after));
    console.log("User balance token1 after mint        : ", ethers.formatEther(user_balanceToken1_after));
    console.log("")
    console.log("")
}
// npx hardhat run --network sepolia yf_sdk/yfsc_collect.js

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });