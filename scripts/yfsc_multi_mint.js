UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
ISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
YF_SC = "0x6dd763d08Ab488677A1b12F0b6e69d6b58f456a2"
POSITION_NFT = "0xE5B9315b998890D233B09Bf6caBf8346Dd872470"

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

const artifacts = {
  NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
  WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
  UNI: require("../artifacts/contracts/yfsc.sol/Token.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/yfsc.sol/PositionsNFT.json"),
};

// const { ethers } = require("hardhat")

const { Contract, ContractFactory, utils, BigNumber  } = require("ethers")
// const { Contract} = require("ethers")

async function main() {
  const signer = await ethers.getSigners();
  console.log("signer1:", signer[0]);
  const provider = ethers.provider

  const YfScContract = new Contract(
    YF_SC,
    artifacts.YfSc.abi,
    provider
  )

  console.log("initialized");

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer[0]).approve(YF_SC, ethers.parseEther("1000"))
  await uniContract.connect(signer[0]).approve(YF_SC, ethers.parseEther("1000"))

  console.log("approved");

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const tx2 = await YfScContract.connect(signer[0]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "22579957097400000",
    "1000000000000000", 
    { gasLimit: '2000000' }
  )

  await tx2.wait()

  await wethContract.connect(signer[1]).approve(YF_SC, ethers.parseEther("1000"))
  await uniContract.connect(signer[1]).approve(YF_SC, ethers.parseEther("1000"))

  const tx3 = await YfScContract.connect(signer[1]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "45159914194900000",
    "2000000000000000", 
    { gasLimit: '2000000' }
  )
  await tx3.wait()

  console.log("done!")
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