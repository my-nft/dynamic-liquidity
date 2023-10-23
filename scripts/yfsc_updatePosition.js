UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
ISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
YF_SC = "0x7BfCfCCBf86726a5246329E98BD1eB8208AD0e23"
POSITION_NFT = "0x97648fe53eC27d827DF4006b88340EbBE6d523ba"

MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

const artifacts = {
  NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
  WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
  UNI: require("../artifacts/contracts/yfsc.sol/Token.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/yfsc.sol/PositionsNFT.json"),
};

const { Contract, ContractFactory, utils, BigNumber  } = require("ethers")

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer1:", signer2[0]);
  const provider = ethers.provider
  const YfScContract = new Contract(
    YF_SC,
    artifacts.YfSc.abi,
    provider
  )

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const tx1 = await YfScContract.connect(signer2[0]).setTicks(
    // "-21960",
    "-27060",
    "-20820",
    { gasLimit: '1000000' }
  )
  await tx1.wait()

  const tx2 = await YfScContract.connect(signer2[0]).updatePosition( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",  
    { gasLimit: '1000000' } 
  ) 
  await tx2.wait() 
  console.log("update position: ", tx2); 

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