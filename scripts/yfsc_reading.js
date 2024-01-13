const { ethers   } = require("hardhat")
const { Contract } = require("ethers")
const { getAddresses, artifacts } = require("/Users/armandmorin/Downloads/dynamic-liquidity-main/scripts/addresses.js");

const addresses = getAddresses(hre.network.name);

t0 = "UNI"
t1 = "WETH"
feeTier    = "3000"

YF_SC           =  addresses['YF_SC']
YF_POSITION_NFT = addresses['YF_POSITION_NFT']
POSITION_MANAGER_ADDRESS = addresses['POSITION_MANAGER_ADDRESS']
UniswapV3Factory = addresses['UniswapV3Factory']

T0 = addresses[t0]
T1 = addresses[t1]


async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer1:", signer2[0].getAddress());

  const provider = ethers.provider

  const YfScContract         = new Contract(YF_SC, artifacts.YfSc.abi, provider)
  const PositionsNFTContract = new Contract(YF_POSITION_NFT, artifacts.PositionsNFT.abi, provider)
  
  const uniswapV3Factory = new Contract(UniswapV3Factory, artifacts.UniswapV3Factory.abi, provider);
  const poolAddr = await uniswapV3Factory.getPool(T0,T1,feeTier);
  console.log("pool Addr:", poolAddr);

  
  const uniNftId = await YfScContract.connect(signer2[0]).poolNftIds(T0, T1, feeTier)
  console.log("uniNftId: ", uniNftId);

  // const positionNftId1 = await PositionsNFTContract.connect(signer2[0]).getUserNftPerPool("0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0", uniNftId)
  const positionNftId1 = await PositionsNFTContract.connect(signer2[0]).getUserNftPerPool(poolAddr, uniNftId)
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

  const pendingrewardForPosition1 = await YfScContract.connect(signer2[0]).getPendingrewardForPosition(T0, T1, feeTier);
  console.log("pendingrewardForPosition1: ", pendingrewardForPosition1);

  console.log("done!")
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });