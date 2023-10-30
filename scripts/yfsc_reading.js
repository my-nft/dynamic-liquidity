UNI_ADDRESS = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
POSITION_MANAGER_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
ISWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
YF_SC = "0x3C219663b5A34A09823b918b672f3F137eaBBE81"
POSITION_NFT = "0x08fdbe8a3dA41F237BFB0c81e9AE3b3DD9411d94"

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

  const YfScContract = new Contract(
    YF_SC,
    artifacts.YfSc.abi,
    provider
  )
  const PositionsNFTContract = new Contract(
    POSITION_NFT,
    artifacts.PositionsNFT.abi,
    provider
  )

  const wethContract = new Contract(WETH_ADDRESS,artifacts.WETH.abi,provider)
  const uniContract = new Contract(UNI_ADDRESS,artifacts.UNI.abi,provider)

  await wethContract.connect(signer2[0]).approve(YF_SC, ethers.parseEther("1000"))
  await uniContract.connect(signer2[0]).approve(YF_SC, ethers.parseEther("1000"))

  let deadline = Math.floor(Date.now() / 1000) + (60 * 10); 

  const uniNftId = await YfScContract.connect(signer2[0]).poolNftIds(UNI_ADDRESS, WETH_ADDRESS, "3000")
  console.log("uniNftId: ", uniNftId);
  const positionNftId1 = await PositionsNFTContract.connect(signer2[0]).getUserNftPerPool("0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0", uniNftId)
  const positionNftId2 = await PositionsNFTContract.connect(signer2[0]).getUserNftPerPool("0xD54f6DBde8E90DB546a0Af3bB4d27DFDe0a269ff", uniNftId)
  console.log("positionNftId1: ", positionNftId1);
  console.log("positionNftId2: ", positionNftId2);
  const totalStatesForPosition1 = await PositionsNFTContract.connect(signer2[0]).totalStatesForPosition(positionNftId1)
  const totalStatesForPosition2 = await PositionsNFTContract.connect(signer2[0]).totalStatesForPosition(positionNftId2)
  console.log("totalStatesForPosition1: ", totalStatesForPosition1);
  console.log("totalStatesForPosition2: ", totalStatesForPosition2);
  console.log("");
  console.log("liquidity for position ------> ", positionNftId1)
  for(var  ind = 0; ind <= parseInt(totalStatesForPosition1); ind++){
    console.log("position state id   : ", ind);
    var stateIdForPosition = await PositionsNFTContract.connect(signer2[0]).statesIdsForPosition(positionNftId1, ind);
    console.log("global state id     : ", stateIdForPosition);
    var liquidityAtState = await PositionsNFTContract.connect(signer2[0]).liquidityForUserInPoolAtState(positionNftId1, stateIdForPosition);
    console.log("liquidityAtState    : ", liquidityAtState);
    var poolLiquidityAtState = await YfScContract.connect(signer2[0]).getTotalLiquidityAtStateForPosition(uniNftId, stateIdForPosition);
    console.log("poolLiquidityAtState: ", poolLiquidityAtState);
  }
  console.log("");
  console.log("liquidity for position ------> ", positionNftId2)
  for(var  ind = 0; ind <= parseInt(totalStatesForPosition2); ind++){
    console.log("position state id   : ", ind);
    var stateIdForPosition = await PositionsNFTContract.connect(signer2[0]).statesIdsForPosition(positionNftId2, ind);
    console.log("global state id     : ", stateIdForPosition);
    var liquidityAtState = await PositionsNFTContract.connect(signer2[0]).liquidityForUserInPoolAtState(positionNftId2, stateIdForPosition);
    console.log("liquidityAtState    : ", liquidityAtState);
    var poolLiquidityAtState = await YfScContract.connect(signer2[0]).getTotalLiquidityAtStateForPosition(uniNftId, stateIdForPosition);
    console.log("poolLiquidityAtState: ", poolLiquidityAtState);
  }

  const pendingrewardForPosition1 = await YfScContract.connect(signer2[0]).getPendingrewardForPosition(UNI_ADDRESS, WETH_ADDRESS, "3000");
  console.log("pendingrewardForPosition1: ", pendingrewardForPosition1);

  const pendingrewardForPosition2 = await YfScContract.connect(signer2[1]).getPendingrewardForPosition(UNI_ADDRESS, WETH_ADDRESS, "3000");
  console.log("pendingrewardForPosition2: ", pendingrewardForPosition2);
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