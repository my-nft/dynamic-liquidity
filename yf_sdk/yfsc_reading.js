const { ethers   } = require("hardhat")
const { Contract } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js")
const yf = require('./yf_toolkit.js').default;

const addresses = getAddresses(hre.network.name);

t0      = "UNI"
t1      = "WETH"
feeTier = "3000"

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

  const YfScContract = new Contract(addresses['YF_SC'], artifacts['YfSc'].abi, provider);
  const StatesVariableContract = new Contract(addresses['YF_SVC'], artifacts['StatesVariables'].abi, provider);

  const token1_Contract  = new Contract(addresses[t1], artifacts[t1].abi, provider)
  const token0_Contract  = new Contract(addresses[t0], artifacts[t0].abi, provider)

  const balanceToken0 = await token0_Contract.connect(signer2[0]).balanceOf(YfScContract.target);
  const balanceToken1 = await token1_Contract.connect(signer2[0]).balanceOf(YfScContract.target);

  console.log("YFSC balance token0: ", ethers.formatEther(balanceToken0));
  console.log("YFSC balance token1: ", ethers.formatEther(balanceToken1));
  console.log("")

  const address_user1 = await signer2[1].getAddress();
  const address_user2 = await signer2[2].getAddress();

  var pendingReward0 = await YfScContract.connect(signer2[1]).getPendingrewardForPosition(addresses[t0], addresses[t1], feeTier);
  var pendingReward1 = await YfScContract.connect(signer2[2]).getPendingrewardForPosition(addresses[t0], addresses[t1], feeTier);

  console.log(`User 1 ${address_user1} pendingReward: `, pendingReward0);
  console.log(`User 2 ${address_user2} pendingReward: `, pendingReward1);

  let originalPoolNftIds = await YfScContract.connect(signer2[0]).originalPoolNftIds(addresses[t0], addresses[t1], feeTier);
  console.log("originalPool NFT Ids of user: ", originalPoolNftIds.toString());
  console.log("")

  let poolNftIds = await YfScContract.connect(signer2[0]).poolNftIds(addresses[t0], addresses[t1], feeTier);
  console.log("pool NFT Ids of user: ", poolNftIds.toString());
  console.log("")

  var rewardToken0_1 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 1);
  var rewardToken0_2 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 2);
  var rewardToken0_3 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 3);
  var rewardToken0_4 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken0(originalPoolNftIds, 4);

  console.log("rewardToken0_1: ", ethers.formatEther(rewardToken0_1));
  console.log("rewardToken0_2: ", ethers.formatEther(rewardToken0_2));
  console.log("rewardToken0_3: ", ethers.formatEther(rewardToken0_3));
  console.log("rewardToken0_4: ", ethers.formatEther(rewardToken0_4));

  var rewardToken1_1 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 1);
  var rewardToken1_2 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 2);
  var rewardToken1_3 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 3);
  var rewardToken1_4 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 4);
  var rewardToken1_5 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 5);
  var rewardToken1_6 = await StatesVariableContract.connect(signer2[1]).getRewardAtStateForNftToken1(originalPoolNftIds, 6);

  console.log("rewardToken1_1: ", ethers.formatEther(rewardToken1_1));
  console.log("rewardToken1_2: ", ethers.formatEther(rewardToken1_2));
  console.log("rewardToken1_3: ", ethers.formatEther(rewardToken1_3));
  console.log("rewardToken1_4: ", ethers.formatEther(rewardToken1_4));
  console.log("rewardToken1_5: ", ethers.formatEther(rewardToken1_5));
  console.log("rewardToken1_6: ", ethers.formatEther(rewardToken1_6));

  console.log("balance token0: ", await token0_Contract.connect(signer2[0]).balanceOf(YfScContract.target));
  console.log("balance token1: ", await token1_Contract.connect(signer2[0]).balanceOf(YfScContract.target));
}

// npx hardhat run --network sepolia yf_sdk/yfsc_reading.js


main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });