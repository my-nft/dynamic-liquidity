UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
ISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564"

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
  const signer2 = await ethers.getSigners();
  console.log("signer1:", signer2[0]);

  const provider = ethers.provider

  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, signer2[0]);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, POSITION_MANAGER_ADDRESS, ISWAP_ROUTER);

  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(
    MINTER_ROLE, YfScContract.target,
    { gasLimit: '1000000' }
  )
  await tx.wait()

  console.log("YfScContract address: ", YfScContract.target);
  console.log("PositionsNFTContract address: ", PositionsNFTContract.target);

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))
  await uniContract.connect(signer2[0]).approve(YfScContract.target, ethers.parseEther("1000"))

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const tx1 = await YfScContract.connect(signer2[0]).mintNFT(
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000", 
    "92265983778560538",
    "10000000000000000", 
    { gasLimit: '2000000' }
  )
  await tx1.wait()

  const public_tickLowerb = await YfScContract.public_tickLower();
  console.log("public_tickLower before: ", public_tickLowerb);

  const public_tickUpperb = await YfScContract.public_tickUpper();
  console.log("public_tickUpper before: ", public_tickUpperb);

  const tickLowerb = await YfScContract.tickLower();
  console.log("tickLower before: ", tickLowerb);

  const tickUpperb = await YfScContract.tickUpper();
  console.log("tickUpper before: ", tickUpperb);

  const tx2 = await YfScContract.connect(signer2[0]).setTicks(
    // "-21960",
    "-26040",
    "-24840",
    { gasLimit: '1000000' }
  )
  await tx2.wait()

  // const tx3 = await YfScContract.connect(signer2[0]).decreaseLiquidity(
  //   UNI_ADDRESS, 
  //   WETH_ADDRESS, 
  //   "3000",  
  //   "100",
  //   "false",
  //   { gasLimit: '1000000' } 
  // );
  // await tx3.wait()

  const tx3 = await YfScContract.connect(signer2[0]).updatePosition( 
    UNI_ADDRESS, 
    WETH_ADDRESS, 
    "3000",  
    { gasLimit: '1000000' } 
  ) 
  await tx3.wait() 
  console.log("update position: ", tx3); 

  const public_amount0 = await YfScContract.public_amount0();
  console.log("public_amount0: ", public_amount0);

  const public_amount1 = await YfScContract.public_amount1();
  console.log("public_amount1: ", public_amount1);

  const public_tickLower = await YfScContract.public_tickLower();
  console.log("public_tickLower: ", public_tickLower);

  const public_tickUpper = await YfScContract.public_tickUpper();
  console.log("public_tickUpper: ", public_tickUpper);

  const tickLower = await YfScContract.tickLower();
  console.log("tickLower: ", tickLower);

  const tickUpper = await YfScContract.tickUpper();
  console.log("tickUpper: ", tickUpper);

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